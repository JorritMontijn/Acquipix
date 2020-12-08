function RunExperiment
% RunExperiment Run Neuropixel Acquisition session
	
	%define globals
	global sFigRE;
	global sRE;
	
	%check if instance is already running
	if isstruct(sFigRE) && isfield(sFigRE,'IsRunning') && sFigRE.IsRunning == 1
		error([mfilename ':SingularGUI'],'RunExperiment instance is already running; only one simultaneous GUI is allowed');
	end
	
	%clear data & disable new instance
	sFigRE = struct;
	sRE = struct;
	sFigRE.IsRunning = true;
	
	%generate gui
	[sFigRE,sRE] = RE_genGUI(sFigRE,sRE);
	
end


