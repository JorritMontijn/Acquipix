function OT_main(varargin)
	%% OT_main Main OT mapper function called every second to check for updates
	%get globals
	global sFig;
	global sOT;
	
	try
	%% retrieve variables
	cellText = {};
	
	%check initialization
	if ~sOT.IsInitialized,return;end
	%check if busy
	if sFig.boolIsBusy,return;end
	sFig.boolIsBusy = true;

	%get stream variables
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
	
	%get data variables
	sStimObject = sOT.sStimObject;
	if isempty(sStimObject),clear sStimObject;end
	vecOldTimestampsNI = sOT.vecTimestampsNI;
	vecOldSyncData = sOT.vecSyncData;
	intDataBufferPos = sOT.intDataBufferPos;
	intDataBufferSize = sOT.intDataBufferSize;
	dblDataBufferSize = sOT.dblDataBufferSize;
	vecTimestampsIM = sOT.vecTimestampsIM;
	matDataBufferIM = sOT.matDataBufferIM;
	vecOldSubTimestamps = sOT.vecSubTimestamps;
	matOldSubData = sOT.matSubData;
	vecAllChans = sOT.vecAllChans;
	vecUseChans = sOT.vecUseChans;
	
	%get stimulus variables
	vecOldStimOnT = sOT.vecStimOnT; %on times of all stimuli (NI time prior to stim on)
	vecOldStimOffT = sOT.vecStimOffT; %off times of all stimuli (NI time after stim off)
	vecDiodeOnT = sOT.vecDiodeOnT; %on times of all stimuli (diode on time)
	vecDiodeOffT = sOT.vecDiodeOffT; %off times of all stimuli (diode off time)
	
	%get resp variables
	intRespTrialN = sOT.intRespTrialN;
	matRespBase = sOT.matRespBase;
	matRespStim = sOT.matRespStim;
	vecStimTypes = sOT.vecStimTypes;
	vecStimOriDeg = sOT.vecStimOriDeg;
	
	%get whether to calculate envelope
	boolCalcEnv = sOT.boolCalcEnv;
	
	%get data from figure
	strStimPath = get(sFig.ptrTextStimPath, 'string');

	%get data type from figure
	intLoadLFP = get(sFig.ptrButtonDataLFP,'Value');
	if intLoadLFP == 1
		strLoadDataType = 'LFP';
	else
		strLoadDataType = 'AP';
	end

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
	intDownsampleIM = 1;
	
	%% get NI I/O box data
	%get current scan number for NI streams
	intCurCountNI = GetScanCount(sOT.hSGL, intStreamNI);
	
	%check if this is the initial fetch
	if intLastFetchNI == 0
		intRetrieveSamplesNI = round(5*dblSampFreqNI); %retrieve last 5 seconds
		intRetrieveSamplesNI = min(intCurCountNI-1,intRetrieveSamplesNI); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountNI - intRetrieveSamplesNI; %set last fetch to starting position
		dblLastTimestampNI = 0;
	else
		intStartFetch = intLastFetchNI - round(dblSampFreqNI);
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
	%update NI time
	dblEphysTimeNI = intCurCountNI/dblSampFreqNI;
	set(sFig.ptrTextTimeNI,'string',sprintf('%.3f',dblEphysTimeNI));
	%save to globals
	sOT.intLastFetchNI = intCurCountNI;
	sOT.dblEphysTimeNI = dblEphysTimeNI;
		
	%process NI data
	vecTimeNI = ((intStartFetch+1):intDownsampleNI:intCurCountNI)/dblSampFreqNI;
	intStartT = find(vecTimeNI>(dblLastTimestampNI+dblSubSampleTo),1);
	if isempty(intStartT),intStartT=1;end
	vecKeepNI = round(intStartT:dblSubSampleFactorNI:intRetrieveSamplesNI);
	vecNewTimestampsNI = vecTimeNI(vecKeepNI);
	vecNewSyncData = sOT.NI2V*single(flat(vecStimSyncDataNI(vecKeepNI))'); %transform to voltage
	%assign data
	vecTimestampsNI = cat(2,vecOldTimestampsNI,vecNewTimestampsNI);
	vecSyncData = cat(2,vecOldSyncData,vecNewSyncData);
	
	
	%find onset and offset of most recent stimulus
	dblMaxErrorT = 0.1; %discard onsets/offsets if temporal mismatch is more than x seconds
	dblLowerTresholdV = -0.75;
	vecStimPresent = vecSyncData < dblLowerTresholdV; %stimulus frames
	vecOnsets = vecTimestampsNI(find(diff(vecStimPresent) == 1)+1);
	
	%onsets
	for intOnset=1:numel(vecOnsets)
		%find closest onset
		[dblMinT,intMinIdx]= min(abs(vecOldStimOnT - vecOnsets(intOnset)));
		if isempty(dblMinT)
			break;
		elseif dblMinT < dblMaxErrorT
			vecDiodeOnT(intMinIdx) = vecOnsets(intOnset);
			if intMinIdx > sOT.intEphysTrialN
				cellText(end+1) = {sprintf('PD onset for stim %d: %.3fs (mismatch: %.3fs)',intMinIdx,vecOnsets(intOnset),dblMinT)};
			end
		elseif intMinIdx > 1 && intMinIdx < sOT.intEphysTrialN
			cellText(end+1:end+2) = {'<< WARNING >>',sprintf('PD onset at %.3fs has mismatch %.3fs!',vecOnsets(intOnset),dblMinT)};
		end
	end
	%offsets
	vecOffsets = vecTimestampsNI(find(diff(vecStimPresent) == -1)+1);
	for intOffset=1:numel(vecOffsets)
		%find closest offset
		[dblMinT,intMinIdx]= min(abs(vecOldStimOffT - vecOffsets(intOffset)));
		if isempty(dblMinT)
			break;
		elseif dblMinT < dblMaxErrorT
			vecDiodeOffT(intMinIdx) = vecOffsets(intOffset);
			if intMinIdx > sOT.intEphysTrialN
				cellText(end+1) = {sprintf('PD offset for stim %d: %.3fs (mismatch: %.3fs)',intMinIdx,vecOffsets(intOffset),dblMinT)};
			end
		elseif intMinIdx > 1 && intMinIdx < sOT.intEphysTrialN
			cellText(end+1:end+2) = {'<< WARNING >>',sprintf('PD offset at %.3fs has mismatch %.3fs!',vecOffsets(intOffset),dblMinT)};
		end
	end
	OT_updateTextInformation(cellText);
	
	%save data to globals
	sOT.vecTimestampsNI = vecTimestampsNI;
	sOT.vecSyncData = vecSyncData;
	sOT.vecDiodeOnT = vecDiodeOnT; %on times of all stimuli (diode on time)
	sOT.vecDiodeOffT = vecDiodeOffT; %off times of all stimuli (diode off time)
	sOT.intEphysTrialN = min([numel(vecDiodeOnT) numel(vecDiodeOffT)]);
	if sOT.intEphysTrialN == 0
		sOT.dblEphysTrialT = 0;
	else
		sOT.dblEphysTrialT = max([vecDiodeOnT(sOT.intEphysTrialN),vecDiodeOffT(sOT.intEphysTrialN)]);
	end
	
	%update figure
	set(sFig.ptrTextStimNI, 'string',sprintf('%.2f (%d)',sOT.dblEphysTrialT,sOT.intEphysTrialN));
	
	%% get IMEC data
	%get current scan number for NI streams
	intCurCountIM = GetScanCount(sOT.hSGL, intStreamIM);
	
	%check if this is the initial fetch
	if intLastFetchIM == 0
		intRetrieveSamplesIM = round(5*dblSampFreqIM); %retrieve last 5 seconds
		intRetrieveSamplesIM = min(intCurCountIM-1,intRetrieveSamplesIM); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountIM - intRetrieveSamplesIM; %set last fetch to starting position
	else
		intStartFetch = intLastFetchIM - round(dblSampFreqIM);
		intStartFetch = max(intStartFetch,1); %ensure we're not requesting data prior to start
		intRetrieveSamplesIM = intCurCountIM - intStartFetch; %retrieve as many samples as acquired between previous fetch and now, plus 500ms
	end
	
	%get IM data
	if intRetrieveSamplesIM > 0
		%fetch in try-catch block
		try
			%fetch "intRetrieveSamplesIM" samples starting at "intFetchStartCountIM"
			[matNewData,intStartCountIM] = Fetch(sOT.hSGL, intStreamIM, intStartFetch, intRetrieveSamplesIM, vecAllChans,intDownsampleIM);
		catch ME
			%buffer has likely already been cleared; unable to fetch data
			cellText = {'<< ERROR >>',ME.identifier,ME.message};
			OT_updateTextInformation(cellText);
			return;
		end
	end
	%update IM time
	dblEphysTimeIM = intCurCountIM/dblSampFreqIM;
	set(sFig.ptrTextTimeIM,'string',sprintf('%.3f',dblEphysTimeIM));
	%save to globals
	sOT.intLastFetchIM = intCurCountIM;
	sOT.dblEphysTimeIM = dblEphysTimeIM;
		
	%put data in buffer
	vecNewTimestampsIM = intStartFetch:(intStartFetch+intRetrieveSamplesIM-1);
	vecAssignBufferPos = modx(intDataBufferPos:(intDataBufferPos+numel(vecNewTimestampsIM)-1),intDataBufferSize);
	%assign to global
	sOT.intDataBufferPos = modx(vecAssignBufferPos(end)+1,intDataBufferSize);
	sOT.vecTimestampsIM(vecAssignBufferPos) = vecNewTimestampsIM;
	sOT.matDataBufferIM(vecAssignBufferPos,:) = matNewData;
	sOT.dblSubLastUpdate = sOT.dblSubLastUpdate + range(vecNewTimestampsIM)/dblSampFreqIM;
	
	%% update data
	if sOT.dblSubLastUpdate > 1 %if last subsample update is more than 1 second ago
		%unroll buffer
		[vecLinBuffT,vecReorderData] = sort(sOT.vecTimestampsIM,'ascend');
		vecLinBuffT = vecLinBuffT/dblSampFreqIM;
		matLinBuffData = sOT.matDataBufferIM(vecReorderData,:);
		vecUseBuffData = vecLinBuffT < (max(vecLinBuffT) - 1);
		
		%message
		cellText(end+1:end+2) = {'',sprintf('Processing new SGL data [%.3fs - %.3fs] ...',min(vecLinBuffT(vecUseBuffData)),max(vecLinBuffT(vecUseBuffData)))};
		OT_updateTextInformation(cellText);
		
		%retrieve which data to use, subsample & assign to env
		if isempty(sOT.vecSubTimestamps)
			dblPrevEnv = max(vecLinBuffT) - 2;
		else
			dblPrevEnv = sOT.vecSubTimestamps(end);
		end
		vecUseSubT = (dblPrevEnv+dblSubSampleTo):dblSubSampleTo:(max(vecLinBuffT) - 1);
		intStartT = find(vecLinBuffT>vecUseSubT(1),1);
		intStopT = find(vecLinBuffT>vecUseSubT(end),1);
		vecKeepIM = intStartT:intSubSampleFactorIM:intStopT;
		matSubNewData = matLinBuffData(vecKeepIM,:)';
		%matSubNewData = nan(size(matLinBuffData,2),numel(vecKeepIM));
		
		% apply high-pass filter & calculate envelope
		if dblFiltFreq > 0 || boolCalcEnv
			%design filter
			if ~isempty(dblFiltFreq) && dblFiltFreq > 0
				d = designfilt('highpassfir',...
					'SampleRate',dblSampFreqIM, ...
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
			%apply to channels
			for intCh=1:size(matLinBuffData,2)
				%get signal
				if boolUseGPU
					gVecSignal = gpuArray(double(matLinBuffData(vecKeepIM,intCh)'));
				else
					gVecSignal = double(matLinBuffData(vecKeepIM,intCh)');
				end
				
				%filter
				if ~isempty(dblFiltFreq) && dblFiltFreq > 0
					gVecSignal = fftfilt(gVecFilter,gVecSignal);
					
					%gVecSignal = highpass(gVecSignal,dblFiltFreq,dblSampFreq);
				end
				%envelope
				if boolCalcEnv
					intFilterSize = round(dblSampFreqIM);
					[vecEnvHigh,vecEnvLow] = getEnvelope(gVecSignal,intFilterSize);
					%downsample
					vecSubEnv = gather(abs(vecEnvHigh)+abs(vecEnvLow));
					
					%assign data
					matSubNewData(intCh,:) = vecSubEnv;
				else
					%assign data
					matSubNewData(intCh,:) = gather(gVecSignal);
				end
			end
		else
			matSubNewData = double(matSubNewData);
			matSubNewData = bsxfun(@minus,matSubNewData,median(matSubNewData,2));
			matSubNewData = (matSubNewData.*(abs(zscore(matSubNewData,[],2))>1)).^2;
		end
		
		%assign data
		sOT.vecSubTimestamps = cat(2,sOT.vecSubTimestamps,vecUseSubT);
		sOT.matSubData = cat(2,sOT.matSubData,matSubNewData);
		
		%msg
		cellText{end} = strcat(cellText{end},'  Completed!');
		OT_updateTextInformation(cellText);
	end
	
	%% retrieve & update stim log data
	%get stimulus object files
	sFiles = dir(strcat(strStimPath,filesep,'Object*.mat'));
	cellNames = {sFiles(:).name};
	vecObjectID = cellfun(@str2double,cellfun(@getFlankedBy,cellNames,cellfill('Object',size(cellNames)),cellfill('.mat',size(cellNames)),'uniformoutput',false));
	vecNewObjectIDs = sort(vecObjectID(vecObjectID>intStimTrialN),'descend');
	if ~isempty(vecNewObjectIDs)
		%if there is new data, load it
		for intLoadObject=vecNewObjectIDs
			sLoad = load([strStimPath filesep sprintf('Object%d.mat',intLoadObject)]);
			sStimObject(intLoadObject) = sLoad.sObject;
		end

		%update variables
		vecNewStimOnT = cell2mat({sStimObject(:).dblStimOnNI});
		vecNewStimOffT = cell2mat({sStimObject(:).dblStimOffNI});
		vecOriDegs = cell2mat({sStimObject(:).Orientation});
		[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
		dblStimTrialT = max(cat(2,vecNewStimOnT,vecNewStimOffT));
		intStimTrialN = vecNewObjectIDs(1);
		dblStimCoverage = (intStimTrialN/numel(vecUnique))*100;
		%save vars
		sOT.sStimObject = sStimObject;
		sOT.dblStimCoverage = dblStimCoverage;
		sOT.intStimTrialN = intStimTrialN;
		sOT.dblStimTrialT = dblStimTrialT;
		sOT.vecStimOnT = vecNewStimOnT;
		sOT.vecStimOffT = vecNewStimOffT;
		
		%update fig
		set(sFig.ptrTextStimTrialT, 'string',sprintf('%.2f',dblStimTrialT));
		set(sFig.ptrTextStimTrialN, 'string',sprintf('%d',intStimTrialN));
		set(sFig.ptrTextStimCoverage, 'string',sprintf('%.2f',dblStimCoverage));
		set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
		drawnow;

		%msg
		cellText{end+1} = sprintf('Loaded %d stimulus objects',numel(vecNewObjectIDs));
		cellText{end+1} = '';
		OT_updateTextInformation(cellText);
	end
	
	%% update trial-average data matrix
	intTrials = min([intEphysTrialN intStimTrialN]);
	if intTrials > intRespTrialN
		%% calc RF estimate
		%update variables
		vecOriDegs = cell2mat({sStimObject(:).Orientation});
		[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
		
		%get data
		vecTimestamps = sOT.vecSubTimestamps;
		matData = sOT.matSubData;
		vecStimOnT = sOT.vecDiodeOnT; %on times of all stimuli (diode on time)
		vecStimOffT = sOT.vecDiodeOffT; %off times of all stimuli (diode off time)
	
		%get selected channels
		vecUseChans = sOT.vecUseChans;
		intMaxChan = sOT.intMaxChan;
		intMinChan = sOT.intMinChan;
		vecSelectChans = vecUseChans(intMinChan:intMaxChan)+1;
		
		%base, stim
		matRespBase = nan(numel(vecSelectChans),intTrials);
		matRespStim = nan(numel(vecSelectChans),intTrials);
		vecStimTypes = nan(1,intTrials);
		vecStimOriDeg = nan(1,intTrials);
		%go through objects and assign to matrices
		for intTrial=1:intTrials
			%get orientation
			intStimType = vecTrialIdx(intTrial);

			%get data
			if intTrial==1
				dblStartTrial = vecStimOnT(intTrial)-median(vecStimOffT-vecStimOnT)+0.1;
			else
				dblStartTrial = vecStimOffT(intTrial-1)+0.1;
			end
			dblStartStim = vecStimOnT(intTrial);
			dblStopStim = vecStimOffT(intTrial);
			vecBaseBins = find(vecTimestamps>dblStartTrial):find(vecTimestamps>dblStartStim);
			vecStimBins = find(vecTimestamps>dblStartStim):find(vecTimestamps>dblStopStim);
			%if ePhys data is not available yet, break
			if isempty(vecBaseBins) || isempty(vecStimBins)
				break;
			end
			vecBaseResp = mean(matData(vecSelectChans,vecBaseBins),2)./numel(vecBaseBins);
			vecStimResp = mean(matData(vecSelectChans,vecStimBins),2)./numel(vecStimBins);
			%size(matData)
			%min(vecBaseBins)
			%max(vecBaseBins)
			%assign data
			matRespBase(:,intTrial) = vecBaseResp;
			matRespStim(:,intTrial) = vecStimResp;
			vecStimTypes(intTrial) = intStimType;
			vecStimOriDeg(intTrial) = vecOriDegs(intTrial);
		end

		%% save data to globals
		sOT.intRespTrialN = intTrials;
		sOT.vecSelectChans = vecSelectChans;
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

