function sMetaVar = RP_genMetaVarWindow()
	
	%% globals
	global sFigMV;
	global sRP;
	
	%% load file
	strMetaVar = fullpath(sRP.strMetaVarFolder,sRP.strMetaVarFile);
	try
		sLoad1 = load(strMetaVar);
		sMetaVar = sLoad1.sMetaVar;
		clear sLoad1;
	catch
		sMetaVar = RP_defaultMetaVar();
	end
	
	%% build GUI
	% check which version of matlab this is; naming of tooltips changed between R2019a and R2019b.
	if verLessThan('matlab','9.7')
		strTooltipField = 'TooltipString';
	else
		strTooltipField = 'Tooltip';
	end
	%build figure
	sFigMV = struct;
	sFigMV.boolAccept = false;
	sFigMV.boolIsRunning = true;
	vecPosGUI = [0,0,100,100];
	sFigMV.ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Resize','off');
	%set main gui properties
	set(sFigMV.ptrMainGUI, 'MenuBar', 'none','ToolBar', 'none');
	set(sFigMV.ptrMainGUI,'DeleteFcn','MV_DeleteFcn')
	sFigMV.ptrMainGUI.Name = 'Meta-var loader';
	
	%set output
	sFigMV.output = sFigMV.ptrMainGUI;
	MV_genFig();
	sFigMV.ptrMainGUI.Visible = 'on';
	
	%unlock
	uiunlock(sFigMV);
	
	%wait for accept
	while sFigMV.boolIsRunning
		pause(0.1);
	end
	
	if sFigMV.boolAccept
		%save
		ptrButtonSave_Callback();
	else
		%load original file
		strMetaVarLoc = fullpath(sRP.strMetaVarFolder,sRP.strMetaVarFile);
		try
			%load settings
			sLoadEnd = load(strMetaVarLoc);
			sMetaVar = sLoadEnd.sMetaVar;
		catch
			%use defaults
			sMetaVar = RP_defaultMetaVar();
		end
	end
	
	%delete window
	delete(sFigMV.ptrMainGUI);
	
	%% subfunctions & callbacks
	function MV_Update()
		cellFields = fieldnames(sMetaVar);
		for intField=1:numel(cellFields)
			strFieldName = cellFields{intField};
			strEditPtr = sprintf('ptrEditField_%s',strFieldName);
			strFieldVal = sFigMV.(strEditPtr).String;
			sMetaVar.(strFieldName) = strFieldVal;
		end
	end
	function MV_genFig()
		%clear figure
		clf(sFigMV.ptrMainGUI);
		% get fields
		cellFields = fieldnames(sMetaVar);
		intFieldNum = numel(cellFields);
		
		%define size
		dblLineHeight = 30;
		dblTotHeight = dblLineHeight*(intFieldNum + 5.5);
		vecPosGUI = [0,0,500,dblTotHeight];
		sFigMV.ptrMainGUI.Position = vecPosGUI;
		
		%load & save buttons
		vecLocLoad = [10 dblTotHeight-dblLineHeight 50 25];
		
		%load button
		sFigMV.ptrButtonLoad = uicontrol(sFigMV.ptrMainGUI,'Style','pushbutton','FontSize',11,...
			'String',sprintf('Load'),...
			'Position',vecLocLoad,...
			strTooltipField,sprintf('Load file with the metadata variables of the recording'),...
			'Callback',@ptrButtonLoad_Callback);
		
		%save button
		vecLocSave = [vecLocLoad(1)+vecLocLoad(3)+5 vecLocLoad(2) 70 25];
		sFigMV.ptrButtonSave = uicontrol(sFigMV.ptrMainGUI,'Style','pushbutton','FontSize',11,...
			'String',sprintf('Save as'),...
			'Position',vecLocSave,...
			strTooltipField,sprintf('Save file with these metadata variables'),...
			'Callback',@ptrButtonSave_Callback);
		
		%file location
		vecLocText = [vecLocSave(1)+vecLocSave(3)+10 vecLocLoad(2) 270 20];
		strMetaVarFile = fullpath(sRP.strMetaVarFolder,sRP.strMetaVarFile);
		if isempty(strMetaVarFile)
			strMetaVarFile = 'default';
		end
		sFigMV.ptrTextFile = uicontrol(sFigMV.ptrMainGUI,'Style','text','HorizontalAlignment','left','String',strMetaVarFile,'FontSize',10,'BackgroundColor',[0.97 0.97 0.97],...
			'Position',vecLocText);
		sFigMV.ptrTextFile.String = strMetaVarFile;
		sFigMV.ptrTextFile.(strTooltipField) = strMetaVarFile;
			
		%generate delete button, field name text & field value edit
		vecLocButton = [vecLocLoad(1) vecLocLoad(2)-dblLineHeight 50 25];
		for intField=1:intFieldNum
			strFieldName = cellFields{intField};
			strFieldVal = sMetaVar.(strFieldName);
			
			%delete button
			strButtonPtr = sprintf('ptrButtonRemfield%s',strFieldName);
			vecLocButton = vecLocButton - [0 dblLineHeight 0 0];
			sFigMV.(strButtonPtr) = uicontrol(sFigMV.ptrMainGUI,'Style','pushbutton','FontSize',11,...
				'String',sprintf('Rem'),...
				'Position',vecLocButton,...
				strTooltipField,sprintf('Remove field "%s"',strFieldName),...
				'Callback',{@ptrButtonRemField_Callback,strFieldName});
			
			%field name text
			vecLocText = [vecLocButton(1)+vecLocButton(3)+10 vecLocButton(2)+2 150 20];
			sFigMV.ptrTextField = uicontrol(sFigMV.ptrMainGUI,'Style','text','HorizontalAlignment','left','String',strFieldName,'FontSize',10,'BackgroundColor',[1 1 1],...
				'Position',vecLocText);
			
			%field value edit
			strEditPtr = sprintf('ptrEditField_%s',strFieldName);
			vecLocEdit = [vecLocText(1)+vecLocText(3)+10 vecLocButton(2) 180 vecLocButton(4)];
			sFigMV.(strEditPtr) = uicontrol(sFigMV.ptrMainGUI,'Style','edit','HorizontalAlignment','left','String',strFieldVal,'FontSize',10,'BackgroundColor',[1 1 1],...
				'Position',vecLocEdit);
			
		end
		
		%new field
		vecLocNewField = [vecLocButton(1) vecLocButton(2)-dblLineHeight 80 25];
		sFigMV.ptrButtonLoad = uicontrol(sFigMV.ptrMainGUI,'Style','pushbutton','FontSize',11,...
			'String',sprintf('New field'),...
			'Position',vecLocNewField,...
			strTooltipField,sprintf('Add new field'),...
			'Callback',@ptrButtonNewField_Callback);
		
		%accept button
		vecLocAccept = [vecLocNewField(1) vecLocNewField(2)-dblLineHeight*2 80 30];
		sFigMV.ptrButtonSave = uicontrol(sFigMV.ptrMainGUI,'Style','pushbutton','FontSize',12,...
			'String',sprintf('Accept'),...
			'Position',vecLocAccept,...
			strTooltipField,sprintf('Accept these metadata variables'),...
			'Callback',@ptrButtonAccept_Callback);
		
		%center
		movegui(sFigMV.ptrMainGUI,'center')
	end
	function ptrButtonAccept_Callback(handles,eventdata)
		sFigMV.boolAccept = true;
		sFigMV.boolIsRunning = false;
	end
	function ptrButtonNewField_Callback(handles,eventdata)
		%retrieve latest settings
		MV_Update();
		
		%get new field
		prompt = {'Enter new parameter name:','Enter new parameter value:'};
		dlgtitle = 'New parameter';
		dims = [1 35];
		definput = {'',''};
		cellAns = inputdlg(prompt,dlgtitle,dims,definput);
		sMetaVar.(cellAns{1}) = cellAns{2};
		
		%regenerate gui
		MV_genFig();
	end
	function ptrButtonRemField_Callback(handles,eventdata,strDeleteFieldName)
		%retrieve latest settings
		MV_Update();
	
		%remove field
		sMetaVar = rmfield(sMetaVar,strDeleteFieldName);
		
		%regenerate gui
		MV_genFig();
	end
	function ptrButtonLoad_Callback(handles,eventdata)
		%retrieve path
		try
			strOldFile = fullpath(sRP.strMetaVarFolder,sRP.strMetaVarFile);
			if isempty(strOldFile),error;end
			[strNewFile,strNewPath] = uigetfile(strOldFile,'Select meta-var file:');
		catch
			[strNewFile,strNewPath] = uigetfile('*.mat','Select meta-var file:');
		end
		strMetaVarLoc = fullpath(strNewPath,strNewFile);
		if ~isempty(strMetaVarLoc) && exist(strMetaVarLoc,'file')
			%load settings
			sRP.strMetaVarFolder = strNewPath;
			sRP.strMetaVarFile = strNewFile;
			sLoad2 = load(strMetaVarLoc);
			sMetaVar = sLoad2.sMetaVar;
			clear sLoad2;
			
			%regenerate gui
			MV_genFig();
		end
	end
	function ptrButtonSave_Callback(handles,eventdata)
		%retrieve path
		try
			strOldFile = fullpath(sRP.strMetaVarFolder,sRP.strMetaVarFile);
			if isempty(strOldFile),error;end
			[strNewFile,strNewPath] = uiputfile(strOldFile,'Save meta-var file as:');
		catch
			[strNewFile,strNewPath] = uiputfile('*.mat','Save meta-var file as:');
		end
		strMetaVarLoc = fullpath(strNewPath,strNewFile);
		if ~isempty(strMetaVarLoc)
			%retrieve latest settings
			MV_Update();
	
			%export
			sRP.strMetaVarFolder = strNewPath;
			sRP.strMetaVarFile = strNewFile;
			save(strMetaVarLoc,'sMetaVar');
			
			%set new name
			sFigMV.ptrTextFile.String = strMetaVarLoc;
			sFigMV.ptrTextFile.(strTooltipField) = strMetaVarLoc;
		end
	end
end