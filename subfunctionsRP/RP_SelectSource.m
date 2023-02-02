function intSelectSource = RP_SelectSource(sFiles,strPrompt)
	%RP_SelectSource GUI pop-up to select source from multiple files
	%   intSelectSource = RP_SelectSource(sFiles,[strPrompt])
	
	%default prompt
	if isempty(strPrompt) || ~ischar(strPrompt)
		strPrompt = 'Select source file';
	end
	intMaxChars = 110;
	if numel(strPrompt) > intMaxChars
		strPrompt(intMaxChars:end) = [];
		strPrompt((end+1):(end+3)) = '...';
	end
	
	%check if necessary
	intSelectSource = numel(sFiles);
	if intSelectSource > 1
		%show files
		cellFiles = cell(1,intSelectSource);
		for intFile=1:intSelectSource
			cellFiles{intFile} = [sFiles(intFile).name ' at ' sFiles(intFile).folder];
		end
		intSelectSource = listdlg('Name','Select source',...
			'PromptString',strPrompt,...
			'SelectionMode','single','ListString',cellFiles,'ListSize',[600 20*(intSelectSource+1)]);
	end
end

