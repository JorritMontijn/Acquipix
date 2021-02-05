function RE_DeleteFcn()
	%RE_DeleteFcn Ensures new GUI can start
	
	%% globals
	global sFigRE;
	
	%% enable new gui
	sFigRE.IsRunning = false;
	
end