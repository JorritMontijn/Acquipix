function OT_main(varargin)
	%% OT_main Main OT mapper function called every second to check for updates
	%get globals
	global sFig;
	global sOT;
	
	try
		%% check if busy
		cellText = {};
		
		%check initialization
		if ~sOT.IsInitialized,return;end
		%check if busy
		if sFig.boolIsBusy,return;end
		%% retrieve variables
		sFig.boolIsBusy = true;
		boolDidSomething = false;
		
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
		
		%get probe variables
		sChanMap = sOT.sChanMap;
		sP = DP_GetParamStruct;
		
		%update
		sOT.vecSelectChans = sOT.intMinChan:sOT.intMaxChan;
		sOT.vecActChans = sOT.vecSpkChans(ismember(sOT.vecSpkChans,sOT.vecSelectChans));
		
		%get data variables
		sStimObject = sOT.sStimObject;
		if isempty(sStimObject),clear sStimObject;end
		vecOldTimestampsNI = sOT.vecTimestampsNI;
		vecOldSyncData = sOT.vecSyncData;
		intDataBufferPos = sOT.intDataBufferPos;
		intDataBufferSize = sOT.intDataBufferSize;
		dblDataBufferSize = sOT.dblDataBufferSize;
		
		vecAllChans = sOT.vecAllChans; %AP, LFP, NI; 0-start
		vecSpkChans = sOT.vecSpkChans; %AP; 0-start
		vecIncChans = sOT.vecIncChans; %AP, minus culled; 0-start
		vecSelectChans = sOT.vecSelectChans; %AP, selected chans; 1-start
		vecActChans = sOT.vecActChans ; %AP, active channels (selected and unculled); 0-start
		boolChannelsCulled = sOT.boolChannelsCulled;
		
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
		
		%get data from figure
		strStimPath = get(sFig.ptrTextStimPath, 'string');
		
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
		
		%keep last 6 seconds
		indKeepSync = vecSyncData > (vecSyncData(end) - 6);
		vecUseSyncData = vecSyncData(indKeepSync);
		vecUseTimestampsNI = vecTimestampsNI(indKeepSync);
		
		%find onset and offset of most recent stimulus
		dblMaxErrorT = 0.1; %discard onsets/offsets if temporal mismatch is more than x seconds
		[boolVecPhotoDiode,dblCritValPD] = DP_GetUpDown(-vecUseSyncData);
		vecSignChange = diff(boolVecPhotoDiode);
		
		%get onsets
		intOldOn = numel(vecDiodeOnT);
		vecOnsets = vecUseTimestampsNI(vecSignChange == 1);
		[vecDiodeOnT,cellTextOn] = OT_getStimT(vecDiodeOnT,vecOldStimOnT,vecOnsets,[],dblMaxErrorT);
		if numel(vecDiodeOnT) > intOldOn
			cellText(end+1) = {['ON, ' cellTextOn{end}]}; %remove 'ON'
		end
		
		%get offsets
		intOldOff = numel(vecDiodeOffT);
		vecOffsets = vecUseTimestampsNI(vecSignChange == -1);
		[vecDiodeOffT,cellTextOff] = OT_getStimT(vecDiodeOffT,vecOldStimOffT,vecOffsets,[],dblMaxErrorT);
		if numel(vecDiodeOffT) > intOldOff
			cellText(end+1) = {['OFF, ' cellTextOff{end}]}; %remove 'ON'
		end
		
		%msg
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
				[matNewData,intStartCountIM] = Fetch(sOT.hSGL, intStreamIM, intStartFetch, intRetrieveSamplesIM, vecSpkChans,intDownsampleIM);
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
			matLinBuffData = sOT.matDataBufferIM(vecReorderData,:); %time by channel
			vecUseBuffData = vecLinBuffT < (max(vecLinBuffT) - 1);
			
			%message
			cellText(end+1:end+2) = {'',sprintf('Processing new SGL data [%.3fs - %.3fs] ...',min(vecLinBuffT(vecUseBuffData)),max(vecLinBuffT(vecUseBuffData)))};
			if numel(cellText) == 2,cellText(1) = [];end
			OT_updateTextInformation(cellText);
			
			%retrieve which data to use, subsample & assign
			if isempty(sOT.dblCurrT)
				dblCurrT = max(vecLinBuffT) - 5;
			else
				dblCurrT = sOT.dblCurrT;
			end
			indKeepIM = vecLinBuffT>dblCurrT & vecLinBuffT<(max(vecLinBuffT) - 1);
			matSubNewData = matLinBuffData(indKeepIM,:)';
			vecSubNewTime = vecLinBuffT(indKeepIM);
			
			%% detect spikes
			%detect spikes on all channels
			[gVecSubNewSpikeCh,gVecSubNewSpikeT,dblSubNewTotT] = DP_DetectSpikes(matSubNewData, sP);
			sOT.dblCurrT = sOT.dblCurrT + dblSubNewTotT;
			vecSubNewSpikeCh = gather(gVecSubNewSpikeCh);
			vecSubNewSpikeT = gather(gVecSubNewSpikeT);
			%clear gpuArrays
			gVecSubNewSpikeT = [];
			gVecSubNewSpikeCh = [];
			
			% assign data
			intStartT = uint32(vecSubNewTime(1)*1000);
			if numel(vecSubNewSpikeCh) > 0
				sOT.vecSubSpikeCh = cat(1,sOT.vecSubSpikeCh,vecSubNewSpikeCh(:));
				sOT.vecSubSpikeT = cat(1,sOT.vecSubSpikeT,vecSubNewSpikeT(:) + intStartT);
			end
			
			%msg
			cellText{end} = strcat(cellText{end},sprintf('  %d new spikes.',numel(vecSubNewSpikeCh)));
			OT_updateTextInformation(cellText);
			boolDidSomething = true;
			
			%% check if channels are culled yet & if first repetition is finished
			if 0%~boolChannelsCulled && sOT.dblStimCoverage > 100 && numel(sOT.vecSubSpikeCh) > 10000
				%msg
				cellText{end+1} = sprintf('Time for channel cull! Using %d spikes...',numel(sOT.vecSubSpikeCh));
				OT_updateTextInformation(cellText);
				
				%when initial run is complete, calc channel cull
				vecUseChannelsFilt = DP_CullChannels(sOT.vecSubSpikeCh,sOT.vecSubSpikeT,dblSubNewTotT,sP,sChanMap);
				
				%update vecSpkChans & boolChannelsCulled
				sOT.vecSpkChans = vecUseChans(vecUseChannelsFilt);
				sOT.boolChannelsCulled = true;
				
				%remove channels from sOT.matDataBufferIM
				vecRemovedChans = ~ismember(1:size(matSubNewData,1),vecUseChannelsFilt);
				sOT.matDataBufferIM(:,vecRemovedChans) = [];
				
				%remove channels from vecSpikeCh and vecSpikeT
				vecRemovedSpikes = ~ismember(sOT.vecSubSpikeCh,vecUseChannelsFilt);
				sOT.vecSubSpikeCh(vecRemovedSpikes) = [];
				sOT.vecSubSpikeT(vecRemovedSpikes) = [];
				%update channel ID of remaining channels
				[dummy,vecNewCh]=find(sOT.vecSubSpikeCh==vecUseChannelsFilt');
				sOT.vecSubSpikeCh = vecNewCh(:);
				
				%msg
				cellText{end} = strcat(cellText{end},sprintf('   Completed! %d channels removed.',sum(vecRemovedChans)));
				OT_updateTextInformation(cellText);
			end
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
			boolDidSomething = true;
		end
		
		%% update trial-average data matrix
		intTrials = min([intEphysTrialN intStimTrialN]);
		if intTrials > intRespTrialN
			%% calc RF estimate
			%update variables
			vecOriDegs = cell2mat({sStimObject(:).Orientation});
			[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
			
			%get data
			vecSpikeT = sOT.vecSubSpikeT; %time in ms (uint32)
			vecSpikeCh = sOT.vecSubSpikeCh; %channel id (uint16)
			vecStimOnT = sOT.vecDiodeOnT; %on times of all stimuli (diode on time)
			vecStimOffT = sOT.vecDiodeOffT; %off times of all stimuli (diode off time)
			
			%get selected channels
			vecUseSpkChans = sOT.vecSpkChans;
			intMaxChan = min(sOT.intMaxChan,numel(vecUseSpkChans));
			intMinChan = min(sOT.intMinChan,numel(vecUseSpkChans));
			vecSelectChans = intMinChan:intMaxChan;
			intUseCh = numel(vecUseSpkChans);
			%fprintf('intUseCh=%d; selectchans=%d-%d\n',intUseCh,intMinChan,intMaxChan);
			
			%base, stim
			matRespBase = nan(intUseCh,intTrials);
			matRespStim = nan(intUseCh,intTrials);
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
				vecBaseSpikes = find(vecSpikeT>uint32(dblStartTrial*1000) & vecSpikeT<uint32(dblStartStim*1000));
				vecStimSpikes = find(vecSpikeT>uint32(dblStartStim*1000) & vecSpikeT<uint32(dblStopStim*1000));
				%if ePhys data is not available yet, break
				if isempty(vecBaseSpikes) || isempty(vecStimSpikes)
					continue;
				end
				
				%base resp
				vecBaseResp = accumarray(vecSpikeCh(vecBaseSpikes),1) ./ (dblStartStim - dblStartTrial);
				vecBaseResp(end+1:intUseCh) = 0;
				%stim resp
				vecStimResp = accumarray(vecSpikeCh(vecStimSpikes),1) ./ (dblStopStim - dblStartStim);
				vecStimResp(end+1:intUseCh) = 0;
				
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
			sOT.matRespBase = matRespBase(vecSelectChans,:); %[chan x rep] matrix
			sOT.matRespStim = matRespStim(vecSelectChans,:); %[chan x rep] matrix
			sOT.vecStimTypes = vecStimTypes; %
			sOT.vecStimOriDeg = vecStimOriDeg; %
			
			%% update maps
			OT_redraw(0);
			boolDidSomething = true;
		elseif ~boolDidSomething
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
	
