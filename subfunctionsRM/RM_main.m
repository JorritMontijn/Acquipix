function RM_main(varargin)
	%% RM_main Main RF mapper function called every second to check for updates
	%get globals
	global sFig;
	global sRM;
	
	try
		%% check if busy
		cellText = {};
		
		%check initialization
		if ~sRM.IsInitialized,return;end
		%check if busy
		if sFig.boolIsBusy,return;end
		%% retrieve variables
		sFig.boolIsBusy = true;
		boolDidSomething = false;
		
		%get stream variables
		intUseStreamIMEC = get(sFig.ptrListSelectProbe,'Value');
		intStimSyncChanNI = sRM.intStimSyncChanNI;
		intLastFetchNI = sRM.intLastFetchNI;
		intLastFetchIM = sRM.intLastFetchIM;
		dblSampFreqNI = sRM.dblSampFreqNI;
		dblSampFreqIM = sRM.dblSampFreqIM;
		dblEphysTimeNI = sRM.dblEphysTimeNI;
		dblEphysTimeIM = sRM.dblEphysTimeIM;
		dblEphysStepSecs = 5;
		intEphysTrialN = sRM.intEphysTrialN; %not used, only updated
		dblEphysTrialT = sRM.dblEphysTrialT; %not used, only updated
		intStimTrialN = sRM.intStimTrialN;
		dblStimTrialT = sRM.dblStimTrialT;
		
		%get probe variables
		sChanMap = sRM.sChanMap;
		sP = DP_GetParamStruct;
		
		%get data variables
		sStimObject = sRM.sStimObject;
		if isempty(sStimObject),clear sStimObject;end
		vecOldTimestampsNI = sRM.vecTimestampsNI;
		vecOldSyncData = sRM.vecSyncData;
		intDataBufferPos = sRM.intDataBufferPos;
		intDataBufferSize = sRM.intDataBufferSize;
		dblDataBufferSize = sRM.dblDataBufferSize;
		vecAllChans = sRM.vecAllChans;
		vecUseChans = sRM.vecUseChans;
		vecSpkChans = sRM.vecSpkChans;
		boolChannelsCulled = sRM.boolChannelsCulled;
		
		%get stimulus variables
		vecOldStimOnT = sRM.vecStimOnT; %on times of all stimuli (NI time prior to stim on)
		vecOldStimOffT = sRM.vecStimOffT; %off times of all stimuli (NI time after stim off)
		vecDiodeOnT = sRM.vecDiodeOnT; %on times of all stimuli (diode on time)
		vecDiodeOffT = sRM.vecDiodeOffT; %off times of all stimuli (diode off time)
		
		%get resp variables
		intRespTrialN = sRM.intRespTrialN;
		
		%get data from figure
		strStimPath = get(sFig.ptrTextStimPath, 'string');
		
		%default high-pass frequency
		dblFiltFreq = str2double(get(sFig.ptrEditHighpassFreq,'String'));
		
		%use GPU?
		boolUseGPU = sRM.UseGPU;
		
		% SGL data
		%set stream IDs
		vecStreamIM = [0];
		intStreamIM = vecStreamIM(intUseStreamIMEC);
		strStreamIM = sprintf( 'GETSCANCOUNT %d', intStreamIM);
		intStreamNI = -1;
		strStreamNI = sprintf( 'GETSCANCOUNT %d', intStreamNI);
		
		%prep meta data
		dblSubSampleFactorNI = sRM.dblSubSampleFactorNI;
		dblSubSampleTo = sRM.dblSubSampleTo;
		intDownsampleNI = 1;
		intDownsampleIM = 1;
		
		%% get NI I/O box data
		%get current scan number for NI streams
		intCurCountNI = GetScanCount(sRM.hSGL, intStreamNI);
		
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
				[vecStimSyncDataNI,intStartCountNI] = Fetch(sRM.hSGL, intStreamNI, intStartFetch, intRetrieveSamplesNI, intStimSyncChanNI,intDownsampleNI);
			catch ME
				%buffer has likely already been cleared; unable to fetch data
				cellText = {'<< ERROR >>',ME.identifier,ME.message};
				RM_updateTextInformation(cellText);
				return;
			end
		end
		%update NI time
		dblEphysTimeNI = intCurCountNI/dblSampFreqNI;
		set(sFig.ptrTextTimeNI,'string',sprintf('%.3f',dblEphysTimeNI));
		%save to globals
		sRM.intLastFetchNI = intCurCountNI;
		sRM.dblEphysTimeNI = dblEphysTimeNI;
		
		%process NI data
		vecTimeNI = ((intStartFetch+1):intDownsampleNI:intCurCountNI)/dblSampFreqNI;
		intStartT = find(vecTimeNI>(dblLastTimestampNI+dblSubSampleTo),1);
		if isempty(intStartT),intStartT=1;end
		vecKeepNI = round(intStartT:dblSubSampleFactorNI:intRetrieveSamplesNI);
		vecNewTimestampsNI = vecTimeNI(vecKeepNI);
		vecNewSyncData = sRM.NI2V*single(flat(vecStimSyncDataNI(vecKeepNI))'); %transform to voltage
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
		[vecDiodeOnT,cellTextOn] = RM_getStimT(vecDiodeOnT,vecOldStimOnT,vecOnsets,[],dblMaxErrorT);
		if numel(vecDiodeOnT) > intOldOn
			cellText(end+1) = {['ON, ' cellTextOn{end}]}; %remove 'ON'
		end
		
		%get offsets
		intOldOff = numel(vecDiodeOffT);
		vecOffsets = vecUseTimestampsNI(vecSignChange == -1);
		[vecDiodeOffT,cellTextOff] = RM_getStimT(vecDiodeOffT,vecOldStimOffT,vecOffsets,[],dblMaxErrorT);
		if numel(vecDiodeOffT) > intOldOff
			cellText(end+1) = {['OFF, ' cellTextOff{end}]}; %remove 'ON'
		end
		
		%msg
		RM_updateTextInformation(cellText);
		
		%save data to globals
		sRM.vecTimestampsNI = vecTimestampsNI;
		sRM.vecSyncData = vecSyncData;
		sRM.vecDiodeOnT = vecDiodeOnT; %on times of all stimuli (diode on time)
		sRM.vecDiodeOffT = vecDiodeOffT; %off times of all stimuli (diode off time)
		sRM.intEphysTrialN = min([numel(vecDiodeOnT) numel(vecDiodeOffT)]);
		if sRM.intEphysTrialN == 0
			sRM.dblEphysTrialT = 0;
		else
			sRM.dblEphysTrialT = max([vecDiodeOnT(sRM.intEphysTrialN),vecDiodeOffT(sRM.intEphysTrialN)]);
		end
		
		%update figure
		set(sFig.ptrTextStimNI, 'string',sprintf('%.2f (%d)',sRM.dblEphysTrialT,sRM.intEphysTrialN));
		
		%% get IMEC data
		%get current scan number for NI streams
		intCurCountIM = GetScanCount(sRM.hSGL, intStreamIM);
		
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
				[matNewData,intStartCountIM] = Fetch(sRM.hSGL, intStreamIM, intStartFetch, intRetrieveSamplesIM, vecSpkChans,intDownsampleIM);
			catch ME
				%buffer has likely already been cleared; unable to fetch data
				cellText = {'<< ERROR >>',ME.identifier,ME.message};
				RM_updateTextInformation(cellText);
				return;
			end
		end
		%update IM time
		dblEphysTimeIM = intCurCountIM/dblSampFreqIM;
		set(sFig.ptrTextTimeIM,'string',sprintf('%.3f',dblEphysTimeIM));
		%save to globals
		sRM.intLastFetchIM = intCurCountIM;
		sRM.dblEphysTimeIM = dblEphysTimeIM;
		
		%put data in buffer
		vecNewTimestampsIM = intStartFetch:(intStartFetch+intRetrieveSamplesIM-1);
		vecAssignBufferPos = modx(intDataBufferPos:(intDataBufferPos+numel(vecNewTimestampsIM)-1),intDataBufferSize);
		%assign to global
		sRM.intDataBufferPos = modx(vecAssignBufferPos(end)+1,intDataBufferSize);
		sRM.vecTimestampsIM(vecAssignBufferPos) = vecNewTimestampsIM;
		sRM.matDataBufferIM(vecAssignBufferPos,:) = matNewData;
		sRM.dblSubLastUpdate = sRM.dblSubLastUpdate + range(vecNewTimestampsIM)/dblSampFreqIM;
		
		%% update data
		if sRM.dblSubLastUpdate > 1 %if last subsample update is more than 1 second ago
			%unroll buffer
			[vecLinBuffT,vecReorderData] = sort(sRM.vecTimestampsIM,'ascend');
			vecLinBuffT = vecLinBuffT/dblSampFreqIM;
			matLinBuffData = sRM.matDataBufferIM(vecReorderData,:); %time by channel
			vecUseBuffData = vecLinBuffT < (max(vecLinBuffT) - 1);
			
			%message
			cellText(end+1:end+2) = {'',sprintf('Processing new SGL data [%.3fs - %.3fs] ...',min(vecLinBuffT(vecUseBuffData)),max(vecLinBuffT(vecUseBuffData)))};
			if numel(cellText) == 2,cellText(1) = [];end
			RM_updateTextInformation(cellText);
			
			%retrieve which data to use, subsample & assign
			if isempty(sRM.dblCurrT)
				dblCurrT = max(vecLinBuffT) - 5;
			else
				dblCurrT = sRM.dblCurrT;
			end
			indKeepIM = vecLinBuffT>dblCurrT & vecLinBuffT<(max(vecLinBuffT) - 1);
			matSubNewData = matLinBuffData(indKeepIM,:)';
			vecSubNewTime = vecLinBuffT(indKeepIM);
			
			%% detect spikes
			%detect spikes on all channels
			[gVecSubNewSpikeCh,gVecSubNewSpikeT,dblSubNewTotT] = DP_DetectSpikes(matSubNewData, sP);
			sRM.dblCurrT = sRM.dblCurrT + dblSubNewTotT;
			vecSubNewSpikeCh = gather(gVecSubNewSpikeCh);
			vecSubNewSpikeT = gather(gVecSubNewSpikeT);
			%clear gpuArrays
			gVecSubNewSpikeT = [];
			gVecSubNewSpikeCh = [];
			
			% assign data
			intStartT = uint32(vecSubNewTime(1)*1000);
			if numel(vecSubNewSpikeCh) > 0
				sRM.vecSubSpikeCh = cat(1,sRM.vecSubSpikeCh,vecSubNewSpikeCh(:));
				sRM.vecSubSpikeT = cat(1,sRM.vecSubSpikeT,vecSubNewSpikeT(:) + intStartT);
			end
			
			%msg
			cellText{end} = strcat(cellText{end},sprintf('  %d new spikes.',numel(vecSubNewSpikeCh)));
			RM_updateTextInformation(cellText);
			boolDidSomething = true;
			
			%% check if channels are culled yet & if first repetition is finished
			if ~boolChannelsCulled && sRM.dblStimCoverage > 100 && numel(sRM.vecSubSpikeCh) > 10000
				%msg
				cellText{end+1} = sprintf('Time for channel cull! Using %d spikes...',numel(sRM.vecSubSpikeCh));
				RM_updateTextInformation(cellText);
				
				%when initial run is complete, calc channel cull
				vecUseChannelsFilt = DP_CullChannels(sRM.vecSubSpikeCh,sRM.vecSubSpikeT,dblSubNewTotT,sP,sChanMap);
				
				%update vecSpkChans & boolChannelsCulled
				sRM.vecSpkChans = vecUseChans(vecUseChannelsFilt);
				sRM.boolChannelsCulled = true;
				
				%remove channels from sRM.matDataBufferIM
				vecRemovedChans = ~ismember(1:size(matSubNewData,1),vecUseChannelsFilt);
				sRM.matDataBufferIM(:,vecRemovedChans) = [];
				
				%remove channels from vecSpikeCh and vecSpikeT
				vecRemovedSpikes = ~ismember(sRM.vecSubSpikeCh,vecUseChannelsFilt);
				sRM.vecSubSpikeCh(vecRemovedSpikes) = [];
				sRM.vecSubSpikeT(vecRemovedSpikes) = [];
				%update channel ID of remaining channels
				[dummy,vecNewCh]=find(sRM.vecSubSpikeCh==vecUseChannelsFilt');
				sRM.vecSubSpikeCh = vecNewCh(:);
				
				%msg
				cellText{end} = strcat(cellText{end},sprintf('   Completed! %d channels removed.',sum(vecRemovedChans)));
				RM_updateTextInformation(cellText);
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
			vecNewStimOnT = cell2mat({sStimObject(:).ActOnNI});
			vecNewStimOffT = cell2mat({sStimObject(:).ActOffNI});
			dblStimTrialT = max(cat(2,vecNewStimOnT,vecNewStimOffT));
			intStimTrialN = vecNewObjectIDs(1);
			dblStimCoverage = 100*sum(sStimObject(end).UsedLinLocOff(:))/numel(sStimObject(end).UsedLinLocOff);
			
			%save vars
			sRM.sStimObject = sStimObject;
			sRM.dblStimCoverage = dblStimCoverage;
			sRM.intStimTrialN = intStimTrialN;
			sRM.dblStimTrialT = dblStimTrialT;
			sRM.vecStimOnT = vecNewStimOnT;
			sRM.vecStimOffT = vecNewStimOffT;
			sRM.FlickerFreq = sStimObject(end).FlickerFreq;
			
			%update fig
			set(sFig.ptrTextStimTrialT, 'string',sprintf('%.2f',dblStimTrialT));
			set(sFig.ptrTextStimTrialN, 'string',sprintf('%d',intStimTrialN));
			set(sFig.ptrTextStimCoverage, 'string',sprintf('%.2f',dblStimCoverage));
			set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
			drawnow;
			
			%msg
			cellText{end+1} = sprintf('Loaded %d stimulus objects',numel(vecNewObjectIDs));
			cellText{end+1} = '';
			RM_updateTextInformation(cellText);
			boolDidSomething = true;
		end
		
		%% update trial-average data matrix
		intTrials = min([intEphysTrialN intStimTrialN]);
		if intTrials > intRespTrialN
			%% calc RF estimate
			%ON, OFF, ON-base OFF-base
			cellStimON = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellBaseON = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellStimOFF = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellBaseOFF = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			
			%get data
			vecSpikeT = sRM.vecSubSpikeT; %time in ms (uint32)
			vecSpikeCh = sRM.vecSubSpikeCh; %channel id (uint16)
			vecStimOnT = sRM.vecDiodeOnT; %on times of all stimuli (diode on time)
			vecStimOffT = sRM.vecDiodeOffT; %off times of all stimuli (diode off time)
			
			%get selected channels
			vecUseSpkChans = sRM.vecSpkChans;
			intMaxChan = min(sRM.intMaxChan,numel(vecUseSpkChans));
			intMinChan = min(sRM.intMinChan,numel(vecUseSpkChans));
			vecSelectChans = intMinChan:intMaxChan;
			%go through objects and assign to matrices
			for intTrial=1:intTrials
				%get repetitions of locations
				vecLinLocOn = sStimObject(intTrial).LinLocOn;
				vecLinLocOff = sStimObject(intTrial).LinLocOff;
				matLinLoc = sStimObject(intTrial).LinLoc;
				
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
				vecBaseResp((end+1):intMaxChan) = 0;
				
				%stim resp
				vecStimResp = accumarray(vecSpikeCh(vecStimSpikes),1) ./ (dblStopStim - dblStartStim);
				vecStimResp((end+1):intMaxChan) = 0;
				%assign data
				for intLocOn=vecLinLocOn(:)'
					size(cellBaseON{matLinLoc==intLocOn})
					size(vecBaseResp)
					cellBaseON{matLinLoc==intLocOn}(:,end+1) = vecBaseResp;
					cellStimON{matLinLoc==intLocOn}(:,end+1) = vecStimResp;
				end
				for intLocOff=vecLinLocOff(:)'
					cellBaseOFF{matLinLoc==intLocOff}(:,end+1) = vecBaseResp;
					cellStimOFF{matLinLoc==intLocOff}(:,end+1) = vecStimResp;
				end
			end
			
			%% save data to globals
			sRM.intRespTrialN = intTrials;
			sRM.vecSelectChans = vecSelectChans;
			sRM.cellStimON = cellStimON; %[y by x] cell with [chan x rep] matrix
			sRM.cellBaseON = cellBaseON; %[y by x] cell with [chan x rep] matrix
			sRM.cellStimOFF = cellStimOFF; %[y by x] cell with [chan x rep] matrix
			sRM.cellBaseOFF = cellBaseOFF; %[y by x] cell with [chan x rep] matrix
			
			
			%% update maps
			RM_redraw(0);
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
	%end
	
	
	
