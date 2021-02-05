function [sFig,sRE] = RE_initialize(sFig,sRE)
	%SC_initialize initializes all fields when data paths are set
	
	%lock GUI
	SC_lock(sFig);
		
	%data processing
	set(sFig.ptrListSelectStimulusSet,'String',sRE.metaData.cellStimSets);
	
	%enable all fields
	SC_enable(sFig);
	
	%set msg
	sRE.IsInitialized = true;
	sRE.IsInputConfirmed = false;
end

