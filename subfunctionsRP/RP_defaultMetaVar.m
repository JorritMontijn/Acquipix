function sMetaVar = RP_defaultMetaVar()
	%% default settings
	sMetaVar = struct;
	sMetaVar.version = '1.0';
	sMetaVar.dataset = 'Neuropixels_data';
	sMetaVar.investigator = 'Jorrit_Montijn';
	sMetaVar.project = 'MontijnNPX2020';
	sMetaVar.setup = 'Neuropixels';
	sMetaVar.stimulus = 'VisStimAcquipix';
	sMetaVar.condition = 'none';
	sMetaVar.subjecttype = 'BL6';
	sMetaVar.niCh0 = 'sync'; %pulse sync channel 
	sMetaVar.niCh1 = 'onset'; %screen diode channel
	sMetaVar.niCh2 = '@PP_GetRunSpeed'; %misc channel
	
end