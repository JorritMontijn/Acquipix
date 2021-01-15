%% starting function
function varargout = runOnlineNM(varargin)
	% runOnlineNM Natural Movie response mapping
	%
	%	Version 0.1 [2020-11-27]
	%		Split from RF/OT mappers for natural movies
	%	Version 1.0 [2020-11-30]
	%		Finished & tested; NM mapper based on z-score ANOVAs
	
	%set tags
	%#ok<*INUSL>
	%#ok<*INUSD>
	
	% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @runOnlineNM_OpeningFcn, ...
		'gui_OutputFcn',  @runOnlineNM_OutputFcn, ...
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
function runOnlineNM_OpeningFcn(hObject, eventdata, handles, varargin)
	%opening actions
	
	%define globals
	global sFig;
	global sNM;
	
	%set closing function
	set(hObject,'DeleteFcn','SC_DeleteFcn')
	
	% set rainbow logo
	I = imread('NM_mapper.jpg');
	axes(handles.ptrAxesLogo);
	imshow(I);
	drawnow;
	
	% set default output
	handles.output = hObject;
	guidata(hObject, handles);
	
	%set default values
	sNM = struct;
	sNM = NM_populateStructure(sNM);
	
	%populate figure
	boolInit = true;
	sFig = SC_populateFigure(handles,boolInit);
	
	% set timer to query whether there is a data update every second
	objMainTimer = timer();
	objMainTimer.Period = 1;
	objMainTimer.StartDelay = 1;
	objMainTimer.ExecutionMode = 'fixedSpacing';
	objMainTimer.TimerFcn = @NM_main;
	sFig.objMainTimer = objMainTimer;
	start(objMainTimer);
	
	% set timer to update plots
	objDrawTimer = timer();
	objDrawTimer.Period = 1;
	objDrawTimer.StartDelay = 1;
	objDrawTimer.ExecutionMode = 'fixedSpacing';
	objDrawTimer.TimerFcn = @NM_redraw;
	sFig.objDrawTimer = objDrawTimer;
	start(objDrawTimer);
	
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
function varargout = runOnlineNM_OutputFcn(hObject, eventdata, handles)
	%output
	varargout{1} = handles.output;
end
%% change in scatter plot
function ptrPanelScatterPlot_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by drawing function, 
	%so no other action is required other than redrawing
	
	%lock GUI
	SC_lock(handles);
	
	%redraw
	NM_redraw(1);
	
	%unlock GUI
	SC_unlock(handles);
end
%% change in target figure
function ptrPanelPlotIn_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by drawing function, 
	%so no other action is required other than redrawing
	
	%lock GUI
	SC_lock(handles);
	
	%redraw
	NM_redraw(1);
	
	%unlock GUI
	SC_unlock(handles);
end
%% select which image to display as background
function ptrListSelectMetric_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%selected image is automatically queried by drawing function; so no
	%other action is required other than redrawing
	
	%lock GUI
	SC_lock(handles);
	
	%redraw
	NM_redraw(1);
	
	%unlock GUI
	SC_unlock(handles);
end
%% this function initializes everything
function ptrEditHostSGL_Callback(hObject, eventdata, handles)
	%This function lets the user select an SGL host
	
	% get globals
	global sFig;
	global sNM;
	
	%lock GUI
	SC_lock(handles);
	
	%clear data
	set(sFig.ptrTextChanNumIM, 'string', '...');
	set(sFig.ptrTextRecording, 'string', '...');
	set(sFig.ptrListSelectProbe, 'string', {''});
	
	%connect to host
	sNM.strHostSGL = get(sFig.ptrEditHostSGL,'String');
	
	% try connection
	try
		%suppress warnings
		cellText = {};
		cellText{1} = ['Attempting to connect to host at ' sNM.strHostSGL];
		SC_updateTextInformation(cellText);
		sWarn = warning('off');
		sNM.hSGL = SpikeGL(sNM.strHostSGL);
		warning(sWarn);
		SC_updateTextInformation('Success!');
	catch ME
		%unlock GUI
		SC_unlock(handles);
		if strcmp(ME.identifier,'ChkConn:ConnectFail')
			SC_updateTextInformation({['Cannot connect to host at ' sNM.strHostSGL]});
			return;
		else
			%disp error message
			cellText = {};
			cellText{1} = '<< ERROR >>';
			cellText{2} = ME.identifier;
			cellText{3} = ME.message;
			SC_updateTextInformation(cellText);
			rethrow(ME);
		end
	end
	
	%retrieve channels to save; if settings are unvalidated, this will give an error
	try
		warning('off','CalinsNetMex:connectionClosed');
		vecSaveChans = GetSaveChans(sNM.hSGL, 0); %#ok<NASGU>
		warning('on','CalinsNetMex:connectionClosed');
	catch ME
		%unlock GUI
		SC_unlock(handles);
		
		%disp error message
		cellText = {};
		cellText{1} = '<< ERROR >>';
		cellText{2} = ME.identifier;
		cellText{3} = ME.message;
		SC_updateTextInformation(cellText);
		warning('on','CalinsNetMex:connectionClosed');
		if contains(ME.message,'Run parameters never validated.')
			%we know what this is; no need to panic
			cellText{4} = '';
			cellText{5} = 'Please verify your settings in SpikeGLX';
			SC_updateTextInformation(cellText);
			return;
		else
			rethrow(ME);
		end
	end
	
	%initialize connection with SGL
	[sFig,sNM] = SC_initSGL(sFig,sNM);
	
	%unlock GUI
	SC_unlock(handles);
	
	
	%check if both data path and stim path is set
	if isfield(sNM,'boolInitSGL') && ~isempty(sNM.boolInitSGL) && sNM.boolInitSGL && ...
			isfield(sNM,'strSourcePathLog') && ~isempty(sNM.strSourcePathLog)
		[sFig,sNM] = SC_initialize(sFig,sNM);
	end
end
function ptrButtonChooseSourceStim_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%This function lets the user select a stim log path
	
	%get globals
	global sFig;
	global sNM;
	
	%lock GUI
	SC_lock(handles);
	
	%switch path
	try
		oldPath = cd(sNM.metaData.strSourcePathLog);
	catch
		oldPath = cd();
	end
	
	%get file
	strSourcePathLog = uigetdir('Select stim log path');
	%back to old path
	cd(oldPath);
	if isempty(strSourcePathLog) || isscalar(strSourcePathLog),SC_unlock(handles);return;end
	if strcmpi(strSourcePathLog(end),filesep)
		strSourcePathLog(end) = [];
	end
	sNM.strSourcePathLog = strSourcePathLog;
	
	%fill recording/block data
	set(sFig.ptrTextStimPath, 'string', strSourcePathLog);
	
	%unlock GUI
	SC_unlock(handles);
	
	%check if connection is active and stim path is set
	if isfield(sNM,'boolInitSGL') && ~isempty(sNM.boolInitSGL) && sNM.boolInitSGL && ...
			isfield(sNM,'strSourcePathLog') && ~isempty(sNM.strSourcePathLog)
		[sFig,sNM] = SC_initialize(sFig,sNM);
	end
end
function ptrListSelectProbe_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%get globals
	global sFig;
	global sNM;
	
	%lock GUI
	SC_lock(handles);
	
	% update maps
	[sFig,sNM] = SC_initSGL(sFig,sNM);
	
	%unlock GUI
	SC_unlock(handles);
end
function ptrListSelectChannel_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%lock GUI
	SC_lock(handles);
	
	% update maps
	NM_redraw(1);
	
	%unlock GUI
	SC_unlock(handles);
end
function ptrListSelectDataProcessing_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%lock GUI
	SC_lock(handles);
	
	% update maps
	NM_redraw(1);
	
	%unlock GUI
	SC_unlock(handles);
end
function ptrEditDownsample_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%get globals
	global sFig;
	global sNM;
	
	%downsample
	dblSampFreqIM = sNM.dblSampFreqIM;
	dblSampFreqNI = sNM.dblSampFreqNI;
	dblSubSampleToReq = str2double(get(sFig.ptrEditDownsample,'String'));
	sNM.intSubSampleFactorIM = round(dblSubSampleToReq*dblSampFreqIM);
	if isnan(sNM.intSubSampleFactorIM),sNM.intSubSampleFactorIM=0;end
	sNM.dblSubSampleTo = sNM.intSubSampleFactorIM/dblSampFreqIM;
	if isnan(sNM.dblSubSampleTo),sNM.dblSubSampleTo=0;end
	sNM.dblSubSampleFactorNI = dblSubSampleTo/dblSampFreqNI;
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(intSubSampleFactorIM));
end 
function ptrPanicButton_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	
	%get global
	global sFig;
	
	%unlock busy & GUI
	sFig.boolIsBusy = false;
	SC_unlock(handles);
	
	%restart timer
	stop(sFig.objMainTimer);
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @NM_main;
	sFig.objMainTimer = objTimer;
	start(objTimer);
	
	%update text
	SC_updateTextInformation({''});
	
end
function ptrButtonClearAll_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define globals
	global sFig;
	global sNM;
	
	%stop timer
	stop(sFig.objMainTimer);
	
	%clear data and reset to defaults
	sNM = struct;
	sNM = NM_populateStructure(sNM);
	sFig = SC_populateFigure(handles,false,sFig);
	
	% set timer to query whether there is a data update every second
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @NM_main;
	sFig.objMainTimer = objTimer;
	start(objTimer);
	
	%update text
	SC_updateTextInformation({''});
	
	%check if default host is online
	ptrEditHostSGL_Callback([], [], handles);
end
function ptrButtonClearAndRecompute_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define global
	global sNM;
	global sFig;
	
	%save initialization parameters
	IsInitialized = sNM.IsInitialized;
	UseGPU = sNM.UseGPU;
	
	%clear rest
	sNM = struct;
	sNM = NM_populateStructure(sNM);
	sNM.IsInitialized = IsInitialized;
	sNM.UseGPU = UseGPU;
	
	%reload data if initialized
	if IsInitialized
		%lock gui
		SC_lock(handles);
		SC_updateTextInformation({'Data cleared, re-processing data...'});
		
		%connect to host
		sNM.strHostSGL = get(sFig.ptrEditHostSGL,'String');
		sNM.hSGL = SpikeGL(sNM.strHostSGL);
		
		%re-establish connection
		[sFig,sNM] = SC_initSGL(sFig,sNM);
		
		%reinitialize
		[sFig,sNM] = SC_initialize(sFig,sNM);
		 
		%run main
		NM_main();
	end
end
function ptrEditChannelMin_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define globals
	global sNM;
	global sFig;
	
	%lock gui
	SC_lock(handles);
		
	%get data
	intMinChan = str2double(get(hObject,'String'));
	strMsg = '';
	
	%check range
	if intMinChan < 1
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMinChan));
		intMinChan = 1;
	end
	if intMinChan > numel(sNM.vecUseChans)
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMinChan));
		intMinChan = numel(sNM.vecUseChans);
	end
	strMsg = strcat(strMsg,sprintf('Min chan set to %d',intMinChan));
	
	%assign to global
	sNM.intMinChan = intMinChan;
	set(hObject,'String',num2str(intMinChan));
	
	%update msg
	SC_updateTextInformation({strMsg});
		
	%unlock gui
	SC_unlock(handles);
end

function ptrEditChannelMax_Callback(hObject, eventdata, handles) %#ok<DEFNU>
%define globals
	global sNM;
	global sFig;
	
	%lock gui
	SC_lock(handles);
		
	%get data
	intMaxChan = str2double(get(hObject,'String'));
	strMsg = '';
	
	%check range
	if intMaxChan < 1
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMaxChan));
		intMaxChan = 1;
	end
	if intMaxChan > numel(sNM.vecUseChans)
		strMsg = strcat(strMsg,sprintf('%d is out of range; ',intMaxChan));
		intMaxChan = numel(sNM.vecUseChans);
	end
	strMsg = strcat(strMsg,sprintf('Max chan set to %d',intMaxChan));
	
	%assign to global
	sNM.intMaxChan = intMaxChan;
	set(hObject,'String',num2str(intMaxChan));
	
	%update msg
	SC_updateTextInformation({strMsg});
		
	%unlock gui
	SC_unlock(handles);
end
function ptrEditStimSyncNI_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%get globals
	global sNM;
	
	%lock GUI
	SC_lock(handles);
	
	%get channel
	intStimSyncChanNI = str2double(get(hObject,'String'));
	
	%check if channel lies within range of NI channels
	vecSaveChans = GetSaveChans(sNM.hSGL, -1);
	if ~ismember(intStimSyncChanNI,vecSaveChans)
		cellText = {'<< WARNING >>','',sprintf('Sync channel %d is out of NI channel range',intStimSyncChanNI)};
	else
		cellText = {sprintf('Changing stim sync channel to %d',intStimSyncChanNI)};
	end
	SC_updateTextInformation(cellText);
	
	%assign new channel ID
	sNM.intStimSyncChanNI = intStimSyncChanNI;
	
	%unlock GUI
	SC_unlock(handles);
end
