function [vecDiodeT,cellText] = OT_getStimT(vecDiodeT,vecOldStimT,vecSignalChangeT,cellText,sOT,dblMaxErrorT)
	%onsets or offsets
	vecDiffT = nan(1,numel(vecOldStimT));
	for intOnset=1:numel(vecSignalChangeT)
		%find closest change
		vecOnsetDiffs = vecOldStimT - vecSignalChangeT(intOnset);
		[dummy,intMinIdx]= min(abs(vecOnsetDiffs));
		dblMinT = vecOnsetDiffs(intMinIdx);
		if isempty(dblMinT)
			break;
		elseif abs(dblMinT) < dblMaxErrorT
			vecDiodeT(intMinIdx) = vecSignalChangeT(intOnset);
			vecDiffT(intMinIdx) = dblMinT;
			if intMinIdx > sOT.intEphysTrialN
				cellText(end+1) = {sprintf('PD time for stim %d: %.3fs (mismatch: %.3fs)',intMinIdx,vecSignalChangeT(intOnset),dblMinT)};
			end
		elseif intMinIdx > 1 && (numel(vecDiodeT) < intMinIdx || abs(dblMinT) < abs(vecOldStimT(intMinIdx) - vecDiodeT(intMinIdx)))
			cellText(end+1:end+2) = {'<< WARNING >>',sprintf('PD time at %.3fs has mismatch %.3fs!',vecSignalChangeT(intOnset),dblMinT)};
			%use stim object data instead
			dblMedianDiff = nanmean(vecDiffT);
			if isnan(dblMedianDiff),dblMedianDiff=0;end
			vecDiodeT(intMinIdx) = vecOldStimT(intMinIdx) - dblMedianDiff;
			vecDiffT(intMinIdx) = dblMedianDiff;
		end
	end
end