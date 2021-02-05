function sStimPresets = loadStimPreset(intPresetIdx,strFilename)
	
	%% set relative path
	strFullPath = mfilename('fullpath');
	cellPathParts = strsplit(strFullPath,filesep);
	strTargetPath = strjoin(cat(2,cellPathParts(1:(end-2)),'StimPresets'),filesep);
	strFile = sprintf('Preset%d_%s',intPresetIdx,strFilename);
	
	%% load
	sLoad = load(fullfile(strTargetPath,strFile));
	sStimPresets = sLoad.sStimPresets;
end