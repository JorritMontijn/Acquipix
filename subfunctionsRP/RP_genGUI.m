function [sFigRP,sRP] = RP_genGUI(varargin)
	%RP_genGUI Main function for offline eye tracker
	%   [sFigRP,sRP] = RP_genGUI(sFigRP,sRP)
	%
	
	%% construct gui
	global sRP;
	global sFigRP;
	
	%default parameters
	%master path
	if ~isfield(sRP,'strTempPath')
		error([mfilename ':NoPathDefined'],'Path definitions were not supplied as input');
	end
	cellExt = {'mp4','avi'};
	
	% check which version of matlab this is; naming of tooltips changed between R2019a and R2019b.
	if verLessThan('matlab','9.7')
		strTooltipField = 'TooltipString';
	else
		strTooltipField = 'Tooltip';
	end
	sFigRP.strTooltipField = strTooltipField;
	
	%% generate main GUI
	%locations: [from-left from-bottom width height]
	vecPosGUI = [0,0,850,700];
	ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Resize','off');
	%set main gui properties
	set(ptrMainGUI,'DeleteFcn','RP_DeleteFcn')
	set(ptrMainGUI, 'MenuBar', 'none','ToolBar', 'none');
	
	%set output
	sFigRP.output = ptrMainGUI;
	
	%% build GUI master parameters
	vecMainColor = [0.97 0.97 0.97];
	
	%retrieve path number
	cellFieldsRP = fieldnames(sRP);
	cellPathVarNames = cellfun(@getFlankedBy,cellFieldsRP,cellfill('str',size(cellFieldsRP)),cellfill('Path',size(cellFieldsRP)),'UniformOutput',false);
	cellPathVarNames(cellfun(@isempty,cellPathVarNames))=[];
	%get tot num
	intPathNum = numel(cellPathVarNames);
	
	%create panel
	sFigRP.ptrPanelPaths = uipanel('Parent',ptrMainGUI,'BackgroundColor',vecMainColor,...
		'Units','pixels','Title','Master paths','FontSize',10);
	dblPH = 30;
	dblPanelHeight = dblPH*(intPathNum+2.5);
	vecLocPanelMP = [10 vecPosGUI(4)-dblPanelHeight-10 vecPosGUI(3)-20 dblPanelHeight];
	set(sFigRP.ptrPanelPaths,'Position',vecLocPanelMP);
	
	vecLocSetPath = [20 dblPanelHeight-30 120 25];
	for intPathButton=1:intPathNum
		%get name
		strPathName = cellPathVarNames{intPathButton};
		vecLocSetPath = vecLocSetPath + [0 -30 0 0];
		%button
		strOutFieldButton = sprintf('ptrButtonSet%s',strPathName);
		sFigRP.(strOutFieldButton) = uicontrol(sFigRP.ptrPanelPaths,'Style','pushbutton','FontSize',11,...
			'String',sprintf('Set %s:',strPathName),...
			'Position',vecLocSetPath,...
			sFigRP.strTooltipField,sprintf('Set path to root directory for %s',strPathName),...
			'Callback',{@ptrButtonSetPath_Callback,strPathName});
		%path
		vecLocText = [vecLocSetPath(1)+vecLocSetPath(3)+10 vecLocSetPath(2)+2 450 20];
		strOutFieldText = sprintf('ptrText%s',strPathName);
		sFigRP.(strOutFieldText) = uicontrol(sFigRP.ptrPanelPaths,'Style','text','HorizontalAlignment','left','String','','FontSize',10,'BackgroundColor',[1 1 1],...
			'Position',vecLocText);
	end
	
	%%
	%%{
	%variables button
	vecLocVariablesButton = [vecLocSetPath(1) vecLocSetPath(2)-30 120 25];
	sFigRP.ptrButtonEditVariables = uicontrol(sFigRP.ptrPanelPaths,'Style','pushbutton','FontSize',11,...
		'String','Edit variables',...
		'Position',vecLocVariablesButton,...
		sFigRP.strTooltipField,'Set recording variables and meta data',...
		'Callback',@ptrButtonEditVariables_Callback);
	
	%compile button
	vecLocCompileButton = [vecLocVariablesButton(1)+vecLocVariablesButton(3)+5 vecLocVariablesButton(2) 120 25];
	sFigRP.ptrButtonCompileLibrary = uicontrol(sFigRP.ptrPanelPaths,'Style','pushbutton','FontSize',12,...
		'String','Find data',...
		'Position',vecLocCompileButton,...
		sFigRP.strTooltipField,'Search data paths for data',...
		'Callback',@ptrButtonCompileLibrary_Callback);
	
	%free temp space
	vecLocTempSpace = [vecLocCompileButton(1)+vecLocCompileButton(3)+5 vecLocCompileButton(2) 80 20];
	sFigRP.ptrStaticTextTempSpace = uicontrol(sFigRP.ptrPanelPaths,'Style','text','FontSize',10,...
		'String','Temp space:',...
		'Position',vecLocTempSpace,'BackgroundColor',vecMainColor);
	vecLocTempSpace = [vecLocTempSpace(1)+vecLocTempSpace(3)+5 vecLocTempSpace(2) 80 20];
	sFigRP.ptrTextTempSpace = uicontrol(sFigRP.ptrPanelPaths,'Style','text','FontSize',10,...
		'String','',...
		'Position',vecLocTempSpace,'BackgroundColor',[1 1 1]);
	
	%find sorter
	vecLocSorter = [vecLocTempSpace(1)+vecLocTempSpace(3)+5 vecLocTempSpace(2) 80 20];
	[dblV,strKilosortPath] = RP_AssertKilosort();
	if dblV > 0
		strSorter = ['Kilosort' num2str(dblV)];
	end
	sFigRP.ptrStaticTextSorter = uicontrol(sFigRP.ptrPanelPaths,'Style','text','FontSize',10,...
		'String','Spike sorter:',...
		'Position',vecLocSorter,'BackgroundColor',vecMainColor);
	vecLocSorter = [vecLocSorter(1)+vecLocSorter(3)+5 vecLocSorter(2) 75 20];
	sFigRP.ptrTextSorter = uicontrol(sFigRP.ptrPanelPaths,'Style','text','FontSize',10,...
		'String',strSorter,...
		sFigRP.strTooltipField,strKilosortPath,...
		'Position',vecLocSorter,'BackgroundColor',[1 1 1]);
	
	%switch to save temp data to permanent folder
	vecLocCheckTempWh = [vecLocSorter(1)+vecLocSorter(3)+5 vecLocSorter(2) 100 20];
	sFigRP.ptrCheckTempWh = uicontrol(sFigRP.ptrPanelPaths,'style','checkbox',...
			'Position',vecLocCheckTempWh,'String','Keep temp','FontSize',10,'BackgroundColor',vecMainColor,'Callback',@ptrCheckTempWh_Callback,...
			strTooltipField,sprintf(['Running phy requires temp_wh.dat, but this file is about as large as your whole recording.\n',...
			'You can still run phy without this check, but then you will only be able to access the most recently clustered recording.']));
	sFigRP.ptrCheckTempWh.Value = sRP.intPermaSaveOfTempWh;
	
	
	%% actions
	%set tracking parameters
	vecLocClusterButton = [20 20 150 25];
	sFigRP.ptrButtonDoClustering = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String',sprintf('Cluster spikes'),...
		'Position',vecLocClusterButton,...
		sFigRP.strTooltipField,sprintf('Cluster spikes with external sorter (%s)',strSorter),...
		'Callback',{@ptrButtonCluster_Callback,strSorter});
	
	vecLocCombineButton = [vecLocClusterButton(1)+vecLocClusterButton(3)+5 vecLocClusterButton(2:4)];
	sFigRP.ptrButtonSetLabels = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Combine sources',...
		'Position',vecLocCombineButton,...
		sFigRP.strTooltipField,'Align & combine data from multiple sources to a single clock',...
		'Callback',@ptrButtonCombine_Callback);
	
	vecLocAdjustCoordsButton = [vecLocCombineButton(1)+vecLocCombineButton(3)+5 vecLocCombineButton(2:4)];
	sFigRP.ptrButtonCheckResults = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Adjust coords',...
		'Position',vecLocAdjustCoordsButton,...
		sFigRP.strTooltipField,'Fine-tune probe location using ephys markers',...
		'Callback',@ptrButtonAdjustCoords_Callback);
	
	vecLocExportDataButton = [vecLocAdjustCoordsButton(1)+vecLocAdjustCoordsButton(3)+5 vecLocAdjustCoordsButton(2:4)];
	sFigRP.ptrButtonExportData = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Export files',...
		'Position',vecLocExportDataButton,...
		sFigRP.strTooltipField,'Export synchronized data & area-assigned units to aggregate output file',...
		'Callback',@ptrButtonExportData_Callback);
	
	%% run initial callbacks
	for intPathButton=1:intPathNum
		ptrButtonSetPath_Callback(sRP.(sprintf('str%sPath',cellPathVarNames{intPathButton})),[],cellPathVarNames{intPathButton});
	end
	
	%% set properties
	% Assign a name to appear in the window title.
	ptrMainGUI.Name = 'Recording Processor';
	
	% Move the window to the center of the screen.
	movegui(ptrMainGUI,'center')
	
	% Make the UI visible.
	ptrMainGUI.Visible = 'on';
	sFigRP.ptrMainGUI = ptrMainGUI;
	
	%unlock
	uiunlock(sFigRP);
	
	%% check if external dependencies (kilosort, npy and spikes) are installed
	dblKilosortVersion = RP_AssertKilosort();
	strInstallMsg = '';
	if isempty(dblKilosortVersion) || dblKilosortVersion < 2
		%build message
		strInstallMsg = [strInstallMsg 'Kilosort not found; please install from "https://github.com/MouseLand/Kilosort"' newline];
		%https://github.com/MouseLand/Kilosort
	end
	dblNpyVersion = RP_AssertNpy();
	if isempty(dblNpyVersion) || dblNpyVersion ~= 1
		%build message
		strInstallMsg = [strInstallMsg 'Npy-matlab not found; please install from "https://github.com/kwikteam/npy-matlab"' newline];
	end
	dblPhyhelperVersion = RP_AssertPhyhelpers();
	if isempty(dblPhyhelperVersion) || dblPhyhelperVersion ~= 1
		%build message
		strInstallMsg = [strInstallMsg 'Phy-helpers not found; please install from "https://github.com/cortex-lab/spikes/tree/master/preprocessing/phyHelpers"' newline];
	end
	
	
	if ~isempty(strInstallMsg)
		%disp msg
		ptrMsg = dialog('Position',[600 400 350 150],'Name','External code not found');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 00 300 100],...
			'FontSize',11,...
			'String',['Installations missing (check your path file):' newline strInstallMsg]);
		movegui(ptrMsg,'center')
		drawnow;
	end
	
	%% load meta vars
	strMetaVar = fullpath(sRP.strMetaVarFolder,sRP.strMetaVarFile);
	try
		sLoad1 = load(strMetaVar);
		sRP.sMetaVar = sLoad1.sMetaVar;
		clear sLoad1;
	catch
		sRP.sMetaVar = RP_defaultMetaVar();
	end
	
	%% callbacks
	function ptrButtonSetPath_Callback(hObject, eventdata,strPathName)
		%get target field
		strField = sprintf('str%sPath',strPathName);
		strTextField = sprintf('ptrText%s',strPathName);
		strFieldKey = sprintf('str%sKey',strPathName);
		strFieldName = sprintf('str%sName',strPathName);
		
		%retrieve path
		if isfield(sRP,strFieldName)
			if ischar(hObject)
				strNewPath = hObject;
				strNewFile = sRP.(strFieldName);
			else
				try
					[strNewFile,strNewPath] = uigetfile(fullpath(sRP.(strField),sRP.(strFieldKey)),sprintf('Select %s:',strPathName));
				catch
					[strNewFile,strNewPath] = uigetfile(sRP.(strFieldKey),sprintf('Select %s:',strPathName));
				end
			end
		else
			if ischar(hObject)
				strNewPath = hObject;
			else
				try
					strNewPath = uigetdir(sRP.(strField),sprintf('Select %s path:',strPathName));
				catch
					strNewPath = uigetdir('',sprintf('Select %s path:',strPathName));
				end
			end
		end
		
		%check if valid & set new path
		if ischar(strNewPath) && ~isempty(strNewPath) && exist(strNewPath','dir')
			sRP.(strField) = strNewPath;
			if exist('strNewFile','var') && ~isempty(strNewFile)
				sRP.(strFieldName) = strNewFile;
				sFigRP.(strTextField).String = fullpath(strNewPath,strNewFile);
			else
				sFigRP.(strTextField).String = strNewPath;
			end
			sFigRP.(strTextField).(sFigRP.strTooltipField) = sFigRP.(strTextField).String;
		else
			return;
		end
		
		%update temp if this is temp
		if strcmpi(strPathName,'Temp')
			%add free space
			objFile      = java.io.File(strNewPath(1:2));
			dblFreeGB   = objFile.getFreeSpace/(1024.^3);
			sFigRP.ptrTextTempSpace.String = sprintf('%.1f GB',dblFreeGB);
			sFigRP.ptrTextTempSpace.(sFigRP.strTooltipField) = sFigRP.(strTextField).String;
		end
	end
	function ptrButtonEditVariables_Callback(hObject, eventdata)
		try
			%generate gui so user can change fields
			sMetaVar = RP_genMetaVarWindow();
			
			%add to global
			sRP.sMetaVar = sMetaVar;
		catch ME
			dispErr(ME);
			errordlg(ME.message,'Error during variable editing');
		end
	end
	function ptrButtonCompileLibrary_Callback(hObject, eventdata)
		%message
		ptrMsg = dialog('Position',[600 400 250 50],'Name','Library Compilation');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 00 210 40],...
			'FontSize',11,...
			'String','Compiling data library...');
		movegui(ptrMsg,'center')
		drawnow;
		try
			%get data
			sRP.sFiles = RP_CompileDataLibrary(sRP,ptrText);
			
			%close msg
			delete(ptrMsg);
			
			%populate gui
			if isfield(sFigRP,'ptrPanelLibrary') && ~isempty(sFigRP.ptrPanelLibrary)
				delete(sFigRP.ptrPanelLibrary);
				delete(sFigRP.ptrSliderLibrary);
				delete(sFigRP.ptrTitleLibrary);
				sFigRP.ptrPanelLibrary=[];
			end
			
			
			%% populate new panel
			%get main GUI size and define subpanel size
			dblPanelX = 0.01;
			dblPanelY = 0.12;
			dblPanelHeight = vecLocPanelMP(2)/vecPosGUI(4)-dblPanelY;
			dblPanelWidth = 0.94;
			vecLocation = [dblPanelX dblPanelY dblPanelWidth dblPanelHeight];
			
			%generate slider panel
			[sFigRP.ptrPanelLibrary,sFigRP.ptrSliderLibrary,sFigRP.ptrTitleLibrary,sFigRP.sPointers] = RP_genSliderPanel(ptrMainGUI,vecLocation,sRP.sFiles);
		catch ME
			dispErr(ME);
			errordlg(ME.message,'Error during library compilation');
		end
	end
	function ptrButtonCluster_Callback(hObject, eventdata, strSorter)
		%get checked
		indUseFiles = RP_CheckSelection(sFigRP);
		if ~any(indUseFiles),return;end
		
		%check if all files have ephys data
		vecRunFiles = find(indUseFiles);
		indReady = false(size(vecRunFiles));
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			if isfield(sRP.sFiles(intFile),'sEphysAp') && ~isempty(sRP.sFiles(intFile).sEphysAp)
				indReady(intFileIdx) = true;
			end
		end
		if ~all(indReady)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','Not all files ready');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','Some files are missing AP data');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			movegui(ptrMsg,'center')
			drawnow;
			return
		else
			%run
			uilock(sFigRP);
			drawnow;
			
			for intFileIdx=1:numel(vecRunFiles)
				try
					intFile = vecRunFiles(intFileIdx);
					sFile = sRP.sFiles(intFile);
					sClustered = getPreProClustering(sFile,sRP);
					
					%update library
					if ~isempty(sClustered)
						%update parameter list
						sRP.sFiles(intFile).sClustered = sClustered;
						sFigRP.sPointers(intFile).Clustered.String = 'Y';
						sFigRP.sPointers(intFile).Clustered.ForegroundColor = [0 0.8 0];
						sFigRP.sPointers(intFile).Clustered.(sFigRP.strTooltipField) = ['Clustered data at: ' sClustered.folder];
						drawnow;
					end
				catch ME
					dispErr(ME);
					errordlg(ME.message,'Error during clustering');
				end
			end
			uiunlock(sFigRP);
		end
	end
	function ptrButtonCombine_Callback(hObject, eventdata)
		
		%get checked
		indUseFiles = RP_CheckSelection(sFigRP);
		if ~any(indUseFiles),return;end
		
		%get meta variables
		sMetaVar = sRP.sMetaVar;
		
		%check if all files have ephys data
		vecRunFiles = find(indUseFiles);
		indReady = false(size(vecRunFiles));
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			if isfield(sRP.sFiles(intFile),'sClustered') && ~isempty(sRP.sFiles(intFile).sClustered)
				indReady(intFileIdx) = true;
			end
		end
		
		if ~all(indReady)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','Not all files ready');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','Some files are missing clustering data');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			movegui(ptrMsg,'center')
			drawnow;
			return
		else
			%run
			uilock(sFigRP);
			drawnow;
			
			for intFileIdx=1:numel(vecRunFiles)
				try
					%get file
					intFile = vecRunFiles(intFileIdx);
					sFile = sRP.sFiles(intFile);
					
					% other variables
					sMetaVar.pulseCh = sFile.sMeta.syncSourceIdx; %pulse channel
					sMetaVar.pulsePeriod = sFile.sMeta.syncSourcePeriod; %pulse period
					
					%add to sFile
					sFile.sMetaVar = sMetaVar;
					
					%run prepro
					sSynthesis = getPreProSynthesis(sFile,sRP);
					
					%update library
					if ~isempty(sSynthesis)
						%update parameter list
						sRP.sFiles(intFile).sSynthesis = sSynthesis;
						sFigRP.sPointers(intFile).Synthesized.String = 'Y';
						sFigRP.sPointers(intFile).Synthesized.ForegroundColor = [0 0.8 0];
						sFigRP.sPointers(intFile).Synthesized.(sFigRP.strTooltipField) = ['Combined data at: ' sSynthesis.folder];
						drawnow;
					end
				catch ME
					dispErr(ME);
					errordlg(ME.message,'Error during synthesis');
				end
			end
			uiunlock(sFigRP);
		end
	end
	function ptrButtonAdjustCoords_Callback(hObject, eventdata)
		%get checked
		indUseFiles = RP_CheckSelection(sFigRP);
		if ~any(indUseFiles),return;end
		
		%check if all files have ephys data
		vecRunFiles = find(indUseFiles);
		indReady = false(size(vecRunFiles));
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			if isfield(sRP.sFiles(intFile),'sProbeCoords') && ~isempty(sRP.sFiles(intFile).sProbeCoords) && isfield(sRP.sFiles(intFile),'sSynthesis') && ~isempty(sRP.sFiles(intFile).sSynthesis)
				indReady(intFileIdx) = true;
			end
		end
		if ~all(indReady)
			ptrMsg = dialog('Position',[600 400 270 100],'Name','Not all files ready');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[10 50 250 40],...
				'FontSize',11,...
				'String','Some recordings are missing pre-processed files');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[110 10 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			movegui(ptrMsg,'center')
			drawnow;
			return
		else
			%run
			uilock(sFigRP);
			drawnow;
			
			for intFileIdx=1:numel(vecRunFiles)
				try
					intFile = vecRunFiles(intFileIdx);
					sFile = sRP.sFiles(intFile);
					
					%load AllenCCF
					if ~isfield(sRP,'st') || isempty(sRP.st)
						[tv,av,st] = RP_LoadABA(sRP.strAllenCCFPath);
						if isempty(tv),return;end
						sRP.tv = tv;
						sRP.av = av;
						sRP.st = st;
					end
					
					%% plot grid
					hMain = PH_GenGUI(sRP.av,sRP.tv,sRP.st,sFile);
					
					%% wait until done
					waitfor(hMain,'UserData','close');
					sGUI = guidata(hMain);
					close(hMain);
					
					%sFiles(intFile).sProbeCoords = sProbeCoords;
					%check if output is present
					if isfield(sGUI,'sProbeAdjusted') && ~isempty(sGUI.sProbeAdjusted) && isfield(sGUI.sProbeAdjusted,'probe_vector')
						%update parameter list
						vecColor = [0 0.8 0];
						sProbeCoords = sRP.sFiles(intFile).sProbeCoords;
						sProbeCoords.sProbeAdjusted = sGUI.sProbeAdjusted;
						sRP.sFiles(intFile).sProbeCoords = sProbeCoords;
						sFigRP.sPointers(intFile).Coords.String = num2str(sRP.sFiles(intFile).sProbeCoords.intProbeIdx);
						sFigRP.sPointers(intFile).Coords.(sFigRP.strTooltipField) = ['Probe track/coordinate data at: ' fullpath(sRP.sFiles(intFile).sProbeCoords.folder,sRP.sFiles(intFile).sProbeCoords.name)];
						sFigRP.sPointers(intFile).Coords.ForegroundColor = vecColor;
						drawnow;
					end
				catch ME
					dispErr(ME);
					errordlg(ME.message,'Error during probe histology');
				end
			end
			uiunlock(sFigRP);
		end
	end
	function ptrButtonExportData_Callback(hObject, eventdata)
		%get checked
		indUseFiles = RP_CheckSelection(sFigRP);
		if ~any(indUseFiles),return;end
		
		%check if all files have ephys data
		vecRunFiles = find(indUseFiles);
		indReady = false(size(vecRunFiles));
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			if (isfield(sRP.sFiles(intFile),'sProbeCoords') && isfield(sRP.sFiles(intFile).sProbeCoords,'sProbeAdjusted') && ~isempty(sRP.sFiles(intFile).sProbeCoords.sProbeAdjusted)) && (isfield(sRP.sFiles(intFile),'sSynthesis') && ~isempty(sRP.sFiles(intFile).sSynthesis))
				indReady(intFileIdx) = true;
			end
		end
		if ~all(indReady)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','Not all files ready');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','Some files are missing pre-processed data');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			movegui(ptrMsg,'center')
			drawnow;
			return
		else
			%run
			uilock(sFigRP);
			drawnow;
			
			for intFileIdx=1:numel(vecRunFiles)
				try
					intFile = vecRunFiles(intFileIdx);
					sFile = sRP.sFiles(intFile);
					
					%export file as AP file & save json
					intResultFlag = RP_ExportFile(sFile,sRP);
					
				catch ME
					dispErr(ME);
					errordlg(ME.message,'Error during file export');
				end
			end
			uiunlock(sFigRP);
		end
	end
	function ptrCheckTempWh_Callback(hObject, eventdata)
		sRP.intPermaSaveOfTempWh = sFigRP.ptrCheckTempWh.Value;
	end
end
