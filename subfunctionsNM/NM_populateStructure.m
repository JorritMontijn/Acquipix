function sNM = NM_populateStructure(sNM)
	%NM_populateStructure Sets default values for NM mapper
	
	%% metadata & figure defaults
	%check metadata
	if ~isfield(sNM,'metaData')
		sNM.metaData = struct;
	end
	%data processing types
	sNM.metaData.cellProcess{1} = '100-ms bins';
	
	%metrics
	sNM.metaData.cellMetric{1} = 'ANOVA';
	sNM.metaData.cellMetric{2} = strcat('Information (',getGreek('delta','lower'),''')');
	
	%channel selection
	sNM.metaData.cellChannels{1} = 'Best';
	sNM.metaData.cellChannels{2} = 'Mean';
	sNM.metaData.cellChannels{3} = 'Single';
	
	%initialize data stream variables
	sNM.IsInitialized = false;
	
	%% common stream core variables
	sNM = SC_populateStreamCoreStructure(sNM);
	
	%% specific parameters
	%stim stream
	sNM.dblStimCoverage = 0;
	sNM.intStimTrial = 0;
	sNM.sStimObject = [];
	sNM.vecTimestamps = [];
	sNM.matRespNM = [];
	
	%stim data
	sNM.intRespTrialN = 0;
	sNM.dblStimCoverage = 0;
	sNM.intStimTrialN = 0;
	sNM.dblStimTrialT = 0;
	sNM.sStimObject = [];
	sNM.vecStimOnT = [];
	sNM.vecStimOffT = [];
end