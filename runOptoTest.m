function varargout = runOptoTest(varargin)
	% RUNOPTOTEST MATLAB code for runOptoTest.fig
	%      RUNOPTOTEST, by itself, creates a new RUNOPTOTEST or raises the existing
	%      singleton*.
	%
	%      H = RUNOPTOTEST returns the handle to a new RUNOPTOTEST or the handle to
	%      the existing singleton*.
	%
	%      RUNOPTOTEST('CALLBACK',hObject,eventData,handles,...) calls the local
	%      function named CALLBACK in RUNOPTOTEST.M with the given input arguments.
	%
	%      RUNOPTOTEST('Property','Value',...) creates a new RUNOPTOTEST or raises the
	%      existing singleton*.  Starting from the left, property value pairs are
	%      applied to the GUI before runOptoTest_OpeningFcn gets called.  An
	%      unrecognized property name or invalid value makes property application
	%      stop.  All inputs are passed to runOptoTest_OpeningFcn via varargin.
	%
	%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
	%      instance to run (singleton)".
	%
	% See also: GUIDE, GUIDATA, GUIHANDLES
	
	% Edit the above text to modify the response to help runOptoTest
	
	% Last Modified by GUIDE v2.5 28-Aug-2020 15:12:21
	
	% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @runOptoTest_OpeningFcn, ...
		'gui_OutputFcn',  @runOptoTest_OutputFcn, ...
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
% --- Executes just before runOptoTest is made visible.
function runOptoTest_OpeningFcn(hObject, eventdata, handles, varargin)
	% This function has no output args, see OutputFcn.
	% hObject    handle to figure
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	% varargin   command line arguments to runOptoTest (see VARARGIN)
	
	% Choose default command line output for runOptoTest
	handles.output = hObject;
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% process input
	if ~exist('intUseDevice','var') || isempty(intUseDevice)
		intUseDevice = 1;
	end
	if ~exist('dblSampRate','var') || isempty(dblSamplingRate)
		dblSamplingRate = 10000;
	end
	if ~exist('dblPrePost','var') || isempty(dblPrePost)
		dblPrePost = 0.1;
	end
	
	%% setup connection
	global sOptoTest
	
	if intUseDevice == 0
		objDaqOut = [];
	else
		%query connected devices
		objDevice = daq.getDevices;
		strCard = objDevice.Model;
		strID = objDevice.ID;
		
		%create connection
		objDaqOut = daq.createSession(objDevice(intUseDevice).Vendor.ID);
		
		%set variables
		objDaqOut.IsContinuous = true;
		objDaqOut.Rate=round(dblSamplingRate); %1ms precision
		objDaqOut.NotifyWhenScansQueuedBelow = 100;
		
		%add opto LED output channels
		[chOut1,dblIdx1] = addAnalogOutputChannel(objDaqOut, strID, 'ao1', 'Voltage');
	end
	%set global variables
	sOptoTest.objDaqOut = objDaqOut;
	sOptoTest.dblSamplingRate = dblSamplingRate;
	sOptoTest.dblPrePost = dblPrePost;
end
% --- Outputs from this function are returned to the command line.
function varargout = runOptoTest_OutputFcn(hObject, eventdata, handles)
	% varargout  cell array for returning output args (see VARARGOUT);
	% hObject    handle to figure
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Get default command line output from handles structure
	varargout{1} = handles.output;
end
%% useless creation functions
function ptrEditVolt_CreateFcn(hObject, eventdata, handles),end
function ptrEditFreq_CreateFcn(hObject, eventdata, handles),end
function ptrEditDur_CreateFcn(hObject, eventdata, handles),end
function ptrEditRep_CreateFcn(hObject, eventdata, handles),end

%% text edit callbacks
function ptrEditVolt_Callback(hObject, eventdata, handles)
	%check input
	dblMin = -5;
	dblMax = 5;
	dblDef = 3;
	dblIn = CheckInput(hObject.String,dblMin,dblMax,dblDef);
	set(hObject,'String',num2str(dblIn));
end
function ptrEditFreq_Callback(hObject, eventdata, handles)
	%check input
	dblMin = 0.1;
	dblMax = 1000;
	dblDef = 20;
	dblIn = CheckInput(hObject.String,dblMin,dblMax,dblDef);
	set(hObject,'String',num2str(dblIn));
end
function ptrEditDur_Callback(hObject, eventdata, handles)
	%check input
	dblMin = 0.1;
	dblMax = 1000;
	dblDef = 5;
	dblIn = CheckInput(hObject.String,dblMin,dblMax,dblDef);
	set(hObject,'String',num2str(dblIn));
end

function ptrEditRep_Callback(hObject, eventdata, handles)
	%check input
	dblMin = 1;
	dblMax = 100;
	dblDef = 5;
	dblIn = CheckInput(hObject.String,dblMin,dblMax,dblDef);
	set(hObject,'String',num2str(dblIn));
end
function dblIn = CheckInput(strIn,dblMin,dblMax,dblDef)
	dblIn = str2double(strIn);
	if isempty(dblIn) || ~isnumeric(dblIn)
		dblIn = dblDef;
	elseif dblIn < dblMin
		dblIn = dblMin;
	elseif dblIn > dblMax
		dblIn = dblMax;
	end
end
%% pulse button
function ptrButtonPulse_Callback(hObject, eventdata, handles)
	% hObject    handle to ptrButtonPulse (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	%get globals
	global sOptoTest
	dblSamplingRate = sOptoTest.dblSamplingRate;
	dblPrePost = sOptoTest.dblPrePost;
	objDaqOut = sOptoTest.objDaqOut;
	
	%get parameters
	intRep = round(str2double(handles.ptrEditRep.String));
	dblDur = str2double(handles.ptrEditDur.String)/1000;
	dblFreq = str2double(handles.ptrEditFreq.String);
	dblVolt = str2double(handles.ptrEditVolt.String);
	
	%generate pulse
	dblITI = 1/dblFreq;
	vecPrePost = zeros(round(dblPrePost*dblSamplingRate),1);
	
	vecOnePulse = cat(1,ones(round(dblDur*dblSamplingRate),1),zeros(round(dblITI*dblSamplingRate),1));
	vecPulses = repmat(vecOnePulse,[intRep 1]);
	vecData = dblVolt*cat(1,vecPrePost,vecPulses,vecPrePost);
	
	%block button
	set(hObject,'Enable','off','String','Zapping...','BackgroundColor',[0.6667    0.8167    0.9133],'ForegroundColor','white');
	
	%send pulse
	if isempty(objDaqOut)
		numel(vecData)/dblSamplingRate
		pause(numel(vecData)/dblSamplingRate);
	else
		stop(objDaqOut);
		queueOutputData(objDaqOut,vecData);
		prepare(objDaqOut);
		startBackground(objDaqOut);
		wait(objDaqOut);
	end
	
	%re-enable button
	set(hObject,'Enable','on','String','Zap!','BackgroundColor',[1 1 1],'ForegroundColor',[0 0.45 0.74]);
	
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

	%get globals
	global sOptoTest
	objDaqOut = sOptoTest.objDaqOut;
	
	%close connection
	try
	queueOutputData(objDaqOut,0);
	startBackground(objDaqOut);
	pause(0.1);
	catch
	end
	
	%% close connection
	try,stop(objDaqOut);catch,end
end