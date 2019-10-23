function boolIsMatch = isMatchStimObj(sStimObject1,sStimObject2)
	%isMatchStimObj Matches two stimulus objects and returns boolean
	%	 boolIsMatch = isMatchStimObj(sStimObject1,sStimObject2)
	
	%compare fields
	boolIsMatch = false;
	cellFields1 = fieldnames(sStimObject1);
	cellFields2 = fieldnames(sStimObject2);
	intFields = numel(cellFields1);
	if intFields == numel(cellFields2)
		indMatchingFields = false(1,numel(cellFields2));
		for intField=1:intFields
			strField = cellFields2{intField};
			if isfield(sStimObject1,strField)
				if isnumeric(sStimObject1.(strField))
					if isempty(sStimObject2.(strField)) && isempty(sStimObject1.(strField))
						indMatchingFields(intField) = true;
					elseif isnan(sStimObject2.(strField)) && isnan(sStimObject1.(strField))
						indMatchingFields(intField) = true;
					elseif sStimObject2.(strField) == sStimObject1.(strField)
						indMatchingFields(intField) = true;
					end
				elseif islogical(sStimObject1.(strField))
					if isempty(sStimObject2.(strField)) && isempty(sStimObject1.(strField))
						indMatchingFields(intField) = true;
					elseif sStimObject2.(strField) == sStimObject1.(strField)
						indMatchingFields(intField) = true;
					end
				elseif ischar(sStimObject1.(strField))
					if strcmp(sStimObject2.(strField),sStimObject1.(strField))
						indMatchingFields(intField) = true;
					end
				else
					error([mfilename ':IncorrectFieldType'],sprintf('Field %s not recognized',strField));
				end
			end
		end
		
		%check if all fields match
		if all(indMatchingFields)
			boolIsMatch = true;
			return;
		end
	end
end