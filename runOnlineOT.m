%% starting function
function varargout = runOnlineOT(varargin)
	% runOnlineOT Online Orientation Tuning
	%
	%	Version 1.0 [2019-04-02]
	%		Created by Jorrit Montijn
	%	Version 1.0.1 [2019-04-11]
	%		Improved high-pass filtering and rewrote for GPU processing
	%	Version 1.0.2 [2019-05-01]
	%		Stepwise data loading to reduce memory load
	%	Version 1.0.3 [2019-05-10]
	%		ENV-support and bug fixes
	%	Version 2.0.0a [2019-10-15]
	%		Neuropixels support with SpikeGLX
	
	%set tags
	%#ok<*INUSL>
	%#ok<*INUSD>
	
	% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @runOnlineOT_OpeningFcn, ...
		'gui_OutputFcn',  @runOnlineOT_OutputFcn, ...
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
function ptrEditDownsample_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonOldFig_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonNewFig_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditHighpassFreq_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrListSelectDataProcessing_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditChannelMin_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditChannelMax_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditHostSGL_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>

%% opening function; initializes output
function runOnlineOT_OpeningFcn(hObject, eventdata, handles, varargin)
	%opening actions
	
	%define globals
	global sFig;
	global sOT;
	
	%set closing function
	set(hObject,'DeleteFcn','OT_DeleteFcn')
	
	% set rainbow logo
	I = imread('OT_mapper-01.jpg');
	axes(handles.ptrAxesLogo);
	imshow(I);
	drawnow;
	
	% set default output
	handles.output = hObject;
	guidata(hObject, handles);
	
	%set default values
	sOT = struct;
	sOT = OT_populateStructure(sOT);
	
	%populate figure
	boolInit = true;
	sFig = OT_populateFigure(handles,boolInit);
	
	% set timer to query whether there is a data update every second
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @OT_main;
	sFig.objTimer = objTimer;
	start(objTimer);
	
	%lock 
	set(sFig.ptrEditHighpassFreq,'UserData','lock');
	set(sFig.ptrEditDownsample,'UserData','lock');
	set(sFig.ptrButtonDataLFP,'UserData','lock')
	set(sFig.ptrButtonDataAP,'UserData','lock')
	set(sFig.ptrEditChannelMin,'UserData','lock');
	set(sFig.ptrEditChannelMax,'UserData','lock');
	set(sFig.ptrButtonScatterYes,'UserData','lock')
	set(sFig.ptrButtonScatterNo,'UserData','lock')
	set(sFig.ptrButtonNewFig,'UserData','lock')
	set(sFig.ptrButtonOldFig,'UserData','lock')
	set(sFig.ptrButtonClearAndRecompute,'UserData','lock')
	set(sFig.ptrListSelectDataProcessing,'UserData','lock');
	set(sFig.ptrListSelectMetric,'UserData','lock');
	set(sFig.ptrListSelectChannel,'UserData','lock')
	
	% Update handles structure
	guidata(hObject, handles);
	
	%check if default host is online
	ptrEditHostSGL_Callback([], [], handles);
end
%% defines output variables
function varargout = runOnlineOT_OutputFcn(hObject, eventdata, handles)
	%output
	varargout{1} = handles.output;
end
%% change in scatter plot
function ptrPanelScatterPlot_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by drawing function, 
	%so no other action is required other than redrawing
	
	%lock GUI
	OT_lock(handles);
	
	%redraw
	OT_redraw(1);
	
	%unlock GUI
	OT_unlock(handles);
end
%% change in target figure
function ptrPanelPlotIn_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by drawing function, 
	%so no other action is required other than redrawing
	
	%lock GUI
	OT_lock(handles);
	
	%redraw
	OT_redraw(1);
	
	%unlock GUI
	OT_unlock(handles);
end
%% change in data type to load
function ptrPanelDataType_SelectionChangedFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%selection is automatically queried by main function, so no other
	%action is required except sending a confirmation message
	
	%get global
	global sFig;
	global sOT;
	if ~isfield(sOT,'hSGL') || ~isempty(sOT.hSGL)
		return;
	end
	
	%lock GUI
	OT_lock(handles);
	
	%get number of channels per type
	vecStreamIM = [0];
	vecChPerType = GetAcqChanCounts(sOT.hSGL, vecStreamIM(1));
	
	%check whether to show AP or LFP
	intLoadLFP = get(sFig.ptrButtonDataLFP,'Value');
	if intLoadLFP == 1 %LFP
		strLoadDataType = 'LFP';
		vecUseChans = sOT.vecAllChans((vecChPerType(1)+1):(vecChPerType(1)+vecChPerType(2)));
	else %AP
		strLoadDataType = 'AP';
		vecUseChans = sOT.vecAllChans(1:vecChPerType(1));
	end
	sOT.vecUseChans = vecUseChans;
	strChanNum = [num2str(sOT.vecUseChans(1)),' - ',num2str(sOT.vecUseChans(end))];

	%fill recording/block data
	set(sFig.ptrTextChanNumIM, 'string', strChanNum);
	
	%update message
	cellText = {['Switched data type to ' strLoadDataType]};
	OT_updateTextInformation(cellText);
	
	%unlock GUI
	OT_unlock(handles);
end
%% select which image to display as background
function ptrListSelectMetric_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%selected image is automatically queried by drawing function; so no
	%other action is required other than redrawing
	
	%lock GUI
	OT_lock(handles);
	
	%redraw
	OT_redraw(1);
	
	%unlock GUI
	OT_unlock(handles);
end
%% this function initializes everything
function ptrEditHostSGL_Callback(hObject, eventdata, handles)
	%This function lets the user select an SGL host
	
	% get globals
	global sFig;
	global sOT;
	
	%lock GUI
	OT_lock(handles);
	
	%clear data
	set(sFig.ptrTextChanNumIM, 'string', '...');
	set(sFig.ptrTextRecording, 'string', '...');
	set(sFig.ptrTextProbe, 'string', '...');
	
	%connect to host
	sOT.strHostSGL = get(sFig.ptrEditHostSGL,'String');
	
	% try connection
	try
		%suppress warnings
		cellText = {};
		cellText{1} = ['Attempting to connect to host at ' sOT.strHostSGL];
		OT_updateTextInformation(cellText);
		sWarn = warning('off');
		sOT.hSGL = SpikeGL(sOT.strHostSGL);
		warning(sWarn);
		cellText{2} = 'Success!';
		OT_updateTextInformation(cellText);
	catch ME
		%unlock GUI
		OT_unlock(handles);
		if strcmp(ME.identifier,'ChkConn:ConnectFail')
			OT_updateTextInformation({['Cannot connect to host at ' sOT.strHostSGL]});
			return;
		else
			%disp error message
			cellText = {};
			cellText{1} = '<< ERROR >>';
			cellText{2} = ME.identifier;
			cellText{3} = ME.message;
			OT_updateTextInformation(cellText);
			rethrow(ME);
		end
	end
	
	%retrieve channels to save; if settings are unvalidated, this will give an error
	try
		warning('off','CalinsNetMex:connectionClosed');
		vecSaveChans = GetSaveChans(sOT.hSGL, 0);
		warning('on','CalinsNetMex:connectionClosed');
	catch ME
		%unlock GUI
		OT_unlock(handles);
		
		%disp error message
		cellText = {};
		cellText{1} = '<< ERROR >>';
		cellText{2} = ME.identifier;
		cellText{3} = ME.message;
		OT_updateTextInformation(cellText);
		warning('on','CalinsNetMex:connectionClosed');
		if contains(ME.message,'Run parameters never validated.')
			%we know what this is; no need to panic
			cellText{4} = '';
			cellText{5} = 'Please verify your settings in SpikeGLX';
			OT_updateTextInformation(cellText);
			return;
		else
			rethrow(ME);
		end
	end
	
	%start run if it's not already running
	boolInitSGL = IsInitialized(sOT.hSGL);
	boolIsRunningSGL = IsRunning(sOT.hSGL);
	if boolInitSGL && ~boolIsRunningSGL
		%start run
		StartRun(sOT.hSGL);
	end
	%set global switch
	sOT.boolInitSGL = true;
	
	% get data
	%set stream IDs
	vecStreamIM = [0];
	intStreamNI = -1;
	
	%get name for this run
	strRecording = GetRunName(sOT.hSGL);
	
	%get probe ID
	[cellSN,vecType] = GetImProbeSN(sOT.hSGL, vecStreamIM(1));
	
	%get number of channels per type
	vecSaveChans = GetSaveChans(sOT.hSGL, vecStreamIM(1));
	vecChPerType = GetAcqChanCounts(sOT.hSGL, vecStreamIM(1));
	if numel(vecSaveChans) ~= sum(vecChPerType)
		%we're not saving all channels... is this correct?
		cellText{end+1} = '';
		cellText{end+1} = '<< WARNING >>';
		cellText{end+1} = sprintf('Only %d/%d available channels are being saved!',numel(vecSaveChans),sum(vecChPerType));
		OT_updateTextInformation(cellText);
		sOT.vecAllChans = 0:(sum(vecChPerType)-1);
	else
		sOT.vecAllChans = vecSaveChans;
	end
	
	%get samp freq
	sOT.dblSampFreq = GetSampleRate(sOT.hSGL, vecStreamIM(1));
	
	%check whether to show AP or LFP
	intLoadLFP = get(sFig.ptrButtonDataLFP,'Value');
	if intLoadLFP == 1 %LFP
		vecUseChans = sOT.vecAllChans((vecChPerType(1)+1):(vecChPerType(1)+vecChPerType(2)));
	else %AP
		vecUseChans = sOT.vecAllChans(1:vecChPerType(1));
	end
	sOT.vecUseChans = vecUseChans;
	strChanNum = [num2str(sOT.vecUseChans(1)),' - ',num2str(sOT.vecUseChans(end))];

	%fill recording/block data
	set(sFig.ptrTextChanNumIM, 'string', strChanNum);
	set(sFig.ptrTextRecording, 'string', strRecording);
	set(sFig.ptrTextProbe, 'string', cellSN{1});
	
	%unlock GUI
	OT_unlock(handles);
	
	
	%check if both data path and stim path is set
	if isfield(sOT,'boolInitSGL') && ~isempty(sOT.boolInitSGL) && sOT.boolInitSGL && ...
			isfield(sOT,'strSourcePathLog') && ~isempty(sOT.strSourcePathLog)
		[sFig,sOT] = OT_initialize(sFig,sOT);
	end
end
function ptrButtonChooseSourceStim_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%This function lets the user select a stim log path
	
	%get globals
	global sFig;
	global sOT;
	
	%lock GUI
	OT_lock(handles);
	
	%switch path
	try
		oldPath = cd(sOT.metaData.strSourcePathLog);
	catch
		oldPath = cd();
	end
	
	%get file
	strSourcePathLog = uigetdir('Select stim log path');
	%back to old path
	cd(oldPath);
	if isempty(strSourcePathLog) || isscalar(strSourcePathLog),OT_unlock(handles);return;end
	if strcmpi(strSourcePathLog(end),filesep)
		strSourcePathLog(end) = [];
	end
	sOT.strSourcePathLog = strSourcePathLog;
	
	%fill recording/block data
	set(sFig.ptrTextStimPath, 'string', strSourcePathLog);
	
	%unlock GUI
	OT_unlock(handles);
	
	%check if connection is active and stim path is set
	if isfield(sOT,'boolInitSGL') && ~isempty(sOT.boolInitSGL) && sOT.boolInitSGL && ...
			isfield(sOT,'strSourcePathLog') && ~isempty(sOT.strSourcePathLog)
		[sFig,sOT] = OT_initialize(sFig,sOT);
	end
end
function ptrListSelectChannel_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%lock GUI
	OT_lock(handles);
	
	% update maps
	OT_redraw(1);
	
	%unlock GUI
	OT_unlock(handles);
end
function ptrListSelectDataProcessing_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%lock GUI
	OT_lock(handles);
	
	% update maps
	OT_redraw(1);
	
	%unlock GUI
	OT_unlock(handles);
end
function ptrEditDownsample_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%get globals
	global sFig;
	global sOT;
	
	%default downsample
	dblSampFreq = sOT.dblSampFreq;
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
	OT_unlock(handles);
	
	%restart timer
	stop(sFig.objTimer);
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @OT_main;
	sFig.objTimer = objTimer;
	start(objTimer);
	
	%update text
	OT_updateTextInformation({''});
	
end
function ptrButtonClearAll_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define globals
	global sFig;
	global sOT;
	
	%stop timer
	stop(sFig.objTimer);
	
	%clear data and reset to defaults
	sOT = struct;
	sOT = OT_populateStructure(sOT);
	sFig = OT_populateFigure(handles,false,sFig);
	
	% set timer to query whether there is a data update every second
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @OT_main;
	sFig.objTimer = objTimer;
	start(objTimer);
	
	%update text
	OT_updateTextInformation({''});
end
function ptrButtonClearAndRecompute_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%define global
	global sOT
	
	%save initialization parameters
	IsInitialized = sOT.IsInitialized;
	UseGPU = sOT.UseGPU;
	
	%clear rest
	sOT = struct;
	sOT = OT_populateStructure(sOT);
	sOT.IsInitialized = IsInitialized;
	sOT.UseGPU = UseGPU;
	
	%reload data if initialized
	if IsInitialized
		%lock gui
		OT_lock(handles);
		OT_updateTextInformation({'Data cleared, re-processing data...'});
		
		%run main
		OT_main();
	end
end



function ptrEditChannelMin_Callback(hObject, eventdata, handles)
% hObject    handle to ptrEditChannelMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ptrEditChannelMin as text
%        str2double(get(hObject,'String')) returns contents of ptrEditChannelMin as a double
end

function ptrEditChannelMax_Callback(hObject, eventdata, handles)
% hObject    handle to ptrEditChannelMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ptrEditChannelMax as text
%        str2double(get(hObject,'String')) returns contents of ptrEditChannelMax as a double
end




