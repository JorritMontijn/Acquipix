function sStream = SC_populateStreamCoreStructure(sStream)
	%SC_populateStreamCoreStructure Shared Core initialization of StreamCore parameters
	%   sStream = SC_populateStreamCoreStructure(sStream)
	%
	%Version 1.0 [2020-11-26]
	%	Split from RM_populateStructure to standardized module by Jorrit Montijn
	
	%default path locations
	sStream.metaData.strHostAddressSGL = '127.0.0.1';
	sStream.metaData.strSourcePathLog = 'X:\JorritMontijn\TempObjects\';
	sStream.metaData.strChanMapPath = 'C:\Code\GitRepos\Acquipix\subfunctionsPP\';
	sStream.metaData.strChanMapFile = 'neuropixPhase3B2_kilosortChanMap.mat';
	
	%metadata
	sStream.intStimSyncChanNI = 0;
	sStream.NumChannels = 0;
	sStream.dblSampFreqIM = 0;
	sStream.dblSampFreqNI = 0;
	sStream.dblEphysTimeIM = 0;
	sStream.dblEphysTimeNI = 0;
	sStream.intEphysTrialN = 0;
	sStream.dblEphysTrialT = 0;
	sStream.intLastFetchNI = 0;
	sStream.intLastFetchIM = 0;
	sStream.vecDiodeOnT = [];
	sStream.vecDiodeOffT = [];
	
	%data
	sStream.boolChannelsCulled = false;
	sStream.vecTimestampsNI = [];
	sStream.vecSyncData = [];
	sStream.dblDataBufferSize = 6; %IM data buffer length in seconds
	sStream.intDataBufferPos = [];
	sStream.intDataBufferSize = [];
	sStream.matDataBufferIM = [];
	sStream.vecTimestampsIM = [];
	sStream.dblSubLastUpdate = [];
	sStream.dblCurrT = [];
	sStream.vecSubSpikeCh = [];
	sStream.vecSubSpikeT = [];
		
	%initialize data stream variables
	sStream.IsInitialized = false;
	sStream.NumChannels = 0;
	sStream.dblSampFreq = 0;
	sStream.dblEphysTime = 0;
	sStream.intEphysTrial = 0;
	
	%ephys selection
	sStream.intMinChan = 1;
	sStream.intMaxChan = 384;
	sStream.vecAllChans = (sStream.intMinChan:(sStream.intMaxChan*2 + 1))-1; %AP, LFP, NI; 0-start
	sStream.vecSpkChans = (sStream.intMinChan:sStream.intMaxChan)-1; %AP; 0-start
	sStream.vecIncChans = (sStream.intMinChan:sStream.intMaxChan)-1; %AP, minus culled; 0-start
	sStream.vecSelectChans = (sStream.intMinChan:sStream.intMaxChan); %AP, selected chans; 1-start
	sStream.vecActChans = sStream.vecIncChans(ismember(sStream.vecIncChans,sStream.vecSelectChans)); %AP, active channels (selected and unculled); 0-start
end