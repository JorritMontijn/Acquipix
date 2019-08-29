%% starting function
function varargout = runOnlineRF(varargin)
	% runDetectCells Detect cells with GUI
	%
	%	Version 1.0 [2019-04-02]
	%		Created by Jorrit Montijn
	%	Version 1.0.1 [2019-04-11]
	%		Improved high-pass filtering and rewrote for GPU processing
	%	Version 1.0.2 [2019-05-01]
	%		Stepwise data loading to reduce memory load
	%	Version 1.0.3 [2019-05-10]
	%		ENV-support and bug fixes
	
	%set tags
	%#ok<*INUSL>
	%#ok<*INUSD>
	
	% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @runOnlineRF_OpeningFcn, ...
		'gui_OutputFcn',  @runOnlineRF_OutputFcn, ...
		'gui_LayoutFcn',  [] , ...
		'gui_Callback',   []);
	if nargin && ischar(varargin{1})
		gui_State.gui_Callback = str2func(varargin{1});
	end
	
	if nargout
		[varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
	else
		gui_mainfcn(gui_State, varargin{:});
	end
	% End initialization code - DO NOT EDIT
	
end
%% these are functions that don't do anything, but are required by matlab
function ptrListSelectImage_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditMagnification_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditHighpassFreq_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrListSelectChannel_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditDownsample_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonOldFig_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrPanelPlotIn_SelectionChangedFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonNewFig_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditHighpassFreq_Callback(hObject, eventdata, handles),end %#ok<DEFNU>

%% opening function; initializes output
function runOnlineRF_OpeningFcn(hObject, eventdata, handles, varargin)
	%opening actions
	
	%define globals
	global sFig;
	global sRM;
	
	%set closing function
	set(hObject,'DeleteFcn','RM_DeleteFcn')
	
	% set rainbow logo
	I = imread('LogoRFmapper.jpg');
	%I2 = imresize(I, [100 NaN]);
	axes(handles.ptrAxesLogo);
	imshow(I);
	drawnow;
	
	% set default output
	handles.output = hObject;
	guidata(hObject, handles);
	
	%set default values
	sRM = struct;
	sRM = RM_populateStructure(sRM);
	
	%populate figure
	boolInit = true;
	sFig = RM_populateFigure(handles,boolInit);
	
	% set timer to query whether there is a data update every second
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @RM_main;
	sFig.objTimer = objTimer;
	start(objTimer);
	
	%lock 
	set(sFig.ptrEditHighpassFreq,'UserData','lock');
	set(sFig.ptrEditDownsample,'UserData','lock');
	
	% Update handles structure
	guidata(hObject, handles);
end
%% defines output variables
function varargout = runOnlineRF_OutputFcn(hObject, eventdata, handles)
	%output
	varargout{1} = handles.output;
end
%% change in data type to load
function ptrPanelDataType_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by main function, so no other
	%action is required except sending a confirmation message
	
	%get global
	global sFig;
	
	%lock GUI
	RM_lock(handles);
	
	%get selected button
	intLoadEnv = get(handles.ptrButtonDataENV,'Value');
	if intLoadEnv == 1
		strLoadDataType = 'dENV';
		set(sFig.ptrEditHighpassFreq,'UserData','lock');
		set(sFig.ptrEditDownsample,'UserData','lock');
	else
		strLoadDataType = 'dRAW';
		set(sFig.ptrEditHighpassFreq,'UserData','');
		set(sFig.ptrEditDownsample,'UserData','');
	end
	
	%update message
	cellText = {['Switched data type to ' strLoadDataType]};
	RM_updateTextInformation(cellText);
	
	%unlock GUI
	RM_unlock(handles);
end
%% select which image to display as background
function ptrListSelectImage_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%selected image is automatically queried by drawing function; so no
	%other action is required other than redrawing
	
	%lock GUI
	RM_lock(handles);
	
	%redraw
	RM_redraw(1);
	
	%unlock GUI
	RM_unlock(handles);
end
%% this function initializes everything
function ptrButtonChooseSourceTDT_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%This function lets the user select a TDT data path
	
	%get globals
	global sFig;
	global sRM;
	
	%lock GUI
	RM_lock(handles);
	
	%switch path
	try
		oldPath = cd(sRM.metaData.strSourcePathTDT);
	catch
		oldPath = cd();
	end
	
	%get file
	strSourcePathTDT = uigetdir('Select TDT data path');
	%back to old path
	cd(oldPath);
	if isempty(strSourcePathTDT) || isscalar(strSourcePathTDT),RM_unlock(handles);return;end
	if strcmpi(strSourcePathTDT(end),filesep)
		strSourcePathTDT(end) = [];
	end
	sRM.strSourcePathTDT = strSourcePathTDT;
	[strBlock,intStop,intStart] = getFlankedBy(strSourcePathTDT,filesep,'','last');
	strRecording = strSourcePathTDT(1:(intStart-1));
	if strcmp(strRecording(end),filesep),strRecording(end) = [];end
  
	%back to old path
	cd(oldPath);
	
	%fill recording/block data
	set(sFig.ptrTextRecording, 'string', strRecording);
	set(sFig.ptrTextBlock, 'string', strBlock);
	
	%unlock GUI
	RM_unlock(handles);
	
	%check if both data path and stim path have been set
	if isfield(sRM,'strSourcePathTDT') && ~isempty(sRM.strSourcePathTDT) && ...
			isfield(sRM,'strSourcePathLog') && ~isempty(sRM.strSourcePathLog)
		[sFig,sRM] = RM_initialize(sFig,sRM);
	end
end
function ptrButtonChooseSourceStim_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%This function lets the user select a stim log path
	
	%get globals
	global sFig;
	global sRM;
	
	%lock GUI
	RM_lock(handles);
	
	%switch path
	try
		oldPath = cd(sRM.metaData.strSourcePathLog);
	catch
		oldPath = cd();
	end
	
	%get file
	strSourcePathLog = uigetdir('Select stim log path');
	%back to old path
	cd(oldPath);
	if isempty(strSourcePathLog) || isscalar(strSourcePathLog),RM_unlock(handles);return;end
	if strcmpi(strSourcePathLog(end),filesep)
		strSourcePathLog(end) = [];
	end
	sRM.strSourcePathLog = strSourcePathLog;
	
	%fill recording/block data
	set(sFig.ptrTextStimPath, 'string', strSourcePathLog);
	
	%unlock GUI
	RM_unlock(handles);
	
	%check if both data path and stim path have been set
	if isfield(sRM,'strSourcePathTDT') && ~isempty(sRM.strSourcePathTDT) && ...
			isfield(sRM,'strSourcePathLog') && ~isempty(sRM.strSourcePathLog)
		[sFig,sRM] = RM_initialize(sFig,sRM);
	end
end
function ptrListSelectChannel_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%lock GUI
	RM_lock(handles);
	
	% update maps
	RM_redraw(1);
	
	%unlock GUI
	RM_unlock(handles);
end
function ptrEditDownsample_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%get globals
	global sFig;
	global sRM;
	
	%default downsample
	dblSampFreq = sRM.dblSampFreq;
	dblSubSampleToReq = str2double(get(sFig.ptrEditDownsample,'String'));
	intSubSampleFactor = round(dblSubSampleToReq*dblSampFreq);
	if isnan(intSubSampleFactor),intSubSampleFactor=0;end
	dblSubSampleTo = intSubSampleFactor/dblSampFreq;
	if isnan(dblSubSampleTo),dblSubSampleTo=0;end
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(intSubSampleFactor));
end 
function ptrPanicButton_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	
	%get global
	global sFig;
	
	%unlock busy & GUI
	sFig.boolIsBusy = false;
	RM_unlock(handles);
	
	%restart timer
	stop(sFig.objTimer);
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @RM_main;
	sFig.objTimer = objTimer;
	start(objTimer);
	
	%update text
	RM_updateTextInformation({''});
	
end
function ptrButtonClearAll_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define globals
	global sFig;
	global sRM;
	
	%stop timer
	stop(sFig.objTimer);
	
	%clear data and reset to defaults
	sRM = struct;
	sRM = RM_populateStructure(sRM);
	sFig = RM_populateFigure(handles,false,sFig);
	
	% set timer to query whether there is a data update every second
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @RM_main;
	sFig.objTimer = objTimer;
	start(objTimer);
	
	%update text
	RM_updateTextInformation({''});
end
function ptrButtonClearAndRecompute_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define global
	global sRM
	
	%save initialization parameter
	IsInitialized = sRM.IsInitialized;
	
	%clear rest
	sRM = struct;
	sRM = RM_populateStructure(sRM);
	sRM.IsInitialized = IsInitialized;
	
	%reload data if initialized
	if IsInitialized
		%lock gui
		RM_lock(handles);
		RM_updateTextInformation({'Data cleared, re-processing data...'});
		
		%run main
		RM_main();
	end
end
