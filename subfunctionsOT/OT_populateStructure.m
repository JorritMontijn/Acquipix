function sOT = OT_populateStructure(sOT)
	%OT_populateStructure Sets default values for RF mapper
	
	%check metadata
	if ~isfield(sOT,'metaData')
		sOT.metaData = struct;
	end
	
	%data processing types
	sOT.metaData.cellProcess{1} = 'Stimulus';
	sOT.metaData.cellProcess{2} = 'Baseline';
	sOT.metaData.cellProcess{3} = 'Stimulus - Baseline';
	
	%metrics
	sOT.metaData.cellMetric{1} = strcat('Information (',getGreek('delta','lower'),''')');
	sOT.metaData.cellMetric{2} = strcat('Curve smoothness (',getGreek('rho','lower'),')');
	sOT.metaData.cellMetric{3} = 'OPI (1 - circ_var)';
	sOT.metaData.cellMetric{4} = 'OSI (p - np / p + np)';
	sOT.metaData.cellMetric{5} = 'Asym Left-Right';
	sOT.metaData.cellMetric{6} = 'Asym Up-Down';
	sOT.metaData.cellMetric{7} = 'Asym Vert-Horz';
	
	%channel selection
	sOT.metaData.cellChannels{1} = 'Best';
	sOT.metaData.cellChannels{2} = 'Mean';
	sOT.metaData.cellChannels{3} = 'Single';
	
	%% shared core variables
	sOT = SC_populateStreamCoreStructure(sOT);
	
	%% specific parameters
	%stim stream
	sOT.dblStimCoverage = 0;
	sOT.intStimTrial = 0;
	sOT.sStimObject = [];
	sOT.vecTimestamps = [];
	sOT.matRespBase = [];
	sOT.matRespStim = [];
	sOT.vecStimTypes = [];
	sOT.vecStimOriDeg = [];
	
	%stim data
	sOT.intRespTrialN = 0;
	sOT.dblStimCoverage = 0;
	sOT.intStimTrialN = 0;
	sOT.dblStimTrialT = 0;
	sOT.sStimObject = [];
	sOT.vecStimOnT = [];
	sOT.vecStimOffT = [];
end