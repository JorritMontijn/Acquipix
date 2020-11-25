%% starting function
function varargout = runOnlineRF(varargin)
	% runOnlineRF Online Receptive Field mapping
	%
	%	Version 1.0 [2019-04-02]
	%		Created for TDT NeuroNexus recordings by Jorrit Montijn
	%	Version 1.0.1 [2019-04-11]
	%		Improved high-pass filtering and rewrote for GPU processing
	%	Version 1.0.2 [2019-05-01]
	%		Stepwise data loading to reduce memory load
	%	Version 1.0.3 [2019-05-10]
	%		ENV-support and bug fixes
	%	Version 2.0.0a [2020-11-19]
	%		Neuropixels support with SpikeGLX
	%	Version 2.0.0b [2020-11-24]
	%		Attempted bug fix
	%	Version 2.0.1 [2020-11-25]
	%		Bug fixes
	%		Added optional smoothing
	%		Added scatter plot of RF per channel
	
	%set tags
	%#ok<*INUSL>
	%#ok<*INUSD>
	
	% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @runOnlineRF_OpeningFcn, ...
		'gui_OutputFcn',  @runOnlineRM_OutputFcn, ...
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
function ptrListSelectMetric_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditHighpassFreq_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrListSelectChannel_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrListSelectProbe_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditDownsample_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonOldFig_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonNewFig_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditHighpassFreq_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrListSelectDataProcessing_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditChannelMin_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditChannelMax_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditHostSGL_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditStimSyncNI_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>

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
	set(sFig.ptrEditChannelMin,'UserData','lock');
	set(sFig.ptrEditChannelMax,'UserData','lock');
	set(sFig.ptrButtonScatterYes,'UserData','lock')
	set(sFig.ptrButtonScatterNo,'UserData','lock')
	set(sFig.ptrButtonNewFig,'UserData','lock')
	set(sFig.ptrButtonOldFig,'UserData','lock')
	set(sFig.ptrButtonClearAll,'UserData','lock')
	set(sFig.ptrListSelectProbe,'UserData','lock');
	set(sFig.ptrListSelectDataProcessing,'UserData','lock');
	set(sFig.ptrListSelectMetric,'UserData','lock');
	set(sFig.ptrListSelectChannel,'UserData','lock')
	
	% Update handles structure
	guidata(hObject, handles);
	
	%check if default host is online
	ptrEditHostSGL_Callback([], [], handles);
end
%% defines output variables
function varargout = runOnlineRM_OutputFcn(hObject, eventdata, handles)
	%output
	varargout{1} = handles.output;
end
%% change in scatter plot
function ptrPanelScatterPlot_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by drawing function, 
	%so no other action is required other than redrawing
	
	%lock GUI
	RM_lock(handles);
	
	%redraw
	RM_redraw(1);
	
	%unlock GUI
	RM_unlock(handles);
end
%% change in target figure
function ptrPanelPlotIn_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by drawing function, 
	%so no other action is required other than redrawing
	
	%lock GUI
	RM_lock(handles);
	
	%redraw
	RM_redraw(1);
	
	%unlock GUI
	RM_unlock(handles);
end
%% select which image to display as background
function ptrListSelectMetric_Callback(hObject, eventdata, handles) %#ok<DEFNU>
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
function ptrEditHostSGL_Callback(hObject, eventdata, handles)
	%This function lets the user select an SGL host
	
	% get globals
	global sFig;
	global sRM;
	
	%lock GUI
	RM_lock(handles);
	
	%clear data
	set(sFig.ptrTextChanNumIM, 'string', '...');
	set(sFig.ptrTextRecording, 'string', '...');
	set(sFig.ptrListSelectProbe, 'string', {''});
	
	%connect to host
	sRM.strHostSGL = get(sFig.ptrEditHostSGL,'String');
	
	% try connection
	try
		%suppress warnings
		cellText = {};
		cellText{1} = ['Attempting to connect to host at ' sRM.strHostSGL];
		RM_updateTextInformation(cellText);
		sWarn = warning('off');
		sRM.hSGL = SpikeGL(sRM.strHostSGL);
		warning(sWarn);
		RM_updateTextInformation('Success!');
	catch ME
		%unlock GUI
		RM_unlock(handles);
		if strcmp(ME.identifier,'ChkConn:ConnectFail')
			RM_updateTextInformation({['Cannot connect to host at ' sRM.strHostSGL]});
			return;
		else
			%disp error message
			cellText = {};
			cellText{1} = '<< ERROR >>';
			cellText{2} = ME.identifier;
			cellText{3} = ME.message;
			RM_updateTextInformation(cellText);
			rethrow(ME);
		end
	end
	
	%retrieve channels to save; if settings are unvalidated, this will give an error
	try
		warning('off','CalinsNetMex:connectionClosed');
		vecSaveChans = GetSaveChans(sRM.hSGL, 0);
		warning('on','CalinsNetMex:connectionClosed');
	catch ME
		%unlock GUI
		RM_unlock(handles);
		
		%disp error message
		cellText = {};
		cellText{1} = '<< ERROR >>';
		cellText{2} = ME.identifier;
		cellText{3} = ME.message;
		RM_updateTextInformation(cellText);
		warning('on','CalinsNetMex:connectionClosed');
		if contains(ME.message,'Run parameters never validated.')
			%we know what this is; no need to panic
			cellText{4} = '';
			cellText{5} = 'Please verify your settings in SpikeGLX';
			RM_updateTextInformation(cellText);
			return;
		else
			rethrow(ME);
		end
	end
	
	%initialize connection with SGL
	[sFig,sRM] = RM_initSGL(sFig,sRM);
	
	%unlock GUI
	RM_unlock(handles);
	
	
	%check if both data path and stim path is set
	if isfield(sRM,'boolInitSGL') && ~isempty(sRM.boolInitSGL) && sRM.boolInitSGL && ...
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
	
	%check if connection is active and stim path is set
	if isfield(sRM,'boolInitSGL') && ~isempty(sRM.boolInitSGL) && sRM.boolInitSGL && ...
			isfield(sRM,'strSourcePathLog') && ~isempty(sRM.strSourcePathLog)
		[sFig,sRM] = RM_initialize(sFig,sRM);
	end
end
function ptrListSelectProbe_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%get globals
	global sFig;
	global sRM;
	
	%lock GUI
	RM_lock(handles);
	
	% update maps
	[sFig,sRM] = RM_initSGL(sFig,sRM);
	
	%unlock GUI
	RM_unlock(handles);
end
function ptrListSelectChannel_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%lock GUI
	RM_lock(handles);
	
	% update maps
	RM_redraw(1);
	
	%unlock GUI
	RM_unlock(handles);
end
function ptrListSelectDataProcessing_Callback(hObject, eventdata, handles) %#ok<DEFNU>
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
	
	%downsample
	dblSampFreqIM = sRM.dblSampFreqIM;
	dblSampFreqNI = sRM.dblSampFreqNI;
	dblSubSampleToReq = str2double(get(sFig.ptrEditDownsample,'String'));
	sRM.intSubSampleFactorIM = round(dblSubSampleToReq*dblSampFreqIM);
	if isnan(sRM.intSubSampleFactorIM),sRM.intSubSampleFactorIM=0;end
	sRM.dblSubSampleTo = sRM.intSubSampleFactorIM/dblSampFreqIM;
	if isnan(sRM.dblSubSampleTo),sRM.dblSubSampleTo=0;end
	sRM.dblSubSampleFactorNI = dblSubSampleTo/dblSampFreqNI;
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(intSubSampleFactorIM));
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
	global sRM;
	global sFig;
	
	%save initialization parameters
	IsInitialized = sRM.IsInitialized;
	UseGPU = sRM.UseGPU;
	
	%clear rest
	sRM = struct;
	sRM = RM_populateStructure(sRM);
	sRM.IsInitialized = IsInitialized;
	sRM.UseGPU = UseGPU;
	
	%reload data if initialized
	if IsInitialized
		%lock gui
		RM_lock(handles);
		RM_updateTextInformation({'Data cleared, re-processing data...'});
		
		%connect to host
		sRM.strHostSGL = get(sFig.ptrEditHostSGL,'String');
		sRM.hSGL = SpikeGL(sRM.strHostSGL);
		
		%re-establish connection
		[sFig,sRM] = RM_initSGL(sFig,sRM);
		
		%reinitialize
		[sFig,sRM] = RM_initialize(sFig,sRM);
		 
		%run main
		RM_main();
	end
end
function ptrEditChannelMin_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define globals
	global sRM;
	global sFig;
	
	%lock gui
	RM_lock(handles);
		
	%get data
	intMinChan = str2double(get(hObject,'String'));
	strMsg = '';
	
	%check range
	if intMinChan < 1
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMinChan));
		intMinChan = 1;
	end
	if intMinChan > numel(sRM.vecUseChans)
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMinChan));
		intMinChan = numel(sRM.vecUseChans);
	end
	strMsg = strcat(strMsg,sprintf('Min chan set to %d',intMinChan));
	
	%assign to global
	sRM.intMinChan = intMinChan;
	set(hObject,'String',num2str(intMinChan));
	
	%update msg
	RM_updateTextInformation({strMsg});
		
	%unlock gui
	RM_unlock(handles);
end

function ptrEditChannelMax_Callback(hObject, eventdata, handles) %#ok<DEFNU>
%define globals
	global sRM;
	global sFig;
	
	%lock gui
	RM_lock(handles);
		
	%get data
	intMaxChan = str2double(get(hObject,'String'));
	strMsg = '';
	
	%check range
	if intMaxChan < 1
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMaxChan));
		intMaxChan = 1;
	end
	if intMaxChan > numel(sRM.vecUseChans)
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMaxChan));
		intMaxChan = numel(sRM.vecUseChans);
	end
	strMsg = strcat(strMsg,sprintf('Max chan set to %d',intMaxChan));
	
	%assign to global
	sRM.intMaxChan = intMaxChan;
	set(hObject,'String',num2str(intMaxChan));
	
	%update msg
	RM_updateTextInformation({strMsg});
		
	%unlock gui
	RM_unlock(handles);
end
function ptrEditStimSyncNI_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%get globals
	global sRM;
	
	%lock GUI
	RM_lock(handles);
	
	%get channel
	intStimSyncChanNI = str2double(get(hObject,'String'));
	
	%check if channel lies within range of NI channels
	vecSaveChans = GetSaveChans(sRM.hSGL, -1);
	if ~ismember(intStimSyncChanNI,vecSaveChans)
		cellText = {'<< WARNING >>','',sprintf('Sync channel %d is out of NI channel range',intStimSyncChanNI)};
	else
		cellText = {sprintf('Changing stim sync channel to %d',intStimSyncChanNI)};
	end
	RM_updateTextInformation(cellText);
	
	%assign new channel ID
	sRM.intStimSyncChanNI = intStimSyncChanNI;
	
	%unlock GUI
	RM_unlock(handles);
end
