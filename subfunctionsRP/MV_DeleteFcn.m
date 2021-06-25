function MV_DeleteFcn
	global sFigMV;
	%close
	sFigMV.boolIsRunning = false;
	%{
	%save config to ini
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-2)),filesep);
	strIni = strcat(strPath,filesep,'configRP.ini');
	
	%get fields to save
	cellFields = fieldnames(RP_defaultValues());
	sRP2=struct;
	for intField=1:numel(cellFields)
		strField = cellFields{intField};
		if isfield(sRP,strField)
			sRP2.(strField) = sRP.(strField);
		end
	end
	
	%save settings to ini
	strData = struct2ini(sRP2,'sRP');
	fFile = fopen(strIni,'wt');
	fprintf(fFile,strData);
	fclose(fFile);
	%}
end