function [strFilename,strLogDir,strTempDir,strTexDir] = RE_assertPaths(strOutputPath,strRecording,strTempObjectPath,strThisFilePath)
	%RE_assertPaths Generates and tests required output paths
	%   [strFilename,strLogDir,strTempDir,strTexDir] = RE_assertPaths(strOutputPath,strRecording,strTempObjectPath,strThisFilePath)
	
	%% generate texture path
	cellPathParts = strsplit(strThisFilePath,filesep);
	strSourceFile = cellPathParts{end};
	if strcmp(strSourceFile((end-1):end),'.m')
		strSourceFile = strSourceFile(1:(end-2));
	end
	strTexSubDir = 'StimulusTextures';
	strTexDir = strcat(strjoin(cellPathParts(1:(end-1)),filesep),filesep,strTexSubDir); %where are the stimulus textures saved?
	%test
	strOldPath = cd(strTexDir);
	cd(strOldPath);
	
	%% define output filename
	vecC = clock;
	strTime = strrep(getTime(),':','_');
	strFilename = sprintf('%04d%02d%02d_%s_%s',vecC(1),vecC(2),vecC(3),strRecording,strTime);
	strSessionDir = strcat(strOutputPath,getDate()); %where are the logs saved?
	if isa(strFilename,'char') && ~isempty(strFilename)
		%append filename
		if ~contains(strFilename,strSourceFile)
			strFilename = strcat(strFilename,'_',strSourceFile);
		end
		%make directory
		strLogDir = strcat(strSessionDir,filesep,strRecording,filesep); %where are the logs saved?
		if ~exist(strLogDir,'dir')
			mkdir(strLogDir);
		end
		strOldPath = cd(strLogDir);
		%check if file does not exist
		if exist([strLogDir filesep strFilename],'file') || exist([strLogDir filesep strFilename '.mat'],'file')
			error([mfilename ':PathExists'],'File "%s" already exists!',strFilename);
		end
	end
	
	%% check if temporary directory exists, clean or make
	strTempDir = fullfile(strTempObjectPath,'TempObjects');
	if exist(strTempDir,'dir')
		sFiles = dir(strcat(strTempDir,filesep,'*.mat'));
		intFileNum = numel(sFiles);
		if intFileNum > 0
			fprintf('Deleting %d temporary .mat files...\n',intFileNum);
			for intFile=1:intFileNum
				delete(strcat(strTempDir,filesep,sFiles(intFile).name));
			end
			fprintf('\b  Done!\n');
		end
	else
		if exist(strTempObjectPath,'dir')
			mkdir(strTempDir);
		else
			sME = struct;
			sME.identifier = [mfilename ':NetworkDirMissing'];
			sME.message = ['Cannot connect to ' strTempDir];
			error(sME);
		end
	end
end

