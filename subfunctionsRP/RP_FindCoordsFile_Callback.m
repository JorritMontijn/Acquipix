function RP_FindCoordsFile_Callback(hObject,eventdata,intFile)
	%globals
	global sRP;
	global sFigRP;
	
	%find file
	strOldPath = cd(sRP.strProbeLocPath);
	[strFile,strPath]=uigetfile('probe_ccf.mat','Select probe coordinate file');
	cd(strOldPath);
	if isempty(strFile) || (numel(strFile)==1 && strFile==0)
		return;
	end
	
	%load
	strRec = sRP.sFiles(intFile).sMeta.strNidqName;
	sLoad = load(fullpath(strPath,strFile));
	if isfield(sLoad,'probe_ccf') && isstruct(sLoad.probe_ccf) && isfield(sLoad.probe_ccf,'points')
		probe_ccf = sLoad.probe_ccf;
		intProbeNum = numel(probe_ccf);
		if intProbeNum > 1
			%load AllenCCF
			if ~isfield(sRP,'st') || isempty(sRP.st)
				try
					sRP.tv = readNPY(fullpath(sRP.strAllenCCFPath,'template_volume_10um.npy')); % grey-scale "background signal intensity"
					sRP.av = readNPY(fullpath(sRP.strAllenCCFPath,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
					sRP.st = PH_loadStructureTree(fullpath(sRP.strAllenCCFPath,'structure_tree_safe_2017.csv')); % a table of what all the labels mean
				catch ME
					strStack = sprintf('Error in %s (Line %d)',ME.stack(1).name,ME.stack(1).line);
					errordlg(sprintf('%s\n%s',ME.message,strStack),'AllenCCF load error')
					return;
				end
			end
			
			%generate selection options
			cellProbes = cell(1,intProbeNum);
			for intProbe=1:intProbeNum
				intIntersectArea = probe_ccf(intProbe).trajectory_areas(find(probe_ccf(intProbe).trajectory_areas>1,1,'first'));
				cellAreas = string(sRP.st.name);
				strArea = cellAreas{intIntersectArea};
				cellProbes{intProbe} = sprintf('Probe %d, starting at %s',intProbe,strArea);
			end
			
			%show probes
			intProbeIdx = listdlg('Name','Select probe','PromptString',sprintf('Select probe # for %s',strRec),...
				'SelectionMode','single','ListString',cellProbes,'ListSize',[300 20*intProbeNum]);
			if isempty(intProbeIdx),return;end
		else
			intProbeIdx = 1;
		end
	else
		try
			error([mfilename ':FileTypeNotRecognized'],'File is of unknown format');
		catch ME
			strStack = sprintf('Error in %s (Line %d)',ME.stack(1).name,ME.stack(1).line);
			errordlg(sprintf('%s\n%s',ME.message,strStack),'Probe coord error')
			return;
		end
	end
	
	%set file name & folder
	strExp = sRP.sFiles(intFile).sMeta.strNidqName;
	strProbeFile = [strcat(strExp,'_ProbeCoords'),'.mat'];
	strFullFileProbeCoords = fullpath(sRP.sFiles(intFile).sEphysNidq.folder,strProbeFile);
	
	%which probe number?
	sRP.sFiles(intFile).sProbeCoords.folder = sRP.sFiles(intFile).sEphysNidq.folder;
	sRP.sFiles(intFile).sProbeCoords.name = strProbeFile;
	sRP.sFiles(intFile).sProbeCoords.sourcefolder = strPath;
	sRP.sFiles(intFile).sProbeCoords.sourcefile = strFile;
	sRP.sFiles(intFile).sProbeCoords.probe_ccf = probe_ccf;
	sRP.sFiles(intFile).sProbeCoords.intProbeIdx = intProbeIdx;
	
	%export probe coord file
	sProbeCoords = sRP.sFiles(intFile).sProbeCoords;
	save(strFullFileProbeCoords,'sProbeCoords');
	
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