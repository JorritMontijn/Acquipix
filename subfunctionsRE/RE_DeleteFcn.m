function RE_DeleteFcn()
	%RE_DeleteFcn Ensures new GUI can start
	
	%% globals
	global sRE;
	global sFigRE;
	
	%% enable new gui
	sFigRE.IsRunning = false;
	
	%% save config to ini
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-1)),filesep);
	strIni = strcat(strPath,filesep,'config.ini');
	
	%save settings to ini
	sRE2 = RE_defaultValues();
	cellFields = fieldnames(sRE2);
	for intField=1:numel(cellFields)
		sRE2.(cellFields{intField}) = sRE.(cellFields{intField});
	end
	
	%save ini
	warning('off','struct2ini:FieldIgnored');
	strData = struct2ini(sRE2,'sRE');
	warning('on','struct2ini:FieldIgnored');
	fFile = fopen(strIni,'wt');
	fprintf(fFile,strData);
	fclose(fFile);
	
end