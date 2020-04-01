function structEP = remStimAP(structEP,vecRemStims)
	%UNTITLED2 Summary of this function goes here
	%   Detailed explanation goes here
	
	if any(vecRemStims)
		cellFields = fieldnames(structEP);
		for intField=1:numel(cellFields)
			strField = cellFields{intField};
			if isnumeric(structEP.(strField)) && (numel(structEP.(strField)) == numel(vecRemStims))
				structEP.(strField)(vecRemStims) = [];
			end
		end
	end
end

