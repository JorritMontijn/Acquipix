function sMetaVar = RP_defaultMetaVar()
	%% default settings
	sMetaVar = struct;
	sMetaVar.syncCh = '1'; %screen diode channel
	sMetaVar.version = '1.0';
	sMetaVar.dataset = 'Neuropixels_data';
	sMetaVar.investigator = 'Jorrit_Montijn';
	sMetaVar.project = 'MontijnNPX2020';
	sMetaVar.setup = 'Neuropixels';
	sMetaVar.stimulus = 'VisStimAcquipix';
	sMetaVar.condition = 'none';
	sMetaVar.subjecttype = 'BL6';
	
end