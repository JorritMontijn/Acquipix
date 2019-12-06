function [boolArray,dblCritVal] = DP_GetUpDown(vecData,dblLowerPercentile,dblUpperPercentile)
	%DP_GetUpDown Calculates whether signal is high or low
	%	[boolArray,dblCritVal] = DP_GetUpDown(vecData,dblLowerPercentile,dblUpperPercentile)
	%
	%Critical value is upper-inclusive and defined as the midpoint between
	%(by default) the 10th and 90th percentile 
	
	%default percentiles
	if ~exist('dblPercentile','var') || isempty(dblLowerPercentile)
		dblLowerPercentile = 0.1;
	end
	if ~exist('dblPercentile','var') || isempty(dblUpperPercentile)
		dblUpperPercentile = 1-dblLowerPercentile;
	end
	
	%get critical value as midpoint between 10th and 90th percentile
	vecSorted = sort(vecData,'ascend');
	intPoints = numel(vecData);
	dblLower = vecSorted(round(intPoints*dblLowerPercentile));
	dblUpper = vecSorted(round(intPoints*dblUpperPercentile));
	dblCritVal = (dblUpper - dblLower)/2 + dblLower;
	boolArray = vecData >= dblCritVal;
end