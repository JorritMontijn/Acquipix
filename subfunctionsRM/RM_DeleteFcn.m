%% closing function
function RM_DeleteFcn(varargin)
	%get globals
	global sFig
	
	%stop timer
	stop(sFig.objTimer);
end