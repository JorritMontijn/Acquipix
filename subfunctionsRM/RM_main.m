function RM_main(varargin)
	%% RM_main Main RF mapper function called every second to check for updates
	
	%get globals
	global sFig;
	global sRM;
	cellText = {};
	
	try
		%suppress warnings
		sWarnStruct = warning();
		warning('off');
		
		%check initialization
		if ~sRM.IsInitialized,return;end
		%check if busy
		if sFig.boolIsBusy,return;end
		sFig.boolIsBusy = true;
		
		%get stream variables
		boolNewData = false;
		dblEphysTime = sRM.dblEphysTime;
		dblEphysStepSecs = 15;
		intEphysTrial = sRM.intEphysTrial; %not used, only updated
		dblStimCoverage = sRM.dblStimCoverage; %not used, only updated
		intStimTrial = sRM.intStimTrial;
		sStimObject = sRM.sStimObject;
		if isempty(sStimObject),clear sStimObject;end
		vecTimestamps = sRM.vecTimestamps;
		matData = sRM.matData;
		
		%get data from figure
		strTank = get(sFig.ptrTextRecording, 'string');
		strBlock = get(sFig.ptrTextBlock, 'string');
		strStimPath = get(sFig.ptrTextStimPath, 'string');
		
		%get data type from figure
		intLoadEnv = get(sFig.ptrButtonDataENV,'Value');
		if intLoadEnv == 1
			strLoadDataType = 'dENV';
		else
			strLoadDataType = 'dRAW';
		end
		
		%default downsample
		intSubSampleFactor = str2double(get(sFig.ptrTextDownsampleFactor,'String'));
		
		%default high-pass frequency
		dblFiltFreq =  str2double(get(sFig.ptrEditHighpassFreq,'String'));
		
		%use GPU?
		boolUseGPU = sRM.UseGPU;
		
		%% TDT data
		%prep meta data
		sMetaData = struct;
		sMetaData.Myevent = strLoadDataType;
		sMetaData.Mytank = strTank;
		sMetaData.Myblock = strBlock;
		%read
		sMetaData = getMetaDataTDT(sMetaData,false);
		%assign
		vecTimeRange = sMetaData.vecTimeRange;
		dblSampFreq = sMetaData.strms(strcmpi(sMetaData.Myevent, {sMetaData.strms(:).name} )).sampf;
		dblSubSampleTo = intSubSampleFactor/dblSampFreq;
		
		%get trigger times
		vecStimOnTime = sMetaData.Trials.stim_onset;
		matWord = sMetaData.Trials.word;
		[vecStimOnTime,matWord] = checkTriggersTDT(vecStimOnTime,matWord);
		vecTrialStartTime = matWord(:,1);
		vecStimType = matWord(:,2);
		if isfield(sMetaData.Trials,'stim_offset')
			vecStimOffTime = checkTriggersTDT(sMetaData.Trials.stim_offset,matWord);
		elseif isfield(sMetaData.Trials,'target_onset')
			vecStimOffTime = checkTriggersTDT(sMetaData.Trials.target_onset,matWord);
		else
			vecStimOffTime = vecStimOnTime + 0.5; %use 500 ms as default duration
		end
		if ~isnan(vecStimType(end)) && vecStimType(end) ~= numel(vecStimType)
			%msg
			cellText{end+1} = 'Warning: ePhys trial count mismatch!';
			cellText{end+1} = sprintf('# of triggers: %d; trial number: %d',numel(vecStimType),vecStimType(end));
			cellText{end+1} = '';
			
			%remove trials
			intMaxTrialNum = min([numel(vecTrialStartTime) numel(vecStimType) numel(vecStimOnTime) numel(vecStimOffTime)]);
			vecTrialStartTime(intMaxTrialNum:end) = [];
			vecStimType(intMaxTrialNum:end) = [];
			vecStimOnTime(intMaxTrialNum:end) = [];
			vecStimOffTime(intMaxTrialNum:end) = [];
		end
		intEphysTrial = numel(vecStimOffTime);
		
		%check for new data
		if (vecTimeRange(end) - 1) > dblEphysTime
			%message
			cellText{1} = sprintf('Processing new ePhys data [%.1fs - %.1fs] ...',vecTimeRange(1),vecTimeRange(end));
			RM_updateTextInformation(cellText);
		end
		%%
		while (vecTimeRange(end) - 1) > dblEphysTime
			%get neural data
			vecNextTimeRange = [dblEphysTime dblEphysTime+dblEphysStepSecs];
			[vecNewTimestamps,matNewData,vecChannels,vecRealTimeRange] = getRawDataTDT(sMetaData,vecNextTimeRange);
			intNumCh = numel(vecChannels);
			sRM.NumChannels = intNumCh;
			
			%concatenate data
			if isempty(vecTimestamps)
				indUseNewData = true(size(vecNewTimestamps));
			elseif isempty(vecNewTimestamps)
				indUseNewData = [];
			else
				indUseNewData = vecNewTimestamps > max(vecTimestamps);
			end
			
			%get timestamps
			boolNewData = true;
			vecNewTimestamps = vecNewTimestamps(indUseNewData);
			
			%re-reference odd by average of all odd channels, and even by even
			matNewData = matNewData(:,indUseNewData);
			matNewData(1:2:end,:) = bsxfun(@minus,matNewData(1:2:end,:),cast(mean(matNewData(1:2:end,:),1),'like',matNewData)); %odd
			matNewData(2:2:end,:) = bsxfun(@minus,matNewData(2:2:end,:),cast(mean(matNewData(2:2:end,:),1),'like',matNewData)); %even
			if strcmpi(strLoadDataType,'dRAW')
				%get subsample vector
				vecSubNewTimestamps = vecNewTimestamps(1:intSubSampleFactor:end);
				intNewPoints = numel(vecNewTimestamps);
				intSubNewPoints = ceil(intNewPoints/intSubSampleFactor);
				vecAssignTo = sort(repmat(1:intSubNewPoints,[1 intSubSampleFactor]));
				vecSubNewTimestamps(end) = [];
				dblEphysTime = vecSubNewTimestamps(end);
				vecAssignTo = vecAssignTo(1:intNewPoints);
				
				%pre-allocate downsampled data matrix
				matSubNewData = zeros(intNumCh,intSubNewPoints-1,'single');
				
				%design filter
				if ~isempty(dblFiltFreq) && dblFiltFreq > 0
					d = designfilt('highpassfir',...
						'SampleRate',dblSampFreq, ...
						'StopbandFrequency',dblFiltFreq-dblFiltFreq/10, ...     % Frequency constraints
						'PassbandFrequency',dblFiltFreq+dblFiltFreq/10, ...
						'StopbandAttenuation',dblFiltFreq/10, ...    % Magnitude constraints
						'PassbandRipple',4);
					if boolUseGPU
						gVecFilter = gpuArray(d.Coefficients);
					else
						gVecFilter = d.Coefficients;
					end
				end
				
				% apply high-pass filter & calculate envelope
				for intCh=1:size(matNewData,1)
					%get signal
					if boolUseGPU
						gVecSignal = gpuArray(double(matNewData(intCh,:)));
					else
						gVecSignal = double(matNewData(intCh,:));
					end
					
					%filter
					if ~isempty(dblFiltFreq) && dblFiltFreq > 0
						gVecSignal = fftfilt(gVecFilter,gVecSignal);
						
						%gVecSignal = highpass(gVecSignal,dblFiltFreq,dblSampFreq);
					end
					%envelope
					dblEnvLengthSecs = 3*dblSubSampleTo; %10*dblSubSampleTo;
					intFilterSize = round(dblSampFreq*dblEnvLengthSecs);
					[vecEnvHigh,vecEnvLow] = getEnvelope(gVecSignal,intFilterSize);
					%downsample
					vecSubEnv = accumarray(vecAssignTo(:),gather(abs(vecEnvHigh)+abs(vecEnvLow)))'/intSubSampleFactor;
					%assign data
					matSubNewData(intCh,:) = vecSubEnv(1:(end-1));
				end
				
				%add to matrix
				matData = cat(2,matData,matSubNewData);
				vecTimestamps = cat(2,vecTimestamps,vecSubNewTimestamps);
			else
				%add to matrix
				dblEphysTime = vecNewTimestamps(end);
				matData = cat(2,matData,matNewData);
				vecTimestamps = cat(2,vecTimestamps,vecNewTimestamps);
			end
			
			
			%update variables
			sRM.vecTimestamps = vecTimestamps;
			sRM.matData = matData;
			sRM.dblEphysTime = dblEphysTime;
			sRM.intEphysTrial = intEphysTrial;
			
			%update fig
			set(sFig.ptrTextEphysTime, 'string',sprintf('%.2f',dblEphysTime));
			set(sFig.ptrTextEphysTrial, 'string',sprintf('%d',intEphysTrial));
		end
		if boolNewData
			%msg
			cellText{end} = strcat(cellText{end},'  Completed!');
			cellText{end+1} = '';
			RM_updateTextInformation(cellText);
		end
		
		%% stim logs
		%get stimulus object files
		sFiles = dir(strcat(strStimPath,filesep,'Object*.mat'));
		cellNames = {sFiles(:).name};
		vecObjectID = cellfun(@str2double,cellfun(@getFlankedBy,cellNames,cellfill('Object',size(cellNames)),cellfill('.mat',size(cellNames)),'uniformoutput',false));
		vecLoadObjects = sort(vecObjectID(vecObjectID>intStimTrial),'descend');
		if isempty(vecLoadObjects)
			%continue; %if there is no new data, wait for new data
		else
			%if there is new data, load it
			boolNewData = true;
			for intLoadObject=vecLoadObjects
				sLoad = load([strStimPath filesep sprintf('Object%d.mat',intLoadObject)]);
				sStimObject(intLoadObject) = sLoad.sObject;
			end
			
			%update variables
			intStimTrial = vecLoadObjects(1);
			dblStimCoverage = 100*sum(sStimObject(end).UsedLinLocOff(:))/numel(sStimObject(end).UsedLinLocOff);
			sRM.sStimObject = sStimObject;
			sRM.dblStimCoverage = dblStimCoverage;
			sRM.intStimTrial = intStimTrial;
			
			%update fig
			set(sFig.ptrTextStimTrial, 'string',sprintf('%d',intStimTrial));
			set(sFig.ptrTextStimCoverage, 'string',sprintf('%.2f',dblStimCoverage));
			set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
			drawnow;
			
			%msg
			cellText{end+1} = sprintf('Loaded %d stimulus objects',numel(vecLoadObjects));
			cellText{end+1} = '';
			RM_updateTextInformation(cellText);
		end
		warning(sWarnStruct);
		intTrials = min([intEphysTrial intStimTrial]);
		if intTrials > 0 && boolNewData && sRM.NumChannels > 0
			%% calc RF estimate
			%ON, OFF, ON-base OFF-base
			intMaxRep = max([sStimObject(end).UsedLinLocOn(:);sStimObject(end).UsedLinLocOff(:)]);
			cellStimON = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellBaseON = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellStimOFF = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellBaseOFF = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			
			%go through objects and assign to matrices
			matLinLoc = sStimObject(end).LinLoc;
			for intTrial=1:intTrials
				%get repetitions of locations
				vecLinLocOn = sStimObject(intTrial).LinLocOn;
				vecLinLocOff = sStimObject(intTrial).LinLocOff;
				
				%get data
				dblStartTrial= vecTrialStartTime(intTrial);
				dblStartStim = vecStimOnTime(intTrial);
				dblStopStim = vecStimOffTime(intTrial);
				vecBaseBins = find(vecTimestamps>dblStartTrial):find(vecTimestamps>dblStartStim);
				vecStimBins = find(vecTimestamps>dblStartStim):find(vecTimestamps>dblStopStim);
				%if ePhys data is not available yet, break
				if isempty(vecBaseBins) || isempty(vecStimBins)
					break;
				end
				vecBaseENV = mean(matData(:,vecBaseBins),2)./numel(vecBaseBins);
				vecStimENV = mean(matData(:,vecStimBins),2)./numel(vecStimBins);
				
				%assign data
				for intLocOn=vecLinLocOn(:)'
					cellBaseON{matLinLoc==intLocOn}(:,end+1) = vecBaseENV;
					cellStimON{matLinLoc==intLocOn}(:,end+1) = vecStimENV;
				end
				for intLocOff=vecLinLocOff(:)'
					cellBaseOFF{matLinLoc==intLocOff}(:,end+1) = vecBaseENV;
					cellStimOFF{matLinLoc==intLocOff}(:,end+1) = vecStimENV;
				end
			end
			
			%% save data to globals
			sRM.cellStimON = cellStimON; %[y by x] cell with [chan x rep] matrix
			sRM.cellBaseON = cellBaseON; %[y by x] cell with [chan x rep] matrix
			sRM.cellStimOFF = cellStimOFF; %[y by x] cell with [chan x rep] matrix
			sRM.cellBaseOFF = cellBaseOFF; %[y by x] cell with [chan x rep] matrix
			
			%% update maps
			RM_redraw(0);
		else
			%% show waiting bar
			cellOldText = get(sFig.ptrTextInformation, 'string');
			strBaseString = 'No new data';
			if ~isempty(cellOldText) && numel(cellOldText{1}) > numel(strBaseString) && strcmpi(cellOldText{1}(1:numel(strBaseString)),strBaseString)
				cellBar = {'-','\','|','/'};
				cellText{1} = cellOldText{1};
				intPrev = find(strcmpi(cellText{1}(end),cellBar));
				if isempty(intPrev)
					intNext = 1;
				else
					intNext = mod(intPrev,numel(cellBar)) + 1;
				end
				cellText{1}(end) = cellBar{intNext};
			else
				cellText{end+1} = strcat(strBaseString,' -');
			end
			RM_updateTextInformation(cellText);
			pause(0.5);
		end
		
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		RM_unlock(sFig);
	catch ME
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		RM_unlock(sFig);
		
		%send error
		dispErr(ME);
	end
end

