%function structEP = RunDriftingGratings

%% suppress m-lint warnings
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>
clear all;
close all;

%% define variables
intStimSet = 1;% 1=0:15:359, reps20; 2=[0 5 90 95], reps 400 with noise
boolUseSGL = true;
intUseDaqDevice = 1; %set to 0 to skip I/O
intDebug = 0;
boolDaqIn = false;

%% set parameters
%
% 1) one "test" protocol, where we can test a) whether there is a response, b) which light intensity we need.
%I would make the pulse 5ms long, but maybe its good to also have longer pulses to be flexible (10ms, 20ms, 100ms, 500ms).
%vecPulseDur =

if intStimSet == 1
	%2) Pulse trains (as discussed)
	%--> 5 pulses, each 5ms long, varying intervals between the pulses according to the frequency
	%Frequencies: 1Hz, 2Hz, 5Hz, 10Hz, 20Hz, 50Hz, 100Hz
	%After each pulse train 10s pause
	%Can run up to 500 trials (as discussed it should repeat the frequencies in a row and then start at 1Hz again) or until stopped
	
	dblPulseVoltage = 3;%volts
	dblPrePostWait = 2;%secs
	dblSamplingRate = 10000;%Hz
	intRepsPerPulse = 5;%count
	intTrialNum = 40;%count
	dblPulseWait = 2;%secs, at least ~0.2s
	vecPulseITI = 1./[1 2 5 10 20 50];%secs
	dblPulseDur = 10/1000;%secs
	vecPulseDur = dblPulseDur*ones(size(vecPulseITI));%secs
	dblPulseWaitSignal = dblPulseWait/2;
	dblPulseWaitPause = dblPulseWait - dblPulseWaitSignal;
end

%% generate data & pre-allocate
cellPulseData = cell(1,intTrialNum);
cellPulseITI = cell(1,intTrialNum);
cellPulseDur = cell(1,intTrialNum);
vecPulseVolt = nan(1,intTrialNum);
vecStimOnNI = nan(1,intTrialNum);
vecStimOffNI = nan(1,intTrialNum);
for intTrial=1:intTrialNum
	%shuffle order
	vecRand = randperm(numel(vecPulseITI));
	vecShuffITI = vecPulseITI(vecRand);
	vecShuffDur = vecPulseDur(vecRand);
	vecData = logical([]);
	
	for intPulseType=1:numel(vecShuffITI)
		vecOnePulse = cat(1,true(round(vecShuffDur(intPulseType)*dblSamplingRate),1),false(round(vecShuffITI(intPulseType)*dblSamplingRate),1));
		vecPulses = repmat(vecOnePulse,[intRepsPerPulse 1]);
		vecWait = false(round(dblSamplingRate*dblPulseWaitSignal),1);
		vecData = cat(1,vecData,vecPulses,vecWait);
	end
	vecPulseVolt(intTrial) = dblPulseVoltage;
	cellPulseData{intTrial} = vecData;
	cellPulseITI{intTrial} = vecShuffITI;
	cellPulseDur{intTrial} = vecShuffDur;
end
%% define paths
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
strSessionDir = strcat('C:\_Data\Exp',getDate()); %where are the logs saved?

%% query user input for recording name
fprintf('Starting %s at [%s]\n',mfilename,getTime);
strRecording = input('Recording name (e.g., MouseX): ', 's');
c = clock;
strFilename = sprintf('%04d%02d%02d_%s_%s',c(1),c(2),c(3),strRecording,mfilename);

%% initialize connection with SpikeGLX
if boolUseSGL
	%start connection
	fprintf('Opening SpikeGLX connection & starting recording "%s" [%s]...\n',strRecording,getTime);
	[hSGL,strFilename,sParamsSGL] = InitSGL(strRecording,strFilename);
	fprintf('Recording started, saving output to "%s.mat" [%s]...\n',strFilename,getTime);
	
	%retrieve some parameters
	intStreamNI = -1;
	dblSampFreqNI = GetSampleRate(hSGL, intStreamNI);
	
	%% check disk space available
	strDataDirSGL = GetDataDir(hSGL);
	jFileObj = java.io.File(strDataDirSGL);
	dblFreeB = jFileObj.getFreeSpace;
	dblFreeGB = dblFreeB/(1024^3);
	if dblFreeGB < 100
		warning([mfilename ':LowDiskSpace'],'Low disk space available (%.0fGB) for Neuropixels data (dir: %s)',dblFreeGB,strDataDirSGL);
	end
else
	sParamsSGL = struct;
end

%% set output locations for logs
try
	%define output filename
	strThisDir = which(mfilename);
	intOffset = length(mfilename) + 2;
	strDir = strThisDir(1:end-intOffset);
	fprintf('Saving output in directory %s; \n',strSessionDir);
	if isa(strFilename,'char') && ~isempty(strFilename)
		%make directory
		strOutputDir = strcat(strSessionDir,filesep,strRecording,filesep); %where are the logs saved?
		if ~exist(strOutputDir,'dir')
			mkdir(strOutputDir);
		end
		strOldPath = cd(strOutputDir);
		%check if file does not exist
		if exist([strOutputDir filesep strFilename],'file') || exist([strOutputDir filesep strFilename '.mat'],'file')
			error([mfilename ':PathExists'],'File "%s" already exists!',strFilename);
		end
	end
catch
	if boolUseSGL,CloseSGL(hSGL);end
end

%% general parameters
fprintf('Preparing variables...\n');
%general variable definitions
structEP = struct; %structureElectroPhysiology

%assign filename
structEP.strFile = mfilename;

%screen params
structEP.debug = intDebug;

%% stimulus params
%visual space parameters
sStimParamsSettings = struct;
sStimParamsSettings.strStimType = 'OptoNora';

%% initialize NI I/O box
if intUseDaqDevice > 0
	%% setup connection
	%query connected devices
	objDevice = daq.getDevices;
	strCard = objDevice.Model;
	strID = objDevice.ID;
	
	%create connection
	objDAQOut = daq.createSession(objDevice(intUseDaqDevice).Vendor.ID);
	
	%set variables
	objDAQOut.IsContinuous = true;
	objDAQOut.Rate=round(dblSamplingRate); %1ms precision
	objDAQOut.NotifyWhenScansQueuedBelow = 100;
	
	%add picospritzer output channels
	%[chOut0,dblIdx0] = addAnalogOutputChannel(objDAQOut, strID, 'ao0', 'Voltage');
	
	%add opto LED output channels
	[chOut1,dblIdx1] = addAnalogOutputChannel(objDAQOut, strID, 'ao1', 'Voltage');
	
	%% set spritzer off
	dblStartT = 0.1;
	%queueOutputData(objDAQOut,repmat([0 0],[ceil(objDAQOut.Rate*dblStartT) 1]));
	queueOutputData(objDAQOut,zeros([ceil(objDAQOut.Rate*dblStartT) 1]));
	startBackground(objDAQOut);
	pause(dblStartT);
else
	objDAQOut = struct;
end

%% assign to structure
structEP.strRecording = strRecording;
structEP.strFilename = strFilename;
structEP.dblPrePostWait = dblPrePostWait;%secs
structEP.dblSamplingRate = dblSamplingRate;%Hz
structEP.intRepsPerPulse = intRepsPerPulse;%count
structEP.intTrialNum = intTrialNum;%count
structEP.dblPulseWait = dblPulseWait;%secs, at least ~0.2s
structEP.vecPulseITI = vecPulseITI;%secs
structEP.dblPulseDur = dblPulseDur;%secs
structEP.vecPulseDur = vecPulseDur;%secs
structEP.dblPulseWaitSignal = dblPulseWaitSignal;
structEP.dblPulseWaitPause = dblPulseWaitPause;

structEP.sStimParamsSettings = sStimParamsSettings;
structEP.sParamsSGL = sParamsSGL;
structEP.objDAQOut = objDAQOut;

%save parameters
save([strOutputDir filesep strFilename], 'structEP');

try
	%% check escape
	if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
	
	%% start pre-wait
	hTicExpStart = tic;
	fprintf('Experiment started; initial wait of %.1fs [%s]\n',dblPrePostWait,getTime);
	while toc(hTicExpStart) < dblPrePostWait
		if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
		pause(1/1000);
	end
	
	%% run stimuli
	for intTrial = 1:intTrialNum
		%timestamp
		hTicTrial = tic;
		
		%save current data
		vecPulseVolt_Temp = vecPulseVolt(1:(intTrial-1));
		cellPulseData_Temp = cellPulseData(1:(intTrial-1));
		cellPulseITI_Temp = cellPulseITI(1:(intTrial-1));
		cellPulseDur_Temp = cellPulseDur(1:(intTrial-1));
		vecStimOnNI_Temp = vecStimOnNI(1:(intTrial-1));
		vecStimOffNI_Temp = vecStimOffNI(1:(intTrial-1));
		save([strOutputDir filesep strFilename '_Temp'],...
			'vecPulseVolt_Temp','cellPulseData_Temp','cellPulseITI_Temp','cellPulseDur_Temp','vecStimOnNI_Temp','vecStimOffNI_Temp');
		
		%get new pulse data
		matData = vecPulseVolt(intTrial)*double(cellPulseData{intTrial});
		
		%msg
		fprintf('Trial %d/%d [%s]\n',intTrial,intTrialNum,getTime);
		
		%check for escape in-between pulse runs
		if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
		
		%prep stimulus
		if intUseDaqDevice > 0
			stop(objDAQOut);
			%extend
			if size(matData,2) == 1
				%matData = repmat(matData,[1 2]);
			end
			%prep
			stop(objDAQOut);
			queueOutputData(objDAQOut,matData);
			prepare(objDAQOut);
		end
		
		%wait
		while toc(hTicTrial) < (dblPulseWaitPause*0.9)
			pause((dblPulseWaitPause - toc(hTicTrial))*0.3);
		end
		while toc(hTicTrial) < dblPulseWaitPause
			%do nothing
		end
		
		%start stimulus
		fprintf('\b; stim started at %.3fs\n',toc(hTicTrial));
		if intUseDaqDevice > 0,startBackground(objDAQOut);end
		
		%log NI timestamp
		if boolUseSGL
			dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
		else
			dblStimOnNI = nan;
		end
		
		%wait
		if intUseDaqDevice > 0
			dblTimeout = (size(matData,1)/dblSamplingRate)*1.5;
			wait(objDAQOut,dblTimeout);
		end
		
		%log NI timestamp
		if boolUseSGL
			dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
		else
			dblStimOffNI = nan;
		end
		
		%log timestamps
		vecStimOnNI(intTrial) = dblStimOnNI;
		vecStimOffNI(intTrial) = dblStimOffNI;
		
		%msg
		fprintf('\b; trial finished at %.3fs [%s]\n',toc(hTicTrial),getTime);
	end
	
	%save data
	structEP.vecPulseVolt = vecPulseVolt(1:intTrial);
	structEP.cellPulseData = cellPulseData(1:intTrial);
	structEP.cellPulseITI = cellPulseITI(1:intTrial);
	structEP.cellPulseDur = cellPulseDur(1:intTrial);
	structEP.vecStimOnNI = vecStimOnNI(1:intTrial);
	structEP.vecStimOffNI = vecStimOffNI(1:intTrial);
	save([strOutputDir filesep strFilename], 'structEP');
	
	%% end-wait
	hTicExpStop = tic;
	fprintf('Starting final wait of %.1fs [%s]\n',dblPrePostWait,getTime);
	while toc(hTicExpStart) < dblPrePostWait
		if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
		pause(1/1000);
	end
	
	%closing remark
	fprintf('\nExperiment is finished at [%s], closing down and cleaning up...\n',getTime);
	
	%end recording
	if boolUseSGL,CloseSGL(hSGL);end
	
	%close Daq IO
	if intUseDaqDevice > 0
		try
			closeDaqOutput(objDAQOut);
			if boolDaqIn
				closeDaqInput(objDAQIn);
			end
		catch
		end
	end
catch ME
	%% catch me and throw me
	fprintf('\n\n\nError occurred! Trying to save data and clean up...\n\n\n');
	
	%save data
	structEP.vecPulseVolt = vecPulseVolt(1:intTrial);
	structEP.cellPulseData = cellPulseData(1:intTrial);
	structEP.cellPulseITI = cellPulseITI(1:intTrial);
	structEP.cellPulseDur = cellPulseDur(1:intTrial);
	structEP.vecStimOnNI = vecStimOnNI(1:intTrial);
	structEP.vecStimOffNI = vecStimOffNI(1:intTrial);
	save([strOutputDir filesep strFilename], 'structEP');
	
	%% end recording
	try
		CloseSGL(hSGL);
	catch
	end
	
	%% close Daq IO
	if intUseDaqDevice > 0
		try
			closeDaqOutput(objDAQOut);
			if boolDaqIn
				closeDaqInput(objDAQIn);
			end
		catch
		end
	end
	
	%% show error
	rethrow(ME);
end
%end
