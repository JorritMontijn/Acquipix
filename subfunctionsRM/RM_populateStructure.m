function sRM = RM_populateStructure(sRM)
	%RM_populateStructure Sets default values for RF mapper
	
	%% metadata & figure defaults
	%check metadata
	if ~isfield(sRM,'metaData')
		sRM.metaData = struct;
	end
	%data processing types
	sRM.metaData.cellProcess{1} = 'Raw';
	sRM.metaData.cellProcess{2} = 'Smoothed';
	sRM.metaData.cellProcess{3} = 'Blurred';
	
	%metrics
 	sRM.metaData.cellMetric{1} = 'Mean';
 	
	%channel selection
	sRM.metaData.cellChannels{1} = 'Magic+';
	sRM.metaData.cellChannels{2} = 'Mean';
	sRM.metaData.cellChannels{3} = 'Best';
	sRM.metaData.cellChannels{4} = 'Single';
	
	%initialize data stream variables
	sRM.IsInitialized = false;
	
	%% common stream core variables
	sRM = SC_populateStreamCoreStructure(sRM);
	
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