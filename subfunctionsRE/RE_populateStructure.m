function sRE = RE_populateStructure(sRE)
	%UNTITLED4 Summary of this function goes here
	%   Detailed explanation goes here
	
	%% metadata & figure defaults
	%check metadata
	if ~isfield(sRE,'metaData')
		sRE.metaData = struct;
	end
	
	%experiment types
	sRE.metaData.cellStimSets = {'RunReceptiveFieldMapping','RunDriftingGratings','RunNaturalMovie','RunOptoStim'};
	
	%initialize variables
	sRE.IsInitialized = false;
end

