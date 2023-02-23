function intSyncPulseCh = PP_FindSyncPulseCh(matDataNI,intUseSamples)
	%PP_FindSyncPulseCh Finds most likely sync pulse channel (most bimodal values)
	%	 intSyncPulseCh = PP_FindSyncPulseCh(matDataNI,intUseSamples);
	
	%check orientation
	[intNumCh,intNumSamples] = size(matDataNI);
	if intNumCh > intNumSamples
		warning([mfilename ':OrientationCheck'],'Input data has more channels than samples. Are you sure this is the right matrix orientation?');
	end
	if ~exist('intUseSamples','var') || isempty(intUseSamples) || (intUseSamples < 10 || ~(intUseSamples > 3))
		intUseSamples = 1e6;
	end
	
	%select data subset
	intUseSamples = min(intNumSamples,intUseSamples);
	matUseData = matDataNI(:,1:intUseSamples);
	vecBimodalityCoefficient = nan(1,intNumCh);
	
	for intCh=1:intNumCh
		vecData = double(matUseData(intCh,:));
		intN = numel(vecData);
		%Sarle's bimodality coefficient b (https://en.wikipedia.org/wiki/Multimodal_distribution):
		dblSkewness = skewness(vecData, 0);
		dblExcessKurtosis = kurtosis(vecData, 0) - 3;
		vecBimodalityCoefficient(intCh) = (dblSkewness.^2 + 1) ./ (dblExcessKurtosis + 3*(intN-1)^2/(intN-2)/(intN-3));
	end
	[dummy,intSyncPulseCh] = max(vecBimodalityCoefficient);
end
