function matStimTypeCombos = buildStimCombos(cellParamTypes)
	%builds combination matrix from cell arrays of stimulus parameters.
	%Cell array order for simulations is:
	%cellParamTypes{1} = 'Ori';
	%cellParamTypes{2} = 'SF';
	%cellParamTypes{3} = 'TF';
	%cellParamTypes{4} = 'Contrast';
	%cellParamTypes{5} = 'Luminance';
	
	cellParamTypes = cellfun(@unique,cellParamTypes,'UniformOutput',false);
	intParamTypes = numel(cellParamTypes);
	vecParamNum = cellfun(@numel,cellParamTypes);
	intTypeCombos = prod(vecParamNum);
	matStimTypeCombos = nan(intParamTypes,intTypeCombos);
	vecRepNum = cumprod([1; vecParamNum(:)]);
	for intType=1:intParamTypes
		intParamNum = vecParamNum(intType);
		intRep = vecRepNum(intType);
		vecParamTypes = cellParamTypes{intType};
		intStartCounter = 1;
		for intC=1:(intTypeCombos/(intRep*intParamNum))
			for intParamType=1:intParamNum
				matStimTypeCombos(intType,intStartCounter:(intStartCounter+intRep-1)) = vecParamTypes(intParamType)*ones(1,intRep);
				intStartCounter = intStartCounter + intRep;
			end
		end
	end
end
