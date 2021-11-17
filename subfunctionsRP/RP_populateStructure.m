function sRP = RP_populateStructure(sRP)
	%RP_populateStructure Prepares recording processor parameters by loading ini file,
	%						or creates one with default values
	
	%check for ini file
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-2)),filesep);
	strIni = strcat(strPath,filesep,'configRP.ini');
	
	%get defaults
	sDRP = RP_defaultValues();
	
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
		sRP=catstruct(sDRP,sRP);
		warning('on','catstruct:DuplicatesFound');
	else
		sRP=sDRP;
	end
end
