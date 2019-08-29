function sRM = RM_populateStructure(sRM)
	%RM_populateStructure Sets default values for RF mapper
	
	%check metadata
	if ~isfield(sRM,'metaData')
		sRM.metaData = struct;
	end
	%default path locations
	sRM.metaData.strSourcePathTDT = 'E:\';
	sRM.metaData.strSourcePathLog = 'X:\JorritMontijn\TempObjects\';
	
	%filters
	sRM.metaData.cellFilter{1} = 'Smoothed ON+OFF Stim-Base';
	sRM.metaData.cellFilter{2} = 'Smoothed ON+OFF Stim-Base/Sd';
	sRM.metaData.cellFilter{3} = 'Smoothed ON Stim/Sd + OFF Stim/Sd';
	sRM.metaData.cellFilter{4} = 'ON+OFF Stim-Base';
	sRM.metaData.cellFilter{5} = 'ON+OFF Stim-Base/Sd';
	sRM.metaData.cellFilter{6} = 'ON Stim/Sd + OFF Stim/Sd';
	
	%default values
	sRM.metaData.dblSubSampleToReq = 0.011;
	sRM.metaData.dblFiltFreq = 500;
	
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
end