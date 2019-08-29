%% closing function
function OT_DeleteFcn(varargin)
	%get globals
	global sFig
	
	%stop timer
	stop(sFig.objTimer);
end