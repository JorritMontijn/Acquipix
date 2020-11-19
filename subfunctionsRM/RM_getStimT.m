function [vecRefinedStimT,cellText,vecDiffT] = RM_getStimT(vecRefinedStimT,vecPresStimT,vecSignalChangeT,cellText,dblMaxErrorT)
	%RM_getStimT Refines presentation times by diode signal changes
	%	[vecRefinedStimT,cellText,vecDiffT] = RM_getStimT(vecRefinedStimT,vecPresStimT,vecSignalChangeT,cellText,dblMaxErrorT)
	%
	%vecPresStimT is the default: these times are known to be correct within at least ~100ms
	%vecSignalChangeT is more precise, but may miss some signal changes
	
	%check inputs
	if ~exist('cellText','var') || isempty(cellText)
		cellText = {};
	end
	if ~exist('dblMaxErrorT','var') || isempty(dblMaxErrorT)
		dblMaxErrorT = 0.1;
	end
	
	%run loop from the last vecPresStimT entry that was less than dblMaxErrorT
	%seconds before the first vecSignalChangeT
	intStartStim = find((vecPresStimT - min(vecSignalChangeT) + dblMaxErrorT) > 0,1);
	intMinStim = min([numel(vecRefinedStimT) numel(vecPresStimT)]);
	vecDiffT = vecPresStimT(1:intMinStim) - vecRefinedStimT(1:intMinStim);
	if isempty(intStartStim);return;end
	%pre-allocate
	vecRefinedStimT((end+1):numel(vecPresStimT)) = nan;
	vecDiffT((end+1):numel(vecPresStimT)) = nan;
	intTextEntry = numel(cellText)+1;
	vecAssignEntries = intTextEntry:(intTextEntry+numel(vecPresStimT)-intStartStim);
	cellText(intTextEntry:(intTextEntry+numel(vecPresStimT)-intStartStim)) = cell(size(vecAssignEntries));
	%run
	for intStim=intStartStim:numel(vecPresStimT)
		%get presentation time
		dblPresTime = vecPresStimT(intStim);
		
		%find closest change
		vecOnsetDiffs = dblPresTime - vecSignalChangeT;
		[dummy,intMinIdx]= min(abs(vecOnsetDiffs));
		dblMinT = vecOnsetDiffs(intMinIdx);
		if isempty(dblMinT)
			break;
		elseif abs(dblMinT) < dblMaxErrorT
			%msg
			cellText(intTextEntry) = {sprintf('PD time for stim %d: %.3fs (mismatch: %.3fs)',intStim,vecPresStimT(intStim),dblMinT)};
			intTextEntry = intTextEntry + 1;
			%overwrite
			vecRefinedStimT(intStim) = vecSignalChangeT(intMinIdx);
			vecDiffT(intStim) = dblMinT;
			
		else
			%msg
			cellText(intTextEntry) = {sprintf('<< WARNING >> PD time for stim %d at %.3fs has mismatch %.3fs!',intStim,vecPresStimT(intStim),dblMinT)};
			intTextEntry = intTextEntry + 1;
			%use stim object data instead
			dblMedianDiff = nanmean(vecDiffT);
			if isempty(dblMedianDiff) || isnan(dblMedianDiff),dblMedianDiff=0;end
			vecRefinedStimT(intStim) = vecPresStimT(intStim) - dblMedianDiff;
			vecDiffT(intStim) = dblMedianDiff;
		end
	end
	%remove excess entries
	cellText(intTextEntry:end) = [];
end