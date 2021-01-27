function intPresetIdx = saveStimPreset(sStimPresets,strFilename,intPresetIdx)
	%saveStimPreset Saves preset stimulus structure to database
	%intPresetIdx = saveStimPreset(sStimPresets,strFilename,intPresetIdx)
	
	%% set relative path
	strFullPath = mfilename('fullpath');
	cellPathParts = strsplit(strFullPath,filesep);
	strTargetPath = strjoin(cat(2,cellPathParts(1:(end-2)),'StimPresets'),filesep);
	strFile = strcat('Preset*_',strFilename,'*');
	%check next number
	if nargin < 3 || isempty(intPresetIdx)
		sFiles = dir(fullfile(strTargetPath,strFile));
		intPresetIdx = numel(sFiles) + 1;
	end
	
	%% save
	strSaveFile = sprintf('Preset%d_%s',intPresetIdx,strFilename);
	save(fullfile(strTargetPath,strSaveFile),'sStimPresets');
end