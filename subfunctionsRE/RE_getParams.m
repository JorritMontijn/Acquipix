function [cellProps,cellVals,cellComments] = RE_getParams(strTargetFile)
	%UNTITLED2 Summary of this function goes here
	%   Detailed explanation goes here
	
	%% all props
	strFindPattern = 'sStimParamsSettings.* = *';
	%generate properties from file
	ptrFile = fopen(strTargetFile);
	cellLines = {};
	cellProps = {};
	cellVals = {};
	cellComments = {};
	boolEnd = false;
	strLine = '';
	while ischar(strLine)
		if regexp(strLine,strFindPattern)
			cellLines(end+1,1) = {strLine};
			intComment = strfind(strLine,'%');
			%split line
			if isempty(intComment)
				intComment=numel(strLine)+1;
				strComment = '';
			else
				strComment =strtrim(strLine((intComment+1):end));
			end
			strCode = strLine(1:(intComment-1));
			strProp = strtrim(getFlankedBy(strCode,'sStimParamsSettings.','=','first'));
			strVal =strtrim(getFlankedBy(strCode,'=',';','last'));
			%assign if field
			if ~isempty(strProp) && ~contains(strVal,'eval(')
				cellComments(end+1,1) = {strComment};
				cellProps(end+1,1) = {strProp};
				cellVals(end+1,1) = {strVal};
			end
		end
		strLine = fgetl(ptrFile);
	end
	fclose(ptrFile);
end

