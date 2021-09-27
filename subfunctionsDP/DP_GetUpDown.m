function [boolArray,dblCritVal] = DP_GetUpDown(vecData,dblLowerPercentile,dblUpperPercentile)
	%DP_GetUpDown Calculates whether signal is high or low
	%	[boolArray,dblCritVal] = DP_GetUpDown(vecData,dblLowerPercentile,dblUpperPercentile)
	%
	%Critical value is upper-inclusive and defined as the midpoint between
	%(by default) the 1st and 99th percentile 
	
	%default percentiles
	if ~exist('dblLowerPercentile','var') || isempty(dblLowerPercentile)
		dblLowerPercentile = 0.01;
	end
	if ~exist('dblUpperPercentile','var') || isempty(dblUpperPercentile)
		dblUpperPercentile = 1-dblLowerPercentile;
	end
	
	%get critical value as midpoint between 10th and 90th percentile
	vecSorted = sort(vecData,'ascend');
	vecSorted(isnan(vecSorted)) = [];
	if isempty(vecSorted)
		dblCritVal = nan;
		boolArray = true(size(vecData));
		return;
	end
	intPoints = numel(vecSorted);
	dblLower = vecSorted(ceil(intPoints*dblLowerPercentile));
	dblUpper = vecSorted(ceil(intPoints*dblUpperPercentile));
	dblCritVal = (dblUpper - dblLower)/2 + dblLower;
	boolArray = vecData >= dblCritVal;
end