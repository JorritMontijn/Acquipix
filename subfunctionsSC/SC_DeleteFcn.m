%% closing function
function SC_DeleteFcn(varargin)
	%get globals
	global sFig
	
	%stop timers
	stop(sFig.objMainTimer);
	stop(sFig.objDrawTimer);
end