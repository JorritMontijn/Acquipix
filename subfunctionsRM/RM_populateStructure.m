function sRM = RM_populateStructure(sRM)
	%RM_populateStructure Sets default values for RF mapper
	
	%check metadata
	if ~isfield(sRM,'metaData')
		sRM.metaData = struct;
	end
	%default path locations
	sRM.metaData.strHostAddressSGL = '127.0.0.1';
	sRM.metaData.strSourcePathLog = 'X:\JorritMontijn\TempObjects\';
	sRM.metaData.strChanMapPath = 'C:\Code\GitRepos\Acquipix\subfunctionsPP\';
	sRM.metaData.strChanMapFile = 'neuropixPhase3B2_kilosortChanMap.mat';
	
	%data processing types
	sRM.metaData.cellProcess{1} = 'Raw';
	sRM.metaData.cellProcess{2} = 'Smoothed';
	
	%metrics
 	sRM.metaData.cellMetric{1} = 'Mean';
 	sRM.metaData.cellMetric{2} = 'ZETA (under construction)';

	%initialize data stream variables
	sRM.IsInitialized = false;
	
	%filters
	%sRM.metaData.cellFilter{1} = 'Smoothed ON+OFF Stim-Base';
	%sRM.metaData.cellFilter{2} = 'Smoothed ON+OFF Stim-Base/Sd';
	%sRM.metaData.cellFilter{3} = 'Smoothed ON Stim/Sd + OFF Stim/Sd';
	%sRM.metaData.cellFilter{4} = 'ON+OFF Stim-Base';
	%sRM.metaData.cellFilter{5} = 'ON+OFF Stim-Base/Sd';
	%sRM.metaData.cellFilter{6} = 'ON Stim/Sd + OFF Stim/Sd';
	
	%ephys
	sRM.intStimSyncChanNI = 0;
	sRM.NumChannels = 0;
	sRM.dblSampFreqIM = 0;
	sRM.dblSampFreqNI = 0;
	sRM.dblEphysTimeIM = 0;
	sRM.dblEphysTimeNI = 0;
	sRM.intEphysTrialN = 0;
	sRM.dblEphysTrialT = 0;
	sRM.intLastFetchNI = 0;
	sRM.intLastFetchIM = 0;
	sRM.vecDiodeOnT = [];
	sRM.vecDiodeOffT = [];
	
	%data
	sRM.boolChannelsCulled = false;
	sRM.vecTimestampsNI = [];
	sRM.vecSyncData = [];
	sRM.dblDataBufferSize = 3;
	sRM.intDataBufferPos = [];
	sRM.intDataBufferSize = [];
	sRM.matDataBufferIM = [];
	sRM.vecTimestampsIM = [];
	sRM.dblSubLastUpdate = [];
	sRM.dblCurrT = [];
	sRM.vecSubSpikeCh = [];
	sRM.vecSubSpikeT = [];
		
	%initialize data stream variables
	sRM.IsInitialized = false;
	sRM.NumChannels = 0;
	sRM.dblSampFreq = 0;
	sRM.dblEphysTime = 0;
	sRM.intEphysTrial = 0;
	sRM.dblStimCoverage = 0;
	sRM.intStimTrial = 0;
	sRM.sStimObject = [];
	sRM.vecTimestamps = [];
	sRM.matData = [];
	
	%stim
	sRM.dblStimCoverage = 0;
	sRM.intStimTrialN = 0;
	sRM.dblStimTrialT = 0;
	sRM.sStimObject = [];
	sRM.vecStimOnT = [];
	sRM.vecStimOffT = [];
	
	%ephys selection
	sRM.intRespTrialN = 0;
	sRM.intMinChan = 1;
	sRM.intMaxChan = 384;
	sRM.vecAllChans = (sRM.intMinChan:(sRM.intMaxChan*2 + 1))-1; %AP, LFP, NI; 0-start
	sRM.vecSpkChans = (sRM.intMinChan:sRM.intMaxChan)-1; %AP; 0-start
	sRM.vecIncChans = (sRM.intMinChan:sRM.intMaxChan)-1; %AP, minus culled; 0-start
	sRM.vecSelectChans = (sRM.intMinChan:sRM.intMaxChan); %AP, selected chans; 1-start
	sRM.vecActChans = sRM.vecIncChans(ismember(sRM.vecIncChans,sRM.vecSelectChans)); %AP, active channels (selected and unculled); 0-start
	
end