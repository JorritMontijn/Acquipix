function sOT = OT_populateStructure(sOT)
	%OT_populateStructure Sets default values for RF mapper
	
	%check metadata
	if ~isfield(sOT,'metaData')
		sOT.metaData = struct;
	end
	%default path locations
	sOT.metaData.strSourcePathTDT = 'E:\';
	sOT.metaData.strSourcePathLog = 'X:\JorritMontijn\TempObjects\';
	
	%data processing types
	sOT.metaData.cellProcess{1} = 'Stimulus';
	sOT.metaData.cellProcess{2} = 'Baseline';
	sOT.metaData.cellProcess{3} = 'Stimulus - Baseline';
	
	%metrics
	sOT.metaData.cellMetric{1} = strcat('Information (',getGreek(4,'lower'),''')');
	sOT.metaData.cellMetric{2} =  strcat('Curve smoothness (',getGreek(17,'lower'),')');
	sOT.metaData.cellMetric{3} = 'OPI (1 - circ_var)';
	sOT.metaData.cellMetric{4} = 'OSI (p - np / p + np)';
	sOT.metaData.cellMetric{5} = 'Asym Left-Right';
	sOT.metaData.cellMetric{6} = 'Asym Up-Down';
	sOT.metaData.cellMetric{7} = 'Asym Vert-Horz';
	
	%default values
	sOT.metaData.dblSubSampleToReq = 0.011;
	sOT.metaData.dblFiltFreq = 500;
	
	%initialize data stream variables
	sOT.IsInitialized = false;
	sOT.NumChannels = 0;
	sOT.dblSampFreq = 0;
	sOT.dblEphysTime = 0;
	sOT.intEphysTrial = 0;
	sOT.dblStimCoverage = 0;
	sOT.intStimTrial = 0;
	sOT.sStimObject = [];
	sOT.vecTimestamps = [];
	sOT.matData = [];
end