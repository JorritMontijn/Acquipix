function [vecRefinedStimT,vecDiffT] = SC_refineDiffT(vecReferenceT,vecNoisyHighResT,dblMaxErrorT)
	%OT_refineT As OT_getStimT, but no text. Refines event times
	%	[vecRefinedStimT,vecDiffT,indRefined] = OT_refineT(vecReferenceT,vecNoisyHighResT,dblMaxErrorT)
	%
	%vecReferenceT is the default: these times are known to be correct, but inaccurate
	%vecNoisyHighResT is more precise, but may miss some signal changes or include spurious events
	%dblMaxErrorT: ignores vecNoisyHighResT entries and returns vecReferenceT(i) if none are within this window around vecReferenceT(i) 
	
	%check inputs
	if ~exist('dblMaxErrorT','var') || isempty(dblMaxErrorT)
		dblMaxErrorT = inf;
	end
	
	%run loop from the last vecPresStimT entry that was less than dblMaxErrorT
	%seconds before the first vecSignalChangeT
	intEvents = numel(vecReferenceT);
	vecReferenceDeltaT = diff(vecReferenceT);
	vecRefinedStimT = nan(size(vecReferenceT));
	vecRefinedStimT(1) = vecReferenceT(1);
	%run
	for intEvent=2:intEvents
		%get presentation time
		dblRefDeltaT = vecReferenceDeltaT(intEvent-1);
		
		%find closest change
		dblPresTime = vecRefinedStimT(intEvent-1);
		vecOnsetDiffs = vecNoisyHighResT - dblPresTime - dblRefDeltaT;
		[dummy,intMinIdx]= min(abs(vecOnsetDiffs));
		dblMinT = vecOnsetDiffs(intMinIdx);
		if isempty(dblMinT)
			break;
		else
			%overwrite
			vecRefinedStimT(intEvent) = vecNoisyHighResT(intMinIdx);
		end
	end
	%interval
	vecRefinedDeltaT = diff(vecRefinedStimT);
	
	%difference
	vecDiffT = vecRefinedDeltaT - vecReferenceDeltaT;
end