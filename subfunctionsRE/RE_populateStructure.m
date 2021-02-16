function sRE = RE_populateStructure(sRE_old)
	%UNTITLED4 Summary of this function goes here
	%   Detailed explanation goes here
	
	%% metadata & figure defaults
	%check metadata
	if ~isfield(sRE_old,'metaData')
		sRE_old.metaData = struct;
	end
	
	%check for ini file
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-1)),filesep);
	strIni = strcat(strPath,filesep,'config.ini');
	
	%get defaults
	sRET = RE_defaultValues();
	
	%load ini
	if exist(strIni,'file')
		%load data
		fFile = fopen(strIni,'rt');
		vecData = fread(fFile);
		fclose(fFile);
		%convert
		strData = cast(vecData','char');
		[cellStructs,cellStructNames] = ini2struct(strData);
		eval([cellStructNames{1} '= cellStructs{1};']);
		%merge structures
		warning('off','catstruct:DuplicatesFound');
		sRE=catstruct(sRET,sRE);
		warning('on','catstruct:DuplicatesFound');
	else
		sRE=sRET;
	end
	%add initial inputs
	warning('off','catstruct:DuplicatesFound');
	sRE=catstruct(sRE,sRE_old);
	warning('on','catstruct:DuplicatesFound');
	
	%initialize variables
	sRE.IsInitialized = false;
end

