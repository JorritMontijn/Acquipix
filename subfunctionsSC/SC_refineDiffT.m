function [vecRefinedT,vecIntervalError] = SC_refineDiffT(vecReferenceT,vecUseSignalOnT)
	%OT_refineT As OT_getStimT, but no text. Refines event times
	%	[vecRefinedT,vecIntervalError] = SC_refineDiffT(vecReferenceT,vecUseSignalOnT)
	%
	%vecReferenceT is the default: these times are known to be correct, but inaccurate
	%vecUseSignalOnT is more precise, but may miss some signal changes or include spurious events
	
	%run loop from the last vecPresStimT entry that was less than dblMaxErrorT
	%seconds before the first vecSignalChangeT
	intEvents = numel(vecReferenceT);
	vecReferenceDeltaT = diff(vecReferenceT);
	vecRefinedT = nan(size(vecReferenceT));
	vecRefinedT(1) = vecReferenceT(1);
	%run
	for intEvent=2:intEvents
		%get presentation time
		dblRefDeltaT = vecReferenceDeltaT(intEvent-1);
		
		%find closest change
		dblPresTime = vecRefinedT(intEvent-1);
		vecOnsetDiffs = vecUseSignalOnT - dblPresTime - dblRefDeltaT;
		[dummy,intMinIdx]= min(abs(vecOnsetDiffs));
		dblMinT = vecOnsetDiffs(intMinIdx);
		if isempty(dblMinT)
			break;
		else
			%overwrite
			vecRefinedT(intEvent) = vecUseSignalOnT(intMinIdx);
		end
	end
	%interval
	vecRefinedDeltaT = diff(vecRefinedT);
	
	%difference
	vecIntervalError = vecRefinedDeltaT - vecReferenceDeltaT;
end