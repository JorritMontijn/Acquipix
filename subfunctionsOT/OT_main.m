function OT_main(varargin)
	%% OT_main Main RF mapper function called every second to check for updates
	%get globals
	global sFig;
	global sOT;
	cellText = {};
	
	try
		
		%check initialization
		if ~sOT.IsInitialized,return;end
		%check if busy
		if sFig.boolIsBusy,return;end
		sFig.boolIsBusy = true;
		
		%get stream variables
		boolNewData = false;
		dblEphysTime = sOT.dblEphysTime;
		dblEphysStepSecs = 15;
		intEphysTrial = sOT.intEphysTrial; %not used, only updated
		intStimTrial = sOT.intStimTrial;
		sStimObject = sOT.sStimObject;
		if isempty(sStimObject),clear sStimObject;end
		vecTimestamps = sOT.vecTimestamps;
		matData = sOT.matData;
		
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
		boolUseGPU = sOT.UseGPU;
		
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
		sWarnStruct = warning();
		warning('off');
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
		
		warning(sWarnStruct);
		intEphysTrial = numel(vecStimOffTime);
		
		%check for new data
		if (vecTimeRange(end) - 1) > dblEphysTime
			%message
			cellText{1} = sprintf('Processing new ePhys data [%.1fs - %.1fs] ...',vecTimeRange(1),vecTimeRange(end));
			OT_updateTextInformation(cellText);
		end
		while (vecTimeRange(end) - 1) > dblEphysTime
			%get neural data
			vecNextTimeRange = [dblEphysTime dblEphysTime+dblEphysStepSecs];
			[vecNewTimestamps,matNewData,vecChannels,vecRealTimeRange] = getRawDataTDT(sMetaData,vecNextTimeRange);
			intNumCh = numel(vecChannels);
			sOT.NumChannels = intNumCh;
			
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
			sOT.vecTimestamps = vecTimestamps;
			sOT.matData = matData;
			sOT.dblEphysTime = dblEphysTime;
			sOT.intEphysTrial = intEphysTrial;
			
			%update fig
			set(sFig.ptrTextEphysTime, 'string',sprintf('%.2f',dblEphysTime));
			set(sFig.ptrTextEphysTrial, 'string',sprintf('%d',intEphysTrial));
		end
		if boolNewData
			%msg
			cellText{end} = strcat(cellText{end},'  Completed!');
			cellText{end+1} = '';
			OT_updateTextInformation(cellText);
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
			vecOriDegs = cell2mat({sStimObject(:).Orientation});
			[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
			
			intStimTrial = vecLoadObjects(1);
			dblStimCoverage = (intStimTrial/numel(vecUnique))*100;
			sOT.sStimObject = sStimObject;
			sOT.dblStimCoverage = dblStimCoverage;
			sOT.intStimTrial = intStimTrial;
			
			%update fig
			set(sFig.ptrTextStimTrial, 'string',sprintf('%d',intStimTrial));
			set(sFig.ptrTextStimCoverage, 'string',sprintf('%.2f',dblStimCoverage));
			set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
			drawnow;
			
			%msg
			cellText{end+1} = sprintf('Loaded %d stimulus objects',numel(vecLoadObjects));
			cellText{end+1} = '';
			OT_updateTextInformation(cellText);
		end
		intTrials = min([intEphysTrial intStimTrial]);
		if intTrials > 0 && boolNewData && sOT.NumChannels > 0
			%% calc RF estimate
			%update variables
			vecOriDegs = cell2mat({sStimObject(:).Orientation});
			[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
			
			%base, stim
			matRespBase = nan(sOT.NumChannels,intTrials);
			matRespStim = nan(sOT.NumChannels,intTrials);
			vecStimTypes = nan(1,intTrials);
			vecStimOriDeg = nan(1,intTrials);
			%go through objects and assign to matrices
			for intTrial=1:intTrials
				%get orientation
				intStimType = vecTrialIdx(intTrial);
				
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
				matRespBase(:,intTrial) = vecBaseENV;
				matRespStim(:,intTrial) = vecStimENV;
				vecStimTypes(intTrial) = intStimType;
				vecStimOriDeg(intTrial) = vecOriDegs(intTrial);
			end
			
			%% save data to globals
			sOT.matRespBase = matRespBase; %[1 by S] cell with [chan x rep] matrix
			sOT.matRespStim = matRespStim; %[1 by S] cell with [chan x rep] matrix
			sOT.vecStimTypes = vecStimTypes; %[1 by S] cell with [chan x rep] matrix
			sOT.vecStimOriDeg = vecStimOriDeg; %[1 by S] cell with [chan x rep] matrix
			
			%% update maps
			OT_redraw(0);
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
			OT_updateTextInformation(cellText);
			pause(0.5);
		end
		
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		OT_unlock(sFig);
	catch ME
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		OT_unlock(sFig);
		
		%send error
		dispErr(ME);
	end
%end

