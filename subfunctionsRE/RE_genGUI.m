function [sFigRE,sRE] = RE_genGUI(sFigRE,sRE)
	%UNTITLED5 Summary of this function goes here
	%   Detailed explanation goes here
	
	%% generate main GUI
	%locations: [from-left from-bottom width height]
	ptrMainGUI = figure('Visible','off','Position',[0,0,600,800]);
	%set main gui properties
	set(ptrMainGUI, 'MenuBar', 'none');
	set(ptrMainGUI, 'ToolBar', 'none');
	set(ptrMainGUI,'DeleteFcn','RE_DeleteFcn')
	%set output
	sFigRE.output = ptrMainGUI;
	
	%% build GUI sub
	%list
	sFigRE.ptrTextStimSet  = uicontrol('Style','text','String','Select Experiment:','FontSize',12,...
		'Position',[50 750 200 20]); 
	
	sFigRE.ptrListSelectStimulusSet = uicontrol('Style','popupmenu','FontSize',10,...
		'Position',[50 700 200 50],...
		'Callback',@ptrListSelectStimulusSet_Callback);
	
	%% set properties
	%set to resize
	ptrMainGUI.Units = 'normalized';
	sFigRE.ptrTextStimSet.Units = 'normalized';
	sFigRE.ptrListSelectStimulusSet.Units = 'normalized';
	
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
	
	%% callbacks
	function ptrListSelectStimulusSet_Callback(hObject, eventdata) %#ok<DEFNU>
		%% get selection
		intStimSet = get(hObject,'Value');
		cellStimSets = get(hObject,'String');
		strStimSet = cellStimSets{intStimSet};
		
		%% delete old panel
		if isfield(sFigRE,'ptrPanelStimParamsParent') && ~isempty(sFigRE.ptrPanelStimParamsParent)
			delete(sFigRE.ptrPanelStimParamsParent);
			sFigRE.ptrPanelStimParamsParent = [];
		end
		
		%% get paths and files
		strFullPath = mfilename('fullpath');
		cellPath = strsplit(strFullPath,filesep);
		strPath = strjoin(cellPath(1:find(strcmpi(cellPath,'Acquipix'))),filesep);
		strTargetFile = fullfile(strPath,strcat(cellStimSets{intStimSet},'.m'));
		
		[cellProps,cellVals,cellComments] = RE_getParams(strTargetFile);
		intParams = numel(cellProps);
		
		%add to gui
		%ptrPanelStimParams = figure('Position',[0 0 500 intParams*30]);
		
		%%
		%get main GUI size and define subpanel size
		ptrMainGUI.Units = 'pixels';
		vecGuiSize = ptrMainGUI.Position;
		ptrMainGUI.Units = 'normalized';
		dblPanelHeight = 0.2;
		dblPanelY = 0.1;
		
		%calculate the total size of the subpanel content
		dblTotSize = (intParams+1)*30;
		dblRelSize = (dblTotSize/(vecGuiSize(end)*dblPanelHeight))+dblPanelHeight;
		
		%create the panels
		ptrPanelStimParamsParent = uipanel('Parent',ptrMainGUI);
		set(ptrPanelStimParamsParent,'Position',[0.01 dblPanelY 0.94 dblPanelHeight]);
		ptrPanelStimParams = uipanel('Parent',ptrPanelStimParamsParent);
		set(ptrPanelStimParams,'Position',[0 0 1 dblRelSize]);
		ptrSlider = uicontrol('Style','Slider','Parent',ptrMainGUI,...
			'Units','normalized','Position',[0.94 dblPanelY 0.05 dblPanelHeight],...
			'Value',1,'Callback',{@slider_callback1,ptrPanelStimParams});
		
		%add all variables
		vecParamTextPtrs = nan(1,intParams);
		vecParamEditPtrs = nan(1,intParams);
		for intParam=1:intParams
			vecParamTextPtrs(intParam) = uicontrol(ptrPanelStimParams,'style','text',...
				'Position',[1 (intParams*30)-((intParam-1)*30) 150 25],'String',cellProps{intParam},'FontSize',10);

			vecParamEditPtrs(intParam) = uicontrol(ptrPanelStimParams,'style','edit',...
				'Position',[150 (intParams*30)-((intParam-1)*30) 390 25],'String',cellVals{intParam},'Tooltip',cellComments{intParam},'FontSize',10);
		end
		
		%show panel & add to sFig
		sFigRE.ptrPanelStimParamsParent = ptrPanelStimParamsParent;
		slider_callback1(ptrSlider,[],ptrPanelStimParams);
		

		%% stim times
		structEP.dblSecsBlankAtStart = 3;
		structEP.dblSecsBlankPre = 0.3;
		structEP.dblSecsStimDur = 0.6;
		structEP.dblSecsBlankPost = 0.1;
		structEP.dblSecsBlankAtEnd = 3;
		dblTrialDur = structEP.dblSecsBlankPre + structEP.dblSecsStimDur + structEP.dblSecsBlankPost ;
		
		
	end
	function slider_callback1(hObject,eventdata,ptrSubPanel)
		vecSize = ptrSubPanel.Position;
		val = get(hObject,'Value');
		dblRealMax = vecSize(end) - 1;
		dblStartY = val*dblRealMax;
		vecSetPanelPos = [0 -dblStartY 1 vecSize(end)];
		set(ptrSubPanel,'Position',vecSetPanelPos);%[from-left from-bottom width height]
	end
end
