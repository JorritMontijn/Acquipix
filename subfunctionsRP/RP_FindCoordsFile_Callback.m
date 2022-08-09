function RP_FindCoordsFile_Callback(hObject,eventdata,intFile)
	%globals
	global sRP;
	global sFigRP;
	
	try
		%lock gui
		uilock(sFigRP);
		drawnow;
		
		%get name
		if isfield(sRP.sFiles(intFile).sMeta,'strNidqName')
			strName = sRP.sFiles(intFile).sMeta.strNidqName;
		else
			strName = [];
		end
		
		%load atlas
		if ~isfield(sRP,'sAtlas') || isempty(sRP.sAtlas)
			ptrListSelectAtlas_Callback();
		end
		
		%open coords file
		strDefaultPath = sRP.strProbeLocPath;
		[sProbeCoords,strFile,strPath] = PH_LoadProbeFile(sRP.sAtlas,strDefaultPath,strName);
		if ~isfield(sProbeCoords,'sourceatlas') && ~isfield(sProbeCoords,'sProbeAdjusted') && ~(isfield(sProbeCoords,'cellPoints') && ~isempty(sProbeCoords.cellPoints) && ~isempty(sProbeCoords.cellPoints{1}))
			errordlg('This is not a SliceFinder or ProbeFinder file','Wrong file type');
			return
		elseif isfield(sProbeCoords,'sourceatlas') && ~strcmpi(sProbeCoords.sourceatlas,sRP.sAtlas.Type)
			errordlg(sprintf('Atlas of probe file %s is not the same as the currently loaded atlas!',sProbeCoords.sourceatlas),'Wrong atlas loaded');
			return
		end
		
		%save a copy of the probe coords file
		strRec = sRP.sFiles(intFile).sMeta.strNidqName;
		strProbeFile = [strcat(strRec,'_ProbeCoords'),'.mat'];
		strFullFileProbeCoords = fullpath(sRP.sFiles(intFile).sEphysNidq.folder,strProbeFile);
		
		%add data
		sRP.sFiles(intFile).sProbeCoords=sProbeCoords;
		sRP.sFiles(intFile).sProbeCoords.folder = sRP.sFiles(intFile).sEphysNidq.folder;
		sRP.sFiles(intFile).sProbeCoords.name = strProbeFile;
		sRP.sFiles(intFile).sProbeCoords.sourcefolder = strPath;
		sRP.sFiles(intFile).sProbeCoords.sourcefile = strFile;
		
		%export probe coord file
		sProbeCoords = sRP.sFiles(intFile).sProbeCoords;
		save(strFullFileProbeCoords,'sProbeCoords');

		%update button
		if isfield(sRP.sFiles(intFile).sProbeCoords,'sProbeAdjusted') && isfield(sRP.sFiles(intFile).sProbeCoords.sProbeAdjusted,'probe_area_full_per_cluster')
			strText = num2str(sRP.sFiles(intFile).sProbeCoords.intProbeIdx);
			vecColor = [0 0.8 0];
			strTip = ['Adjusted probe track/coordinate data at: ' sRP.sFiles(intFile).sProbeCoords.sourcefolder];
		else
			strText = num2str(sRP.sFiles(intFile).sProbeCoords.intProbeIdx);
			vecColor = [1 0.5 0];
			strTip = ['Raw probe track/coordinate data at: ' sRP.sFiles(intFile).sProbeCoords.sourcefolder];
		end
		sFigRP.sPointers(intFile).Coords.String = strText;
		sFigRP.sPointers(intFile).Coords.(sFigRP.strTooltipField) = strTip;
		sFigRP.sPointers(intFile).Coords.ForegroundColor = vecColor;
		
		%unlock gui
		uiunlock(sFigRP);
		drawnow;
	catch ME
		%unlock gui
		uiunlock(sFigRP);
		drawnow;
		rethrow(ME)
	end
end