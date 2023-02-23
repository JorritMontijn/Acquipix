function dblSampRate = PP_GetPulseIntervalFromBinVec(binVec)
	%PP_GetRateFromBinVec Calculates pulse interval from binary vector
	%	dblSampRate = PP_GetPulseIntervalFromBinVec(binVec)
	
	vecChangePulses = diff(binVec);
	vecSyncPulseOn = (find(vecChangePulses == 1)+1);
	vecDiffPulses = sort(diff(vecSyncPulseOn));
	indUsePulsePeriods = abs(vecDiffPulses-mean(vecDiffPulses))<2 | abs(zscore(vecDiffPulses)) < 2;
	indUsePulsePeriods([1 end]) = false;
	dblSampRate = mean(vecDiffPulses(indUsePulsePeriods));
end
