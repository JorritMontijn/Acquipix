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
	%Version 1.1 [2021-01-15]
	%	Major bug fixes and stability upgrades [by JM]
	
	%check update function
	if nargin < 3 || isempty(f_updateTextInformation)
		f_updateTextInformation = @SC_updateTextInformation;
	end
	
	%get stream variables
	boolDidSomething = true;
	cellText = {};
	intUseStreamIMEC = get(sFig.ptrListSelectProbe,'Value');
	intStimSyncChanNI = sStream.intStimSyncChanNI;
	intLastFetchNI = sStream.intLastFetchNI;
	intLastFetchIM = sStream.intLastFetchIM;
	dblSampFreqNI = sStream.dblSampFreqNI;
	dblSampFreqIM = sStream.dblSampFreqIM;
	dblEphysTimeNI = sStream.dblEphysTimeNI;
	dblEphysTimeIM = sStream.dblEphysTimeIM;
	dblSyncBufferSize = 30; %seconds
	intEphysTrialN = sStream.intEphysTrialN; %not used, only updated
	dblEphysTrialT = sStream.dblEphysTrialT; %not used, only updated
	
	%get probe variables
	sChanMap = sStream.sChanMap;
	sP = DP_GetParamStruct;
	dblStreamBufferSizeSGL = 5; %stream buffer size should be 8 seconds, but we'll set the maximum retrieval lower to be safe
	intMaxFetchIM = round(dblSampFreqIM*dblStreamBufferSizeSGL);
	intMaxFetchNI = round(dblSampFreqNI*dblStreamBufferSizeSGL);
	
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
	%get current scan number for IM streams
	warning('off','CalinsNetMex:connectionClosed');
	intCurCountNI = GetScanCount(sStream.hSGL, intStreamNI);
	
	%check if this is the initial fetch
	if intLastFetchNI == 0 || (intLastFetchNI < (intCurCountNI - intMaxFetchNI))
		intRetrieveSamplesNI = round(1*dblSampFreqNI); %retrieve last 0.1 seconds
		intRetrieveSamplesNI = min(intCurCountNI-1,intRetrieveSamplesNI); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountNI - intRetrieveSamplesNI; %set last fetch to starting position
		dblLastTimestampNI = intStartFetch;
	else
		intStartFetch = intLastFetchNI;% - round(dblSampFreqNI);
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
	
	%keep last dblSpikeBufferSize seconds
	indKeepSync = vecSyncData > (vecSyncData(end) - dblSyncBufferSize);
	vecUseSyncData = vecSyncData(indKeepSync);
	vecUseTimestampsNI = vecTimestampsNI(indKeepSync);
	
	%find onset and offset of most recent stimulus
	dblMaxErrorT = 0.1; %discard onsets/offsets if temporal mismatch is more than x seconds
	[boolVecPhotoDiode,dblCritValPD] = DP_GetUpDown(-vecUseSyncData);
	vecSignChange = diff(boolVecPhotoDiode);
	
	%get onsets
	intOldOn = numel(vecDiodeOnT);
	vecOnsets = vecUseTimestampsNI(vecSignChange == 1);
	[vecDiodeOnT,cellTextOn] = SC_getStimT(vecDiodeOnT,vecOldStimOnT,vecOnsets,[],dblMaxErrorT);
	if numel(vecDiodeOnT) > intOldOn
		cellText(end+1) = {['ON, ' cellTextOn{end}]}; %remove 'ON'
	end
	
	%get offsets
	intOldOff = numel(vecDiodeOffT);
	vecOffsets = vecUseTimestampsNI(vecSignChange == -1);
	[vecDiodeOffT,cellTextOff] = SC_getStimT(vecDiodeOffT,vecOldStimOffT,vecOffsets,[],dblMaxErrorT);
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
	%get current scan number for IM streams
	intCurCountIM = GetScanCount(sStream.hSGL, intStreamIM);
	
	%check if this is the initial fetch
	if intLastFetchIM == 0 || (intLastFetchIM < (intCurCountIM - intMaxFetchIM))
		intRetrieveSamplesIM = round(1*dblSampFreqIM); %retrieve last 0.1 seconds
		intRetrieveSamplesIM = min(intCurCountIM-1,intRetrieveSamplesIM); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountIM - intRetrieveSamplesIM; %set last fetch to starting position
	else
		intStartFetch = intLastFetchIM;% - round(dblSampFreqIM);
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
			%fprintf('Last Fetch=%d, CurCount=%d, Start=%d, End=%d, Samp#=%d; retrieved=[%d x %d], start at %d [%s]\n',...
			%	intLastFetchIM,intCurCountIM,intStartFetch,intStartFetch+intRetrieveSamplesIM,intRetrieveSamplesIM,size(matNewData,1),size(matNewData,2),intStartCountIM,getTime);
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
	dblUseOverlapT = 0.1;
	if sStream.dblSubLastUpdate > dblUseOverlapT %if last subsample update is more than 1 second ago
		%reset counter
		sStream.dblSubLastUpdate = 0;
		
		%unroll buffer
		[vecLinBuffT,vecReorderData] = sort(sStream.vecTimestampsIM,'ascend');
		vecLinBuffT = vecLinBuffT/dblSampFreqIM;
		matLinBuffData = sStream.matDataBufferIM(vecReorderData,:); %time by channel
		
		%retrieve which data to use, subsample & assign
		dblCurrT = sStream.dblCurrT; %last update
		if isempty(dblCurrT)
			dblCurrT = max(vecLinBuffT) - 5;
			sStream.dblCurrT = dblCurrT;
		end
		indKeepIM = vecLinBuffT>(dblCurrT - dblUseOverlapT);
		matSubNewData = matLinBuffData(indKeepIM,:)';
		vecSubNewTime = vecLinBuffT(indKeepIM);
		
		%message
		cellText = {'',sprintf('Processing %.3fs of new SGL data [%.3fs - %.3fs] ...',max(vecSubNewTime)-min(vecSubNewTime)-dblUseOverlapT,min(vecSubNewTime)+dblUseOverlapT,max(vecSubNewTime))};
		feval(f_updateTextInformation,cellText);
		
		%% detect spikes
		%detect spikes on all channels
		[gVecSubNewSpikeCh,gVecSubNewSpikeT,dblSubNewTotT] = DP_DetectSpikes(matSubNewData, sP);
		vecSubNewSpikeCh = gather(gVecSubNewSpikeCh);
		vecSubNewSpikeT = gather(gVecSubNewSpikeT);
		strClassCh = class(vecSubNewSpikeCh);
		strClassT = class(vecSubNewSpikeT);
		
		%remove spikes in overlap
		indRemSp = vecSubNewSpikeT < cast(dblUseOverlapT*1000-1,strClassT);
		vecSubNewSpikeT(indRemSp) = [];
		vecSubNewSpikeCh(indRemSp) = [];
		%clear gpuArrays
		gVecSubNewSpikeT = [];
		gVecSubNewSpikeCh = [];
		
		% assign data
		intStartT = cast(vecSubNewTime(1)*1000,strClassT);
		sStream.dblCurrT = vecSubNewTime(end);
		if numel(vecSubNewSpikeCh) > 0
			sStream.vecSubSpikeCh = cat(1,sStream.vecSubSpikeCh,vecSubNewSpikeCh(:));
			sStream.vecSubSpikeT = cat(1,sStream.vecSubSpikeT,vecSubNewSpikeT(:) + intStartT); %in ms
		end
		
		%msg
		feval(f_updateTextInformation,sprintf('  %d new spikes.',numel(vecSubNewSpikeCh)));
		boolDidSomething = true;
	end
end

