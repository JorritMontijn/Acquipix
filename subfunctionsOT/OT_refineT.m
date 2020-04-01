function [vecRefinedStimT,vecDiffT,indRefined] = OT_refineT(vecReferenceT,vecNoisyHighResT,dblMaxErrorT)
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
	vecRefinedStimT = vecReferenceT;
	indRefined = false(1,intEvents);
	%run
	for intEvent=1:intEvents
		%get presentation time
		dblPresTime = vecReferenceT(intEvent);
		
		%find closest change
		vecOnsetDiffs = dblPresTime - vecNoisyHighResT;
		[dummy,intMinIdx]= min(abs(vecOnsetDiffs));
		dblMinT = vecOnsetDiffs(intMinIdx);
		if isempty(dblMinT)
			break;
		elseif abs(dblMinT) < dblMaxErrorT
			%overwrite
			vecRefinedStimT(intEvent) = vecNoisyHighResT(intMinIdx);
			indRefined(intEvent) = true;
		end
	end
	%difference
	vecDiffT = vecRefinedStimT - vecReferenceT;
	vecDiffT(~indRefined) = nan;
end