function OT_main(varargin)
	%% OT_main Main OT mapper function called every second to check for updates
	
	try
	%get globals
	global sFig;
	global sOT;
	
	cellText = {};
	
	%check initialization
	if ~sOT.IsInitialized,return;end
	%check if busy
	if sFig.boolIsBusy,return;end
	sFig.boolIsBusy = true;

	%get stream variables
	boolNewData = false;
	intUseStreamIMEC = get(sFig.ptrListSelectProbe,'Value');
	intStimSyncChanNI = sOT.intStimSyncChanNI;
	intLastFetchNI = sOT.intLastFetchNI;
	intLastFetchIM = sOT.intLastFetchIM;
	dblSampFreqNI = sOT.dblSampFreqNI;
	dblSampFreqIM = sOT.dblSampFreqIM;
	dblEphysTimeNI = sOT.dblEphysTimeNI;
	dblEphysTimeIM = sOT.dblEphysTimeIM;
	dblEphysStepSecs = 5;
	intEphysTrialN = sOT.intEphysTrialN; %not used, only updated
	dblEphysTrialT = sOT.dblEphysTrialT; %not used, only updated
	intStimTrialN = sOT.intStimTrialN;
	dblStimTrialT = sOT.dblStimTrialT;
	
	%get other variables
	sStimObject = sOT.sStimObject;
	if isempty(sStimObject),clear sStimObject;end
	vecOldTimestampsNI = sOT.vecTimestampsNI;
	vecSyncData = sOT.vecSyncData;
	vecTimestampsIM = sOT.vecTimestampsIM;
	matData = sOT.matData;

	%get stimulus variables
	vecStimOnT = sOT.vecStimOnT; %on times of all stimuli (NI time prior to stim on)
	vecStimOffT = sOT.vecStimOffT; %off times of all stimuli (NI time after stim off)
	vecDiodeOnT = sOT.vecDiodeOnT; %on times of all stimuli (diode on time)
	vecDiodeOffT = sOT.vecDiodeOnT; %off times of all stimuli (diode off time)
	vecImecOnT = sOT.vecDiodeOnT; %on times of all stimuli (IMEC on time)
	vecImecOffT = sOT.vecDiodeOnT; %off times of all stimuli (IMEC off time)
	
	
	
	%get data from figure
	strStimPath = get(sFig.ptrTextStimPath, 'string');

	%get data type from figure
	intLoadLFP = get(sFig.ptrButtonDataLFP,'Value');
	if intLoadLFP == 1
		strLoadDataType = 'LFP';
	else
		strLoadDataType = 'AP';
	end

	%default downsample
	intSubSampleFactor = str2double(get(sFig.ptrTextDownsampleFactor,'String'));

	%default high-pass frequency
	dblFiltFreq = str2double(get(sFig.ptrEditHighpassFreq,'String'));

	%use GPU?
	boolUseGPU = sOT.UseGPU;

	% SGL data
	%set stream IDs
	vecStreamIM = [0];
	intStreamIM = vecStreamIM(intUseStreamIMEC);
	strStreamIM = sprintf( 'GETSCANCOUNT %d', intStreamIM);
	intStreamNI = -1;
	strStreamNI = sprintf( 'GETSCANCOUNT %d', intStreamNI);

	%prep meta data
	intSubSampleFactorIM = sOT.intSubSampleFactorIM;
	dblSubSampleFactorNI = sOT.dblSubSampleFactorNI;
	dblSubSampleTo = sOT.dblSubSampleTo;
	intDownsampleNI = 1;

	% get NI I/O box data, single iter takes ~0.5ms
	%get current scan number for NI streams
	intCurCountNI = GetScanCount(sOT.hSGL, intStreamNI);
	
	%check if this is the initial fetch
	if intLastFetchNI == 0
		intRetrieveSamplesNI = round(5*dblSampFreqNI); %retrieve last 5 seconds
		intRetrieveSamplesNI = min(intCurCountNI-1,intRetrieveSamplesNI); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountNI - intRetrieveSamplesNI; %set last fetch to starting position
		dblLastTimestampNI = 0;
	else
		intStartFetch = intLastFetchNI - 2*round(dblSampFreqNI);
		intStartFetch = max(intStartFetch,1); %ensure we're not requesting data prior to start
		intRetrieveSamplesNI = intCurCountNI - intStartFetch; %retrieve as many samples as acquired between previous fetch and now, plus 500ms
		dblLastTimestampNI = vecOldTimestampsNI(end);
	end
	
	
	%get NI data
	if intRetrieveSamplesNI > 0
		%fetch in try-catch block
		try
			%fetch "intRetrieveSamplesNI" samples starting at "intFetchStartCountNI"
			[vecStimSyncDataNI,intStartCountNI] = Fetch(sOT.hSGL, intStreamNI, intStartFetch, intRetrieveSamplesNI, intStimSyncChanNI,intDownsampleNI);
		catch ME
			%buffer has likely already been cleared; unable to fetch data
			cellText = {'<< ERROR >>',ME.identifier,ME.message};
			OT_updateTextInformation(cellText);
			return;
		end
	end
	%sketch
dblCurTimeNI = GetScanCount(sOT.hSGL, intStreamNI)/dblSampFreqNI
	dblCurTimeIM = GetScanCount(sOT.hSGL, intStreamIM)/dblSampFreqIM
	
	
	%update NI time
	sOT.intLastFetchNI = intCurCountNI;
	dblCurTimeNI = intCurCountNI/dblSampFreqNI;
	
	sOT.dblEphysTimeNI = dblCurTimeNI;
	set(sFig.ptrTextTimeNI,'string',sprintf('%.3f',dblCurTimeNI));
	
	%process NI data
	vecTimeNI = ((intStartFetch+1):intDownsampleNI:intCurCountNI)/dblSampFreqNI;
	intStartT = find(vecTimeNI>(dblLastTimestampNI+dblSubSampleTo),1);
	if isempty(intStartT),intStartT=1;end
	vecKeepNI = round(intStartT:dblSubSampleFactorNI:intRetrieveSamplesNI);
	vecNewTimestampsNI = vecTimeNI(vecKeepNI);
	vecNewSyncData = sOT.NI2V*single(flat(vecStimSyncDataNI(vecKeepNI))'); %transform to voltage
	%assign data
	vecTimestampsNI = cat(2,vecOldTimestampsNI,vecNewTimestampsNI);
	vecSyncData = cat(2,sOT.vecSyncData,vecNewSyncData);
	sOT.vecTimestampsNI = vecTimestampsNI;
	sOT.vecSyncData = vecSyncData;
	
	%find onset and offset of most recent stimulus
	dblLowerTresholdV = -2;
	vecStimPresent = sOT.vecSyncData < dblLowerTresholdV; %stimulus frames
	
	figure(2)
	%subplot(2,1,1)
	plot(vecSyncData)
	%subplot(2,1,2)
	%plot(vecStimSyncDataNI)
	%vecNewSyncData
	retrieve approximate time from stim object file
	sOT.vecStimOnT %on times of all stimuli
	sOT.vecStimOffT %off times of all stimuli
	vecUseStimFrames = vecTimestampsNI(vecStimPresent)
	
	vecNewSyncData
	%% 
	
	
	%check for new data
	if (numel(vecNewTimestampsNI) > 0)
		%message
		cellText{1} = sprintf('Processing new SGL data [%.1fs - %.1fs] ...',vecNewTimestampsNI(1),vecNewTimestampsNI(end));
		OT_updateTextInformation(cellText);
	end
	while (vecNewTimestampsNI(end) - 1) > dblEphysTime
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
		if strcmpi(strLoadDataType,'AP')

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
				dblLFPLengthSecs = 3*dblSubSampleTo; %10*dblSubSampleTo;
				intFilterSize = round(dblSampFreq*dblLFPLengthSecs);
				[vecLFPHigh,vecLFPLow] = getLFPelope(gVecSignal,intFilterSize);
				%downsample
				vecSubLFP = accumarray(vecAssignTo(:),gather(abs(vecLFPHigh)+abs(vecLFPLow)))'/intSubSampleFactor;
				%assign data
				matSubNewData(intCh,:) = vecSubLFP(1:(end-1));
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
		sOT.dblEphysTimeNI = dblEphysTimeNI;
		sOT.dblEphysTimeIM = dblEphysTimeIM;
		sOT.intEphysTrialN = intEphysTrialN;
		sOT.intEphysTrialT = dblEphysTrialT;

		sOT.vecTimestamps = vecTimestamps;
		sOT.matData = matData;
		
		%update fig
		set(sFig.ptrTextTimeNI, 'string',sprintf('%.2f',dblEphysTimeNI));
		set(sFig.ptrTextStimNI, 'string',sprintf('%.2f (%d)',dblEphysTrialT,intEphysTrialN));
		set(sFig.ptrTextTimeIM, 'string',sprintf('%.2f',dblEphysTimeIM));
	end
	if boolNewData
		%msg
		cellText{end} = strcat(cellText{end},'  Completed!');
		cellText{end+1} = '';
		OT_updateTextInformation(cellText);
	end
%}
	%% stim logs
	%get stimulus object files
	sFiles = dir(strcat(strStimPath,filesep,'Object*.mat'));
	cellNames = {sFiles(:).name};
	vecObjectID = cellfun(@str2double,cellfun(@getFlankedBy,cellNames,cellfill('Object',size(cellNames)),cellfill('.mat',size(cellNames)),'uniformoutput',false));
	vecLoadObjects = sort(vecObjectID(vecObjectID>intStimTrialN),'descend');
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
		vecStimOnT = cell2mat({sStimObject(:).dblStimOnNI});
		vecStimOffT = cell2mat({sStimObject(:).dblStimOffNI});
		vecOriDegs = cell2mat({sStimObject(:).Orientation});
		[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
		dblStimTrialT = max(cat(2,vecStimOnT,vecStimOffT));
		intStimTrialN = vecLoadObjects(1);
		dblStimCoverage = (intStimTrialN/numel(vecUnique))*100;
		%save vars
		sOT.sStimObject = sStimObject;
		sOT.dblStimCoverage = dblStimCoverage;
		sOT.intStimTrialN = intStimTrialN;
		sOT.dblStimTrialT = dblStimTrialT;
		sOT.vecStimOnT = cat(2,sOT.vecStimOnT,vecStimOnT);
		sOT.vecStimOffT = cat(2,sOT.vecStimOnT,vecStimOnT);
		
		%update fig
		set(sFig.ptrTextStimTrialT, 'string',sprintf('%.2f',dblStimTrialT));
		set(sFig.ptrTextStimTrialN, 'string',sprintf('%d',intStimTrialN));
		set(sFig.ptrTextStimCoverage, 'string',sprintf('%.2f',dblStimCoverage));
		set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
		drawnow;

		%msg
		cellText{end+1} = sprintf('Loaded %d stimulus objects',numel(vecLoadObjects));
		cellText{end+1} = '';
		OT_updateTextInformation(cellText);
	end
	intTrials = min([intEphysTrialN intStimTrialN]);
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
			vecBaseLFP = mean(matData(:,vecBaseBins),2)./numel(vecBaseBins);
			vecStimLFP = mean(matData(:,vecStimBins),2)./numel(vecStimBins);

			%assign data
			matRespBase(:,intTrial) = vecBaseLFP;
			matRespStim(:,intTrial) = vecStimLFP;
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

