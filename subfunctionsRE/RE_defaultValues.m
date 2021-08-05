function sRE = RE_defaultValues()
	%define defaults
	[intPresetsCreated,cellExperiments] = assertPresets();
	sRE.cellStimSets = cellExperiments;
	sRE.strHostAddress = '192.87.10.238'; %default host address
	sRE.intUseDaqDevice = 1; %default host address
	sRE.dblPupilLightMultiplier = 1;
	sRE.dblSyncLightMultiplier = 0.5;

end