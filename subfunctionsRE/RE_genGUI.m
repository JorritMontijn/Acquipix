function [sFigRE,sRE] = RE_genGUI(sFigRE,sRE)
	%RE_genGUI Main function for runExperiment
	%   [sFigRE,sRE] = RE_genGUI(sFigRE,sRE)
	
	%% generate main GUI
	%locations: [from-left from-bottom width height]
	ptrMainGUI = figure('Visible','off','Position',[0,0,600,800],'Resize','off');
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
	sFigRE.ptrTextStimSet  = uicontrol('Style','text','String','Select Experiment:','FontSize',12,...
		'Position',vecLocTextStimSet); 
	
	vecLocListStimSet = vecLocTextStimSet + [0 -50 0 30];
	sFigRE.ptrListSelectStimulusSet = uicontrol('Style','popupmenu','FontSize',10,...
		'Position',vecLocListStimSet,...
		'Callback',@ptrListSelectStimulusSet_Callback);
	
	%stim set input checker
	sFigRE.ptrButtonCheckStimPresets = uicontrol('Style','pushbutton','FontSize',10,...
		'String','Evaluate Inputs',...
		'Position',[20 280 100 30],...
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
	vecExpLocStaticText = get(sFigRE.ptrTextStimSet,'Position');
	vecExpLocStaticText = vecExpLocStaticText + [0 60 0 20];
	strExp = ['Name: ' strRecording];
	sFigRE.ptrExpLocStaticText = uicontrol('Style','text','FontSize',12,...
		'Position',vecExpLocStaticText,...
		'HorizontalAlignment','Left',...
		'String',strExp);
	
	%% evaluate first stimulus
	ptrListSelectStimulusSet_Callback(sFigRE.ptrListSelectStimulusSet);
	
	%% callbacks
	function ptrListSelectStimulusSet_Callback(hObject, eventdata) %#ok<DEFNU>
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
		while ~boolFinishedLoading
			intPresetIdx = intPresetIdx + 1;
			try
				sStimPresets = loadStimPreset(intPresetIdx,strStimSet);
				cellStimPresets{end+1} = sStimPresets;
				cellStimPresetText{end+1} = sprintf('Set %d',intPresetIdx);
			catch
				boolFinishedLoading = true;
			end
		end
		
		%generate preset list
		vecLocTextSP = get(sFigRE.ptrTextStimSet,'Position');
		vecLocTextSP(1) = vecLocTextSP(1) + vecLocTextSP(3) + 25;
		sFigRE.ptrTextStimPresets  = uicontrol('Style','text','String','Select Stimulus Set:','FontSize',12,...
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
		dblPanelY = 0.1;
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
		for intVal=1:numel(cellVals)
			cellVals{intVal} = num2str(sStimPresets.(cellProps{intVal}));
		end
		
		%get main GUI size and define subpanel size
		dblPanelX = 0.01;
		dblPanelY = 0.4;
		dblPanelHeight = 0.4;
		dblPanelWidth = 0.94;
		vecLocation = [dblPanelX dblPanelY dblPanelWidth dblPanelHeight];
		
		%generate panel
		[sFigRE.ptrPanelStimPresetsParent,sFigRE.ptrSliderStimPresets] = RE_genSliderPanel(ptrMainGUI,vecLocation,cellProps,cellVals,[],0);
		
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
		if ~sRE.IsInputConfirmed
			error
			return;
		end
		
		%get experiment
		strStimType = sFigRE.ptrListSelectStimulusSet.String{sFigRE.ptrListSelectStimulusSet.Value};
		
		%retrieve stim preset panel settings
		sStimPresets = sRE.sStimPresets;
		sStimParamsSettings = sRE.sStimParams;
		sStimParamsSettings.strRecording = sRE.strRecording;
		
		%run!
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
