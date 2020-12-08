function RE_DeleteFcn()
	%UNTITLED2 Summary of this function goes here
	%   Detailed explanation goes here
	
	%% globals
	global sFigRE;
	global sRE;
	
	%% confirm exit
	disp bye!
	
	%% enable new gui
	sFigRE.IsRunning = false;
	
end