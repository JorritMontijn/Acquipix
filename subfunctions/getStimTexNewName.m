function strFilename = getStimTexNewName(sStimObject,cellTexDB)
	%getStimTexNewName Generates new name for texture file
	%	strFilename = getStimTexNewName(sStimObject,cellTexDB)
	
	%get previous names
	if isempty(cellTexDB)
		cellTakenNames = {};
		intNewFile = 1;
	else
		cellTakenNames = cellTexDB(:,1);
		intNewFile = size(cellTexDB,1) + 1;
	end
	
	%generate name
	strFilename = strcat(sStimObject.StimType,'Tex',num2str(intNewFile));
	cellFields = fieldnames(sStimObject);
	for intField=1:numel(cellFields)
		strField = cellFields{intField};
		if ~strcmpi(strField,'StimType')
			try
				strVal = num2str(sStimObject.(strField));
				if ischar(strVal) && numel(strVal) < 5
					strFilename = strcat(strFilename,strField(1),strVal);
				end
			catch
			end
		end
	end
	%check if it exists
	while ismember(strFilename,cellTakenNames)
		%append random string
		strFilename = strcat(strFilename,char(64+randi(26)));
	end
end
