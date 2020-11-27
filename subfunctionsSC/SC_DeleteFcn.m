%% closing function
function SC_DeleteFcn(varargin)
	%get globals
	global sFig
	
	%stop timer
	stop(sFig.objMainTimer);
end