function sMetaVar = RP_defaultMetaVar()
	%% default settings
	sMetaVar = struct;
	sMetaVar.version = '1.0';
	sMetaVar.dataset = 'Default_data'; %Neuropixels_data
	sMetaVar.investigator = 'NomenNescio'; %Jorrit_Montijn
	sMetaVar.project = 'DefaultProject'; %MontijnNPX2020
	sMetaVar.setup = 'WindowlessBroomCloset';%Neuropixels
	sMetaVar.stimulus = 'VisStimAcquipix';
	sMetaVar.condition = 'none';
	sMetaVar.subjecttype = 'undefined'; %BL6
	sMetaVar.niCh0 = 'sync'; %pulse sync channel 
	sMetaVar.niCh1 = 'onset'; %screen diode channel
	sMetaVar.niCh2 = '@PP_GetRunSpeed'; %misc channel; e.g., @PP_GetRunSpeed
end