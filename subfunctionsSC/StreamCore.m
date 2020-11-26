function [sFig,sStream,boolDidSomething] = StreamCore(sFig,sStream,f_updateTextInformation)
	%StreamCore Streaming Interface shared core module
	%   [sFig,sStream,boolDidSomething] = StreamCore(sFig,sStream,f_updateTextInformation)
	%
	%StreamCore handles the IMEC and NI data streams.
	%
	%inputs:
	% - sFig: handles to GUI
	% - sStream: online stream data structure; e.g., sRM, sOT etc
	% - f_updateTextInformation: function handle to update GUI messages
	%
	%Version 1.0 [2020-11-26]
	%	Split from RM_main/OT_main to standardized module by Jorrit Montijn
	
	%check update function
	if nargin < 3 || isempty(f_updateTextInformation)
		f_updateTextInformation = @SC_updateTextInformation;
	end
	
	%get stream variables
	boolDidSomething = false;
	cellText = {};
	intUseStreamIMEC = get(sFig.ptrListSelectProbe,'Value');
	intStimSyncChanNI = sStream.intStimSyncChanNI;
	intLastFetchNI = sStream.intLastFetchNI;
	intLastFetchIM = sStream.intLastFetchIM;
	dblSampFreqNI = sStream.dblSampFreqNI;
	dblSampFreqIM = sStream.dblSampFreqIM;
	dblEphysTimeNI = sStream.dblEphysTimeNI;
	dblEphysTimeIM = sStream.dblEphysTimeIM;
	dblEphysStepSecs = 5;
	intEphysTrialN = sStream.intEphysTrialN; %not used, only updated
	dblEphysTrialT = sStream.dblEphysTrialT; %not used, only updated
	
	%get probe variables
	sChanMap = sStream.sChanMap;
	sP = DP_GetParamStruct;
	dblStreamBufferSize = 5; %stream buffer size should be 8 seconds, but we'll set the maximum retrieval lower to be safe
	intMaxFetchIM = round(dblSampFreqIM*dblStreamBufferSize);
	intMaxFetchNI = round(dblSampFreqNI*dblStreamBufferSize);
	
	%update
	sStream.vecSelectChans = sStream.intMinChan:sStream.intMaxChan;
	sStream.vecActChans = sStream.vecSpkChans(ismember(sStream.vecSpkChans,sStream.vecSelectChans));
	
	%get data variables
	vecOldTimestampsNI = sStream.vecTimestampsNI;
	vecOldSyncData = sStream.vecSyncData;
	intDataBufferPos = sStream.intDataBufferPos;
	intDataBufferSize = sStream.intDataBufferSize;
	dblDataBufferSize = sStream.dblDataBufferSize;
	vecAllChans = sStream.vecAllChans; %AP, LFP, NI; 0-start
	vecSpkChans = sStream.vecSpkChans; %AP; 0-start
	vecIncChans = sStream.vecIncChans; %AP, minus culled; 0-start
	vecSelectChans = sStream.vecSelectChans; %AP, selected chans; 1-start
	vecActChans = sStream.vecActChans ; %AP, active channels (selected and unculled); 0-start
	
	boolChannelsCulled = sStream.boolChannelsCulled;
	
	%get stimulus variables
	vecOldStimOnT = sStream.vecStimOnT; %on times of all stimuli (NI time prior to stim on)
	vecOldStimOffT = sStream.vecStimOffT; %off times of all stimuli (NI time after stim off)
	vecDiodeOnT = sStream.vecDiodeOnT; %on times of all stimuli (diode on time)
	vecDiodeOffT = sStream.vecDiodeOffT; %off times of all stimuli (diode off time)
	
	% SGL data
	%set stream IDs
	vecStreamIM = [0];
	intStreamIM = vecStreamIM(intUseStreamIMEC);
	strStreamIM = sprintf( 'GETSCANCOUNT %d', intStreamIM);
	intStreamNI = -1;
	strStreamNI = sprintf( 'GETSCANCOUNT %d', intStreamNI);
	
	%prep meta data
	dblSubSampleFactorNI = sStream.dblSubSampleFactorNI;
	dblSubSampleTo = sStream.dblSubSampleTo;
	intDownsampleNI = 1;
	intDownsampleIM = 1;
	
	%% get NI I/O box data
	%get current scan number for NI streams
	intCurCountNI = GetScanCount(sStream.hSGL, intStreamNI);
	
	%check if this is the initial fetch
	if intLastFetchNI == 0
		intRetrieveSamplesNI = round(1*dblSampFreqNI); %retrieve last 0.1 seconds
		intRetrieveSamplesNI = min(intCurCountNI-1,intRetrieveSamplesNI); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountNI - intRetrieveSamplesNI; %set last fetch to starting position
		dblLastTimestampNI = intStartFetch;
	else
		intStartFetch = intLastFetchNI - round(dblSampFreqNI);
		intStartFetch = max(intStartFetch,1); %ensure we're not requesting data prior to start
		intRetrieveSamplesNI = intCurCountNI - intStartFetch; %retrieve as many samples as acquired between previous fetch and now, plus 500ms
		dblLastTimestampNI = vecOldTimestampsNI(end);
	end
	
	%check that requested fetch does not exceed buffer limit
	if intRetrieveSamplesNI > intMaxFetchNI
		%crop Fetch
		intRetrieveSamplesNI = intMaxFetchNI;
		%send warning
		feval(f_updateTextInformation,sprintf('<< WARNING >> Requested NI Fetch was %.1fs, max query is %.1fs',...
			intRetrieveSamplesNI/dblSampFreqNI,intMaxFetchNI/dblSampFreqNI));
		
		%crop Fetch
		intRetrieveSamplesNI = intMaxFetchNI;
	end
	
	%get NI data
	if intRetrieveSamplesNI > 0
		%fetch in try-catch block
		try
			%fetch "intRetrieveSamplesNI" samples starting at "intFetchStartCountNI"
			[vecStimSyncDataNI,intStartCountNI] = Fetch(sStream.hSGL, intStreamNI, intStartFetch, intRetrieveSamplesNI, intStimSyncChanNI,intDownsampleNI);
		catch ME
			%buffer has likely already been cleared; unable to fetch data
			cellText = {'<< ERROR >>',ME.identifier,ME.message};
			feval(f_updateTextInformation,cellText);
			return;
		end
	end
	%update NI time
	dblEphysTimeNI = intCurCountNI/dblSampFreqNI;
	set(sFig.ptrTextTimeNI,'string',sprintf('%.3f',dblEphysTimeNI));
	%save to globals
	sStream.intLastFetchNI = intCurCountNI;
	sStream.dblEphysTimeNI = dblEphysTimeNI;
	
	%process NI data
	vecTimeNI = ((intStartFetch+1):intDownsampleNI:intCurCountNI)/dblSampFreqNI;
	intStartT = find(vecTimeNI>(dblLastTimestampNI+dblSubSampleTo),1);
	if isempty(intStartT),intStartT=1;end
	vecKeepNI = round(intStartT:dblSubSampleFactorNI:intRetrieveSamplesNI);
	vecNewTimestampsNI = vecTimeNI(vecKeepNI);
	vecNewSyncData = sStream.NI2V*single(flat(vecStimSyncDataNI(vecKeepNI))'); %transform to voltage
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
	feval(f_updateTextInformation,cellText);
	
	%save data to globals
	sStream.vecTimestampsNI = vecTimestampsNI;
	sStream.vecSyncData = vecSyncData;
	sStream.vecDiodeOnT = vecDiodeOnT; %on times of all stimuli (diode on time)
	sStream.vecDiodeOffT = vecDiodeOffT; %off times of all stimuli (diode off time)
	sStream.intEphysTrialN = min([numel(vecDiodeOnT) numel(vecDiodeOffT)]);
	if sStream.intEphysTrialN == 0
		sStream.dblEphysTrialT = 0;
	else
		sStream.dblEphysTrialT = max([vecDiodeOnT(sStream.intEphysTrialN),vecDiodeOffT(sStream.intEphysTrialN)]);
	end
	
	%update figure
	set(sFig.ptrTextStimNI, 'string',sprintf('%.2f (%d)',sStream.dblEphysTrialT,sStream.intEphysTrialN));
	
	%% get IMEC data
	%get current scan number for NI streams
	intCurCountIM = GetScanCount(sStream.hSGL, intStreamIM);
	
	%check if this is the initial fetch
	if intLastFetchIM == 0
		intRetrieveSamplesIM = round(1*dblSampFreqIM); %retrieve last 0.1 seconds
		intRetrieveSamplesIM = min(intCurCountIM-1,intRetrieveSamplesIM); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountIM - intRetrieveSamplesIM; %set last fetch to starting position
	else
		intStartFetch = intLastFetchIM - round(dblSampFreqIM);
		intStartFetch = max(intStartFetch,1); %ensure we're not requesting data prior to start
		intRetrieveSamplesIM = intCurCountIM - intStartFetch; %retrieve as many samples as acquired between previous fetch and now, plus 500ms
	end
	
	%check that requested fetch does not exceed buffer limit
	if intRetrieveSamplesIM > intMaxFetchIM
		%crop Fetch
		intRetrieveSamplesIM = intMaxFetchIM;
		%send warning
		feval(f_updateTextInformation,sprintf('<< WARNING >> Requested IMEC Fetch was %.1fs, max query is %.1fs',...
			intRetrieveSamplesIM/dblSampFreqIM,intMaxFetchIM/dblSampFreqIM));
		
		%crop Fetch
		intRetrieveSamplesIM = intMaxFetchIM;
	end
	
	%get IM data
	if intRetrieveSamplesIM > 0
		%fetch in try-catch block
		try
			%fetch "intRetrieveSamplesIM" samples starting at "intFetchStartCountIM"
			[matNewData,intStartCountIM] = Fetch(sStream.hSGL, intStreamIM, intStartFetch, intRetrieveSamplesIM, vecSpkChans,intDownsampleIM);
			
			%% CHECK: if channels are missing in vecSpkChans, is matNewData size of vecSpikeChans or of [t x 384]?
			%% chans vecSpkChans to vecIncChans to select only unculled channels
		catch ME
			%buffer has likely already been cleared; unable to fetch data
			cellText = {'<< ERROR >>',ME.identifier,ME.message};
			feval(f_updateTextInformation,cellText);
			return;
		end
	end
	%update IM time
	dblEphysTimeIM = intCurCountIM/dblSampFreqIM;
	set(sFig.ptrTextTimeIM,'string',sprintf('%.3f',dblEphysTimeIM));
	%save to globals
	sStream.intLastFetchIM = intCurCountIM;
	sStream.dblEphysTimeIM = dblEphysTimeIM;
	
	%put data in buffer
	vecNewTimestampsIM = intStartFetch:(intStartFetch+intRetrieveSamplesIM-1);
	vecAssignBufferPos = modx(intDataBufferPos:(intDataBufferPos+numel(vecNewTimestampsIM)-1),intDataBufferSize);
	%assign to global
	sStream.intDataBufferPos = modx(vecAssignBufferPos(end)+1,intDataBufferSize);
	sStream.vecTimestampsIM(vecAssignBufferPos) = vecNewTimestampsIM;
	sStream.matDataBufferIM(vecAssignBufferPos,:) = matNewData;
	sStream.dblSubLastUpdate = sStream.dblSubLastUpdate + range(vecNewTimestampsIM)/dblSampFreqIM;
	
	%% update data
	if sStream.dblSubLastUpdate > 1 %if last subsample update is more than 1 second ago
		%unroll buffer
		[vecLinBuffT,vecReorderData] = sort(sStream.vecTimestampsIM,'ascend');
		vecLinBuffT = vecLinBuffT/dblSampFreqIM;
		matLinBuffData = sStream.matDataBufferIM(vecReorderData,:); %time by channel
		vecUseBuffData = vecLinBuffT < (max(vecLinBuffT) - 1);
		
		%message
		cellText = {'',sprintf('Processing new SGL data [%.3fs - %.3fs] ...',min(vecLinBuffT(vecUseBuffData)),max(vecLinBuffT(vecUseBuffData)))};
		feval(f_updateTextInformation,cellText);
		
		%retrieve which data to use, subsample & assign
		if isempty(sStream.dblCurrT)
			dblCurrT = max(vecLinBuffT) - 5;
		else
			dblCurrT = sStream.dblCurrT;
		end
		indKeepIM = vecLinBuffT>dblCurrT & vecLinBuffT<(max(vecLinBuffT) - 1);
		matSubNewData = matLinBuffData(indKeepIM,:)';
		vecSubNewTime = vecLinBuffT(indKeepIM);
		
		%% detect spikes
		%detect spikes on all channels
		[gVecSubNewSpikeCh,gVecSubNewSpikeT,dblSubNewTotT] = DP_DetectSpikes(matSubNewData, sP);
		sStream.dblCurrT = sStream.dblCurrT + dblSubNewTotT;
		vecSubNewSpikeCh = gather(gVecSubNewSpikeCh);
		vecSubNewSpikeT = gather(gVecSubNewSpikeT);
		%clear gpuArrays
		gVecSubNewSpikeT = [];
		gVecSubNewSpikeCh = [];
		
		% assign data
		intStartT = uint32(vecSubNewTime(1)*1000);
		if numel(vecSubNewSpikeCh) > 0
			sStream.vecSubSpikeCh = cat(1,sStream.vecSubSpikeCh,vecSubNewSpikeCh(:));
			sStream.vecSubSpikeT = cat(1,sStream.vecSubSpikeT,vecSubNewSpikeT(:) + intStartT);
		end
		
		%msg
		feval(f_updateTextInformation,sprintf('  %d new spikes.',numel(vecSubNewSpikeCh)));
		boolDidSomething = true;
		
		%% check if channels are culled yet & if first repetition is finished
		if 0%boolChannelsCulled && sRM.dblStimCoverage > 100 && numel(sRM.vecSubSpikeCh) > 10000
			%msg
			feval(f_updateTextInformation,sprintf('Time for channel cull! Using %d spikes...',numel(sRM.vecSubSpikeCh)));
			
			%when initial run is complete, calc channel cull
			vecUseChannelsFilt = DP_CullChannels(sRM.vecSubSpikeCh,sRM.vecSubSpikeT,dblSubNewTotT,sP,sChanMap);
			
			%update vecSpkChans & boolChannelsCulled
			sRM.vecSpkChans = sRM.vecSpkChans(vecUseChannelsFilt);
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
			feval(f_updateTextInformation,sprintf('   Completed! %d channels removed.',sum(vecRemovedChans)));
		end
	end
	
end

