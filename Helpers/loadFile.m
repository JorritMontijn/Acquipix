function sVariables = loadFile(strFile)
	%loadFile Copies file to fast SSD and loads it from there. 
	%   varargout = loadFile(strFile)
	%For some reason, copying the file first and then loading it is much faster for .mat files than
	%loading it directly from a slow location (e.g., external hard drive) 

	%get temp location
	sRP = RP_populateStructure();
	strTempPath = sRP.strTempPath;
	if ~exist(strTempPath,'dir')
		error([mfilename ':TempPathAbsent'],sprintf('Temporary path does not exist: "%s". Please set a valid path using runRecordingProcessor().',strTempPath));
	end
	
	%split input
	sFileIn = dir(strFile);
	if isempty(sFileIn)
		error([mfilename ':TempPathAbsent'],sprintf('File does not exist: "%s".',strFile));
	elseif numel(sFileIn) > 1
		error([mfilename ':TempPathAbsent'],sprintf('Filename "%s" is ambiguous and gives %d results.',strFile,numel(sFileIn)));
	end
	
	%copy and load
	copyfile(fullpath(sFileIn.folder,sFileIn.name),fullpath(strTempPath,sFileIn.name));
	sVariables=load(fullpath(strTempPath,sFileIn.name));
end

