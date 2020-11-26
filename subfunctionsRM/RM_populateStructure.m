function sRM = RM_populateStructure(sRM)
	%RM_populateStructure Sets default values for RF mapper
	
	%% metadata & figure defaults
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
	sRM.metaData.cellProcess{3} = 'Blurred';
	
	%metrics
 	sRM.metaData.cellMetric{1} = 'Mean';
 	sRM.metaData.cellMetric{2} = 'ZETA (under construction)';

	%initialize data stream variables
	sRM.IsInitialized = false;
	
	%% common stream core variables
	sRM = populateStreamCoreStructure(sRM);
	
	%% specific parameters
	%stim stream
	sRM.dblStimCoverage = 0;
	sRM.intStimTrial = 0;
	sRM.sStimObject = [];
	sRM.vecTimestamps = [];
	sRM.matData = [];
	
	%stim data
	sRM.intRespTrialN = 0;
	sRM.dblStimCoverage = 0;
	sRM.intStimTrialN = 0;
	sRM.dblStimTrialT = 0;
	sRM.sStimObject = [];
	sRM.vecStimOnT = [];
	sRM.vecStimOffT = [];
end