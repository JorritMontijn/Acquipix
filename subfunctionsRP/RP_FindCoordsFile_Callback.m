function RP_FindCoordsFile_Callback(hObject,eventdata,intFile)
	%globals
	global sRP;
	global sFigRP;
	
	%delete old coords file
	try
		sRP.sFiles(intFile).sProbeCoords = [];
		strOldFile = fullpath(sRP.sFiles(intFile).sProbeCoords.folder,sRP.sFiles(intFile).sProbeCoords.name);
		delete(strOldFile);
	catch
	end
	
	%open coords file
	strDefaultPath = sRP.strProbeLocPath;
	[cellPoints,strFile,strPath] = PH_OpenCoordsFile(strDefaultPath);
	if ~isempty(cellPoints)
		%load AllenCCF
		if ~isfield(sRP,'st') || isempty(sRP.st)
			[tv,av,st] = RP_LoadABA(sRP.strAllenCCFPath);
			if isempty(tv),return;end
			sRP.tv = tv;
			sRP.av = av;
			sRP.st = st;
		end
		
		% get probe nr
		strRec = sRP.sFiles(intFile).sMeta.strNidqName;
		intProbeIdx = PH_SelectProbeNr(cellPoints,strRec,sRP.tv,sRP.av,sRP.st);
		if isempty(intProbeIdx),return;end
		
		%set file name & folder
		strProbeFile = [strcat(strRec,'_ProbeCoords'),'.mat'];
		strFullFileProbeCoords = fullpath(sRP.sFiles(intFile).sEphysNidq.folder,strProbeFile);
		
		%which probe number?
		if isempty(sRP.sFiles(intFile).sProbeCoords),sRP.sFiles(intFile).sProbeCoords=[];end
		sRP.sFiles(intFile).sProbeCoords.folder = sRP.sFiles(intFile).sEphysNidq.folder;
		sRP.sFiles(intFile).sProbeCoords.name = strProbeFile;
		sRP.sFiles(intFile).sProbeCoords.sourcefolder = strPath;
		sRP.sFiles(intFile).sProbeCoords.sourcefile = strFile;
		sRP.sFiles(intFile).sProbeCoords.cellPoints = cellPoints;
		sRP.sFiles(intFile).sProbeCoords.intProbeIdx = intProbeIdx;
		
		%export probe coord file
		sProbeCoords = sRP.sFiles(intFile).sProbeCoords;
		save(strFullFileProbeCoords,'sProbeCoords');
	end
	
	%update button
	if isfield(sRP.sFiles(intFile),'sProbeCoords') && ~isempty(sRP.sFiles(intFile).sProbeCoords)
		strText = num2str(intProbeIdx);
		vecColor = [0 0.8 0];
		strTip = ['Probe track/coordinate data at: ' sRP.sFiles(intFile).sProbeCoords.sourcefolder];
	else
		strText = 'N';
		vecColor = [0.8 0 0];
		strTip = 'Did not find probe track/coordinate data';
	end
	sFigRP.sPointers(intFile).Coords.String = strText;
	sFigRP.sPointers(intFile).Coords.(sFigRP.strTooltipField) = strTip;
	sFigRP.sPointers(intFile).Coords.ForegroundColor = vecColor;
end