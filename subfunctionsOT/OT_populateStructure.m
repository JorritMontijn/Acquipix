function sOT = OT_populateStructure(sOT)
	%OT_populateStructure Sets default values for RF mapper
	
	%check metadata
	if ~isfield(sOT,'metaData')
		sOT.metaData = struct;
	end
	%default path locations
	sOT.metaData.strHostAddressSGL = '127.0.0.1';
	sOT.metaData.strSourcePathLog = 'X:\JorritMontijn\TempObjects\';
	
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
	
	%initialize data stream variables
	sOT.IsInitialized = false;
	%ephys
	sOT.NumChannels = 0;
	sOT.dblSampFreqIM = 0;
	sOT.dblSampFreqNI = 0;
	sOT.dblEphysTimeIM = 0;
	sOT.dblEphysTimeNI = 0;
	sOT.intEphysTrialN = 0;
	sOT.dblEphysTrialT = 0;
	sOT.intLastFetchNI = 0;
	sOT.intLastFetchIM = 0;
	%data
	sOT.vecTimestampsNI = [];
	sOT.vecSyncData = [];
	sOT.vecTimestampsIM = [];
	sOT.matData = [];

	%stim
	sOT.dblStimCoverage = 0;
	sOT.intStimTrialN = 0;
	sOT.dblStimTrialT = 0;
	sOT.sStimObject = [];
	sOT.vecStimOnT = [];
	sOT.vecStimOffT = [];
	
end