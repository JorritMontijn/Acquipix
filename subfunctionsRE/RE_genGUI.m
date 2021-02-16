function [sFigRE,sRE] = RE_genGUI(sFigRE,sRE)
	%RE_genGUI Main function for runExperiment
	%   [sFigRE,sRE] = RE_genGUI(sFigRE,sRE)
	
	%% generate main GUI
	%locations: [from-left from-bottom width height]
	vecPosGUI = [0,0,600,850];
	ptrMainGUI = figure('Visible','off','Units','pixels','Position',vecPosGUI,'Resize','off');
	%set main gui properties
	set(ptrMainGUI, 'MenuBar', 'none');
	set(ptrMainGUI, 'ToolBar', 'none');
	set(ptrMainGUI,'DeleteFcn','RE_DeleteFcn')
	
	%set output
	sFigRE.output = ptrMainGUI;
	
	%% ask for animal name
	strRecording = RE_getAnimalName();
	sRE.strRecording = strRecording;
	
	%% build GUI sub
	%list
	vecLocTextStimSet = [50 680 200 20];
	sFigRE.ptrTextStimSet  = uicontrol('Style','text','String','Select Experiment:','FontSize',10,...
		'Position',vecLocTextStimSet); 
	
	vecLocListStimSet = vecLocTextStimSet + [0 -50 0 30];
	sFigRE.ptrListSelectStimulusSet = uicontrol('Style','popupmenu','FontSize',10,...
		'Position',vecLocListStimSet,...
		'Callback',@ptrListSelectStimulusSet_Callback);
	
	%stim set input checker
	sFigRE.ptrButtonCheckStimPresets = uicontrol('Style','pushbutton','FontSize',10,...
		'String','Evaluate Inputs',...
		'Position',[20 285 100 30],...
		'Enable','off',...
		'Visible','off',...
		'UserData','lock',...
		'Callback',@ptrButtonCheckStimPresets_Callback);
	
	%estimated duration text
	vecLocButtonStimPres = get(sFigRE.ptrButtonCheckStimPresets,'Position');
	vecEstDurLocStaticText = [vecLocButtonStimPres(1)+vecLocButtonStimPres(3) vecLocButtonStimPres(2) + vecLocButtonStimPres(4) 0 0] +...
		[20 -25 200 25];
	vecEstDurLocText = [vecEstDurLocStaticText(1) vecEstDurLocStaticText(2)-20 vecEstDurLocStaticText(3) 20];
	
	sFigRE.ptrStaticTextEstDur = uicontrol('Style','text','FontSize',10,...
		'Position',vecEstDurLocStaticText,...
		'Visible','off',...
		'String','Estimated Duration:');
	sFigRE.ptrTextEstDur = uicontrol('Style','text','FontSize',10,...
		'Position',vecEstDurLocText,...
		'Visible','off',...
		'String','NaN');
	
	%stim set saver
	vecLocSaveNewStimSet = [vecEstDurLocStaticText(1)+vecEstDurLocStaticText(3) vecEstDurLocStaticText(2) 0 0] + [20 2 100 25];
	vecLocOverwriteStimSet = vecLocSaveNewStimSet + [0 -25 0 0];
	vecLocDeleteStimSet = vecLocOverwriteStimSet + [vecLocOverwriteStimSet(3)+5 0 0 0];
	sFigRE.ptrButtonOverwriteStimSet = uicontrol('Style','pushbutton','FontSize',10,...
		'String','Overwrite',...
		'Position',vecLocOverwriteStimSet,...
		'Enable','off',...
		'Visible','off',...
		'UserData','lock',...
		'Callback',@ptrButtonOverwriteStimPresets_Callback);
	sFigRE.ptrButtonSaveNewStimSet = uicontrol('Style','pushbutton','FontSize',10,...
		'String','Save New Set',...
		'Position',vecLocSaveNewStimSet,...
		'Enable','off',...
		'Visible','off',...
		'UserData','lock',...
		'Callback',@ptrButtonSaveNewStimSet_Callback);
	sFigRE.ptrButtonDeleteStimSet = uicontrol('Style','pushbutton','FontSize',10,...
		'String','Delete',...
		'Position',vecLocDeleteStimSet,...
		'Enable','off',...
		'Visible','off',...
		'UserData','lock',...
		'Callback',@ptrButtonDeleteStimSet_Callback);
	
	%start button
	sFigRE.ptrButtonStartExperiment = uicontrol('Style','pushbutton','FontSize',10,...
		'String','Start Experiment!',...
		'FontWeight','bold',...
		'Position',[50 20 130 40],...
		'Enable','off',...
		'Visible','off',...
		'UserData','lock',...
		'Callback',@ptrButtonStartExperiment_Callback);
	
	%% set properties
	%set to resize
	%ptrMainGUI.Units = 'normalized';
	%sFigRE.ptrTextStimSet.Units = 'normalized';
	%sFigRE.ptrListSelectStimulusSet.Units = 'normalized';
	
	% Assign a name to appear in the window title.
	ptrMainGUI.Name = 'Acquipix Experiment Interface';
	
	% Move the window to the center of the screen.
	movegui(ptrMainGUI,'center')
	
	% Make the UI visible.
	ptrMainGUI.Visible = 'on';
	sFigRE.ptrMainGUI = ptrMainGUI;
	
	%% populate with data
	%populate structure
	sRE = RE_populateStructure(sRE);
	
	%initialize
	[sFigRE,sRE] = RE_initialize(sFigRE,sRE);
	
	%unlock
	SC_unlock(sFigRE);
	
	%% set experiment name
	vecExpLocStaticText = [20 vecPosGUI(4)-25 300 25];
	strExp = ['Name: ' strRecording];
	sFigRE.ptrExpLocStaticText = uicontrol('Style','text','FontSize',10,...
		'Position',vecExpLocStaticText,...
		'HorizontalAlignment','Left',...
		'String',strExp);
	
	%% build SGL module
	%make panel
	sFigRE.ptrPanelSGL = uipanel('Parent',ptrMainGUI,'Units','pixels','Title','SpikeGLX Client','FontSize',10);
	dblHeight = 120;
	vecLocPanelSGL = [vecExpLocStaticText(1) vecExpLocStaticText(2)-dblHeight-2 279 dblHeight];
	set(sFigRE.ptrPanelSGL,'Position',vecLocPanelSGL);
	
	%edit text for host address & whether connected
	sFigRE.ptrTextHostAddressSGL  = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String','Host:','FontSize',10,'HorizontalAlignment','Left',...
		'Position',[10 75 40 20]);
	sFigRE.ptrEditHostAddressSGL  = uicontrol(sFigRE.ptrPanelSGL,'Style','edit','String',sRE.strHostAddress,'FontSize',10,...
		'Position',[50 77 150 20],'Callback',@ptrEditHostAddressSGL_Callback);
	sFigRE.ptrTextConnectedSGL  = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String','Idle','FontSize',10,'FontAngle','italic','ForegroundColor',[0 0 0],...
		'Position',[200 75 79 20]);
	
	%display run name
	sFigRE.ptrStaticTextRunNameSGL = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String','Recording:','FontSize',10,'ForegroundColor',[0 0 0],'HorizontalAlignment','Left',...
		'Position',[10 50 70 20]);
	sFigRE.ptrTextRunNameSGL = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String','...','FontSize',10,'FontAngle','italic','ForegroundColor',[0 0 0],...
		'Position',[80 50 195 20]);
	
	%is eye-tracker connected?
	%sFigRE.ptrStaticTextEyeTrackerSGL = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String','Eye Tracker:','FontSize',10,'ForegroundColor',[0 0 0],'HorizontalAlignment','Left',...
	%	'Position',[10 25 90 20]);
	%sFigRE.ptrTextEyeTrackerSGL = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String','Not connected','FontSize',10,'FontAngle','italic','ForegroundColor',[0 0 0],...
	%	'Position',[100 25 175 20]);
	
	%display available disk space
	dblFreeGB = nan;
	sFigRE.ptrStaticTextDiskSpace = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String','Free space:','FontSize',10,'ForegroundColor',[0 0 0],'HorizontalAlignment','Left',...
		'Position',[10 0 80 20]);
	sFigRE.ptrTextDiskSpaceAvailable = uicontrol(sFigRE.ptrPanelSGL,'Style','text','String',sprintf('%.1f GB',dblFreeGB),'FontSize',10,'ForegroundColor',[0 0 0],...
		'Position',[90 0 50 20]);
	
	%button to start recording
	sFigRE.ptrToggleStartRecording = uicontrol(sFigRE.ptrPanelSGL,'Style','togglebutton','String','Record NPX','FontSize',10,'ForegroundColor',[0 0 0],...
		'Position',[165 2 110 22],'Callback',@ptrToggleStartRecording_Callback);
	
	%% build Daq module
	%make panel
	sFigRE.ptrPanelDaq = uipanel('Parent',ptrMainGUI,'Units','pixels','Title','NI-DAQ Client','FontSize',10);
	vecLocPanelDaq = vecLocPanelSGL + [vecLocPanelSGL(3)+2 0 0 0];
	set(sFigRE.ptrPanelDaq,'Position',vecLocPanelDaq);
	
	%query connected devices & build list
	objDevice = daq.getDevices;
	cellDaqList = {objDevice(:).Model};
	if isempty(cellDaqList)
		cellDaqList = {' '};
	end
	
	%select device text
	sFigRE.ptrStaticTextDaqDevice  = uicontrol(sFigRE.ptrPanelDaq,'Style','text','String','Device:','FontSize',10,'HorizontalAlignment','Left',...
		'Position',[10 75 50 20]);
	
	sFigRE.ptrListSelectDaqDevice = uicontrol(sFigRE.ptrPanelDaq,'Style','popupmenu','FontSize',10,...
		'Position',[60 77 210 20],...
		'String',cellDaqList,...
		'Callback',@ptrListSelectDaq_Callback);
	
	%pupil light intensity
	sFigRE.ptrStaticTextPupilLight  = uicontrol(sFigRE.ptrPanelDaq,'Style','text','String','Pupil LED gain:','FontSize',10,'HorizontalAlignment','Left',...
		'Position',[10 50 100 20]);
	sFigRE.ptrEditPupilLight  = uicontrol(sFigRE.ptrPanelDaq,'Style','edit','String','1','FontSize',10,'HorizontalAlignment','center',...
		'Position',[110 50 50 20]);
	
	%sync light intensity
	sFigRE.ptrStaticTextSyncLight = uicontrol(sFigRE.ptrPanelDaq,'Style','text','String','Sync LED gain:','FontSize',10,'HorizontalAlignment','Left',...
		'Position',[10 25 100 20]);
	sFigRE.ptrEditSyncLight = uicontrol(sFigRE.ptrPanelDaq,'Style','edit','String','0.5','FontSize',10,'HorizontalAlignment','center',...
		'Position',[110 25 50 20]);
	
	%buttons
	sFigRE.ptrButtonSetLightsOn = uicontrol(sFigRE.ptrPanelDaq,'Style','pushbutton','FontSize',10,...
		'String','LEDs On',...
		'Position',[10 2 100 20],...
		'Callback',@ptrButtonSetLightsOn_Callback);
	
	%buttons
	sFigRE.ptrButtonSetLightsOff = uicontrol(sFigRE.ptrPanelDaq,'Style','pushbutton','FontSize',10,...
		'String','LEDs Off',...
		'Position',[120 2 100 20],...
		'Callback',@ptrButtonSetLightsOff_Callback);
	
	%don't forget to update gratings and RF mapper (and opto stim?) to nat
	%mov changes
	%error to do
	
	%% evaluate first stimulus
	ptrListSelectStimulusSet_Callback(sFigRE.ptrListSelectStimulusSet);
	drawnow;
	
	%% connect to SGL and Daq
	ptrListSelectDaq_Callback;
	ptrEditHostAddressSGL_Callback;
	
	%% callbacks
	function ptrEditHostAddressSGL_Callback(hObject, eventdata)
		%connect to SGL
		sRE.strHostAddress = get(sFigRE.ptrEditHostAddressSGL,'String');
		try
			
			set(sFigRE.ptrTextConnectedSGL,'ForegroundColor',[1 0.5 0],'String','Connecting');
			drawnow;
			[hSGL,strRunName,sParamsSGL] = InitSGL(sRE.strRecording,sRE.strHostAddress,false);
			sRE.hSGL = hSGL;
			sRE.strRunName = strRunName;
			sRE.sParamsSGL = sParamsSGL;
			set(sFigRE.ptrTextConnectedSGL,'ForegroundColor',[0 0.8 0],'String','Linked');
			sRE.IsConnectedSGL = true;
		catch ME
			set(sFigRE.ptrTextConnectedSGL,'ForegroundColor',[0 0 0],'String','Idle');
			sRE.IsConnectedSGL = false;
			%rethrow(ME);
			return
		end
		
		%display run name
		set(sFigRE.ptrTextRunNameSGL,'String',sRE.strRunName);
		
		%display available disk space
		strDataDirSGL = GetDataDir(sRE.hSGL);
		jFileObj = java.io.File(strDataDirSGL);
		dblFreeGB = (jFileObj.getFreeSpace)/(1024^3);
		set(sFigRE.ptrTextDiskSpaceAvailable,'String',sprintf('%.1f GB',dblFreeGB));
		
	end
	function ptrToggleStartRecording_Callback(hObject, eventdata)
		%start recording if requested & not already recording
		if get(hObject,'Value') == 1 && isfield(sRE,'hSGL')
			if ~IsSaving(sRE.hSGL)
				SetRecordingEnable(sRE.hSGL, 1);
			end
			hTicStart = tic;
			
			%check if output is being saved
			while ~IsSaving(sRE.hSGL) && toc(hTicStart) < 1
				pause(0.01);
			end
			if ~IsSaving(sRE.hSGL)
				set(hObject,'Value',0);
			end
		else
			set(hObject,'Value',0);
		end
	end
	function ptrListSelectDaq_Callback(hObject, eventdata)
		intUseDevice = sFigRE.ptrListSelectDaqDevice.Value;
		strDevice = sFigRE.ptrListSelectDaqDevice.String{intUseDevice};
		if isempty(strDevice) || strcmp(strDevice,' ')
			sRE.objDaqOut = [];
			sRE.IsConnectedDaq = false;
		else
			sRE.objDaqOut = openDaqOutput(intUseDevice);
			sRE.IsConnectedDaq = true;
		end
	end
	function ptrButtonSetLightsOn_Callback(hObject, eventdata)
		if isempty(sRE.objDaqOut),return;end
		%get values
		dblSyncLightMultiplier = str2double(sFigRE.ptrEditSyncLight.String);
		dblPupilLightMultiplier = str2double(sFigRE.ptrEditPupilLight.String);
		
		%set
		stop(sRE.objDaqOut);
		outputData1 = dblSyncLightMultiplier*linspace(3, 3, 250)';
		outputData2 = dblPupilLightMultiplier*linspace(3, 3, 250)';
		queueOutputData(sRE.objDaqOut,[outputData1 outputData2]);
		prepare(sRE.objDaqOut);
		pause(0.1);
		startBackground(sRE.objDaqOut)
	end
	function ptrButtonSetLightsOff_Callback(hObject, eventdata)
		if isempty(sRE.objDaqOut),return;end
		%set
		stop(sRE.objDaqOut);
		outputData1 = 0*linspace(3, 3, 250)';
		outputData2 = 0*linspace(3, 3, 250)';
		queueOutputData(sRE.objDaqOut,[outputData1 outputData2]);
		prepare(sRE.objDaqOut);
		pause(0.1);
		startBackground(sRE.objDaqOut)
	end
	function ptrListSelectStimulusSet_Callback(hObject, eventdata)
		%% get selection
		intStimSet = get(hObject,'Value');
		cellStimSets = get(hObject,'String');
		strStimSet = cellStimSets{intStimSet};
		
		%% set switches to unconfirmed
		sRE.IsInputConfirmed = false;
		%check button
		set(sFigRE.ptrButtonCheckStimPresets,...
			'Enable','off',...
			'Visible','on',...
			'UserData','lock');
		
		%start button
		set(sFigRE.ptrButtonStartExperiment,...
			'Enable','off',...
			'Visible','on',...
			'UserData','lock');
		set(sFigRE.ptrStaticTextEstDur,...
			'Visible','on');
		set(sFigRE.ptrTextEstDur,...
			'Visible','on');
		%save buttons
		set(sFigRE.ptrButtonOverwriteStimSet,...
			'Visible','on');
		set(sFigRE.ptrButtonSaveNewStimSet,...
			'Visible','on');
		set(sFigRE.ptrButtonDeleteStimSet,...
			'Visible','on');
		
		%% delete old panels
		if isfield(sFigRE,'ptrTextStimPresets') && ~isempty(sFigRE.ptrTextStimPresets)
			delete(sFigRE.ptrTextStimPresets);
			sFigRE.ptrTextStimPresets = [];
		end
		if isfield(sFigRE,'ptrPanelStimParamsParent') && ~isempty(sFigRE.ptrPanelStimParamsParent)
			delete(sFigRE.ptrPanelStimParamsParent);
			sFigRE.ptrPanelStimParamsParent = [];
			delete(sFigRE.ptrSliderStimParams);
			sFigRE.ptrSliderStimParams = [];
		end
		if isfield(sFigRE,'ptrListSelectStimPresets') && ~isempty(sFigRE.ptrListSelectStimPresets)
			delete(sFigRE.ptrListSelectStimPresets);
			sFigRE.ptrListSelectStimPresets = [];
		end
		
		%% get stim presets
		boolFinishedLoading = false;
		cellStimPresets = cell(0);
		cellStimPresetText = cell(0);
		intPresetIdx = 0;
		while ~boolFinishedLoading || intPresetIdx < 100
			intPresetIdx = intPresetIdx + 1;
			try
				sStimPresets = loadStimPreset(intPresetIdx,strStimSet);
				cellStimPresets{end+1} = sStimPresets;
				cellStimPresetText{end+1} = sprintf('Set %d',intPresetIdx);
				boolFinishedLoading = false;
			catch
				boolFinishedLoading = true;
			end
		end
		
		%generate preset list
		vecLocTextSP = get(sFigRE.ptrTextStimSet,'Position');
		vecLocTextSP(1) = vecLocTextSP(1) + vecLocTextSP(3) + 25;
		sFigRE.ptrTextStimPresets  = uicontrol('Style','text','String','Select Stimulus Set:','FontSize',10,...
			'Position',vecLocTextSP);
		
		vecLocListSP = get(sFigRE.ptrListSelectStimulusSet,'Position');
		vecLocListSP(1) = vecLocListSP(1) + vecLocListSP(3) + 25;
		sFigRE.ptrListSelectStimPresets = uicontrol('Style','popupmenu','FontSize',10,...
			'Position',vecLocListSP,...
			'String',cellStimPresetText,...
			'Callback',@ptrListSelectStimPresets_Callback);
		
		%assign data
		sRE.cellStimPresets = cellStimPresets;
		
		%% get paths and files
		strFullPath = mfilename('fullpath');
		cellPath = strsplit(strFullPath,filesep);
		strPath = strjoin(cellPath(1:find(strcmpi(cellPath,'Acquipix'))),filesep);
		strTargetFile = fullfile(strPath,strcat(cellStimSets{intStimSet},'.m'));
		
		[cellProps,cellVals,cellComments] = RE_getParams(strTargetFile);
		
		%% stim parameters
		%get main GUI size and define subpanel size
		dblPanelX = 0.01;
		dblPanelY = 0.08;
		dblPanelHeight = 0.2;
		dblPanelWidth = 0.94;
		vecLocation = [dblPanelX dblPanelY dblPanelWidth dblPanelHeight];
		
		%generate slider panel
		[sFigRE.ptrPanelStimParamsParent,sFigRE.ptrSliderStimParams] = RE_genSliderPanel(ptrMainGUI,vecLocation,cellProps,cellVals,cellComments);
		
		%unlock
		set(sFigRE.ptrButtonCheckStimPresets,...
			'Enable','on',...
			'UserData','unlock');
		set(sFigRE.ptrButtonStartExperiment,...
			'Enable','on',...
			'UserData','unlock');
		
		%generate content
		ptrListSelectStimPresets_Callback(sFigRE.ptrListSelectStimPresets);
				
	end
	function ptrListSelectStimPresets_Callback(hObject, eventdata) %#ok<DEFNU>
		
		%remove old panel
		if isfield(sFigRE,'ptrPanelStimPresetsParent') && ~isempty(sFigRE.ptrPanelStimPresetsParent)
			delete(sFigRE.ptrPanelStimPresetsParent);
			sFigRE.ptrPanelStimPresetsParent = [];
			delete(sFigRE.ptrSliderStimPresets);
			sFigRE.ptrSliderStimPresets = [];
		end
		
		%get data
		cellStimPresets = sRE.cellStimPresets;
		sStimPresets = cellStimPresets{hObject.Value};
		cellProps = fieldnames(sStimPresets);
		cellVals = cell(size(cellProps));
		cellCallbacks = cell(size(cellProps));
		for intVal=1:numel(cellVals)
			cellVals{intVal} = num2str(sStimPresets.(cellProps{intVal}));
			cellCallbacks{intVal} = @ptrButtonCheckStimPresets_Callback;
		end
		
		%get main GUI size and define subpanel size
		dblPanelX = 0.01;
		dblPanelY = 0.38;
		dblPanelHeight = 0.38;
		dblPanelWidth = 0.94;
		vecLocation = [dblPanelX dblPanelY dblPanelWidth dblPanelHeight];
		
		%generate panel
		[sFigRE.ptrPanelStimPresetsParent,sFigRE.ptrSliderStimPresets] = RE_genSliderPanel(ptrMainGUI,vecLocation,cellProps,cellVals,[],cellCallbacks,0);
		
		%evalute parameters
		ptrButtonCheckStimPresets_Callback;
	end
	function ptrButtonCheckStimPresets_Callback(hObject, eventdata) %#ok<DEFNU>
		%unlock check
		set(sFigRE.ptrButtonStartExperiment,...
			'Enable','on',...
			'UserData','unlock');
		
		%calculate estimated time
		strStimType = sFigRE.ptrListSelectStimulusSet.String{sFigRE.ptrListSelectStimulusSet.Value};
		
		%retrieve stim preset panel settings
		sStimPresets = SC_getPanelSettings(sFigRE.ptrPanelStimPresetsParent.Children);
	
		%retrieve stim parameter panel settings
		sStimParams = SC_getPanelSettings(sFigRE.ptrPanelStimParamsParent.Children);
		
		%combine & evaluate
		warning('off','catstruct:DuplicatesFound');
		sStimStruct = catstruct(sStimParams,sStimPresets);
		warning('on','catstruct:DuplicatesFound');
		[strEstTotDur,sStimParamsEvaluated,sStimObject] = RE_evaluateStimPresets(sStimStruct,strStimType);
	
		%update text
		set(sFigRE.ptrTextEstDur,...
			'String',strEstTotDur,...
			'Visible','on');
		
		%set switch to confirmed
		sRE.IsInputConfirmed = true;
		sRE.sStimPresets = sStimPresets;
		sRE.sStimParams = sStimParams;
	end
	function ptrButtonStartExperiment_Callback(hObject, eventdata) %#ok<DEFNU>
		%evaluate variables
		ptrButtonCheckStimPresets_Callback;
		if ~sRE.IsInputConfirmed || ~sRE.IsConnectedSGL || ~sRE.IsConnectedDaq
			error
			return;
		end
		
		%get experiment
		strStimType = sFigRE.ptrListSelectStimulusSet.String{sFigRE.ptrListSelectStimulusSet.Value};
		
		%retrieve stim preset panel settings
		sStimPresets = sRE.sStimPresets;
		sStimParamsSettings = sRE.sStimParams;
		sStimParamsSettings.strRecording = sRE.strRecording;
		
		%get led gains
		dblSyncLightMultiplier = str2double(sFigRE.ptrEditSyncLight.String);
		dblPupilLightMultiplier = str2double(sFigRE.ptrEditPupilLight.String);
		if isempty(dblSyncLightMultiplier) || ~isnumeric(dblSyncLightMultiplier)
			dblSyncLightMultiplier = 0.5;
		end
		if isempty(dblPupilLightMultiplier) || ~isnumeric(dblPupilLightMultiplier)
			dblPupilLightMultiplier = 1;
		end
		
		%get meta settings
		sExpMeta = struct;
		sExpMeta.dblPupilLightMultiplier = dblPupilLightMultiplier;
		sExpMeta.dblSyncLightMultiplier = dblSyncLightMultiplier;
		sExpMeta.strHostAddress = sRE.strHostAddress;
		sExpMeta.objDaqOut = sRE.objDaqOut;
		sExpMeta.hSGL = sRE.hSGL;
		sExpMeta.strRunName = sRE.strRunName;
		sExpMeta.sParamsSGL = sRE.sParamsSGL;
		
		%run!
		assignin('base','sExpMeta',sExpMeta);
		assignin('base','sStimParamsSettings',sStimParamsSettings);
		assignin('base','sStimPresets',sStimPresets);
		
		evalin('base',strStimType);
	end
	function ptrButtonOverwriteStimPresets_Callback(hObject, eventdata) %#ok<DEFNU>
		%evaluate variables
		ptrButtonCheckStimPresets_Callback;
		if ~sRE.IsInputConfirmed
			error
			return;
		end
		
		%get experiment
		strStimType = sFigRE.ptrListSelectStimulusSet.String{sFigRE.ptrListSelectStimulusSet.Value};
		
		%retrieve stim preset panel settings
		sStimPresets = sRE.sStimPresets;
		
		%get this set
		strSets = sFigRE.ptrListSelectStimPresets.String{sFigRE.ptrListSelectStimPresets.Value};
		intSet = str2double(strSets(5:end));
		
		%save
		sOpt = struct;
		sOpt.Interpreter = 'tex';
		sOpt.Default = 'Cancel';
		strAns = questdlg(sprintf('%s OVERWRITE preset with current parameters?\n\n"%s Set %d"\n','\fontsize{10}',strStimType,intSet),'Overwrite preset','Overwrite','Cancel',sOpt);
		if strcmp(strAns,'Overwrite')
			saveStimPreset(sStimPresets,strStimType,intSet);
		end
		
	end
	function ptrButtonSaveNewStimSet_Callback(hObject, eventdata) %#ok<DEFNU>
		%evaluate variables
		ptrButtonCheckStimPresets_Callback;
		if ~sRE.IsInputConfirmed
			error
			return;
		end
		
		%get current sets
		cellSets = sFigRE.ptrListSelectStimPresets.String;
		vecSets = cellfun(@(x) str2double(x(5:end)),cellSets);
		vecPossible = 1:(max(vecSets)+1);
		intFirstOpenEntry = find(~ismember(vecPossible,vecSets),1);
		
		%get experiment
		strStimType = sFigRE.ptrListSelectStimulusSet.String{sFigRE.ptrListSelectStimulusSet.Value};
		
		%retrieve stim preset panel settings
		sStimPresets = sRE.sStimPresets;
		
		%save
		sOpt = struct;
		sOpt.Interpreter = 'tex';
		sOpt.Default = 'Cancel';
		strAns = questdlg(sprintf('%s Save current parameters as new preset?\n\n"%s Set %d"\n','\fontsize{10}',strStimType,intFirstOpenEntry),'Save new preset','Create','Cancel',sOpt);
		if strcmp(strAns,'Create')
			saveStimPreset(sStimPresets,strStimType,intFirstOpenEntry);
		else
			return;
		end
		
		%update gui
		ptrListSelectStimulusSet_Callback(sFigRE.ptrListSelectStimulusSet);
		sFigRE.ptrListSelectStimPresets.Value = intFirstOpenEntry;
		ptrListSelectStimPresets_Callback(sFigRE.ptrListSelectStimPresets);
	end
	function ptrButtonDeleteStimSet_Callback(hObject, eventdata) %#ok<DEFNU>
		%evaluate variables
		ptrButtonCheckStimPresets_Callback;
		if ~sRE.IsInputConfirmed
			error
			return;
		end
		
		%get experiment
		strStimType = sFigRE.ptrListSelectStimulusSet.String{sFigRE.ptrListSelectStimulusSet.Value};
		
		%get this set
		strSets = sFigRE.ptrListSelectStimPresets.String{sFigRE.ptrListSelectStimPresets.Value};
		intSet = str2double(strSets(5:end));
		
		%save
		sOpt = struct;
		sOpt.Interpreter = 'tex';
		sOpt.Default = 'Cancel';
		strAns = questdlg(sprintf('%s DELETE current preset?\n\n"%s Set %d"\n','\fontsize{10}',strStimType,intSet),'Delete preset','Delete','Cancel',sOpt);
		if strcmp(strAns,'Delete')
			%delete
			strFullPath = mfilename('fullpath');
			cellPathParts = strsplit(strFullPath,filesep);
			strTargetPath = strjoin(cat(2,cellPathParts(1:(end-2)),'StimPresets'),filesep);
			strDeleteFile = sprintf('Preset%d_%s.mat',intSet,strStimType);
			delete(fullfile(strTargetPath,strDeleteFile));
		else
			return;
		end
		
		%update gui
		ptrListSelectStimulusSet_Callback(sFigRE.ptrListSelectStimulusSet);
	end
	
end
