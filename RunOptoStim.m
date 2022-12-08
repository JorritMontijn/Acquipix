%function structEP = RunDriftingGratings

%% suppress m-lint warnings
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>
clearvars -except sStimPresets sExpMeta sStimParamsSettings;

%% define variables
fprintf('Starting %s [%s]\n',mfilename,getTime);
intStimSet = 1;% 1=0:15:359, reps20; 2=[0 5 90 95], reps 400 with noise
boolUseSGL = true;
boolUseNI = true;
boolDebug = false;
strHostAddress = '192.87.10.238'; %default host address
if exist('sExpMeta','var')
	%defaults
	objDaqOut = [];
	
	%expand structure
	if isfield(sExpMeta,'strHostAddress'),strHostAddress=sExpMeta.strHostAddress;end
	if isfield(sExpMeta,'objDaqOut'),objDaqOut=sExpMeta.objDaqOut;end
	if isfield(sExpMeta,'boolUseSGL'),boolUseSGL=sExpMeta.boolUseSGL;end
	if isfield(sExpMeta,'boolUseNI'),boolUseNI=sExpMeta.boolUseNI;end
else
	sExpMeta = [];
end

%% query user input for recording name
if exist('sStimParamsSettings','var') && isfield(sStimParamsSettings,'strRecording')
	strRecording = sStimParamsSettings.strRecording;
else
	strRecording = input('Recording name (e.g., MouseX): ', 's');
end

%% input params
fprintf('Loading settings...\n');
if ~exist('sStimParamsSettings','var') || isempty(sStimParamsSettings) 
	%parameters
	sStimParamsSettings.strStimType = 'OptoStim';
	sStimParamsSettings.strHostAddress = strHostAddress;
	sStimParamsSettings.strOutputPath = 'F:\DataRaw\Exp'; %appends date
	sStimParamsSettings.strTempObjectPath = 'D:\Tempdata\';%X:\JorritMontijn\ or F:\Data\Temp\
	sStimParamsSettings.dblPulseVoltage = 3;%volts
	sStimParamsSettings.dblSamplingRate = 10000;%Hz
	sStimParamsSettings.intUseDaqDevice = 1; %ID of DAQ device
    sStimParamsSettings.strPortOut = 'ao1'; %output port of DAQ device
elseif ~strcmpi(sStimParamsSettings.strStimType,'OptoStim')
	error([mfilename ':WrongStimType'],sprintf('You''re trying to run "%s", but the stim parameter structure is meant for "%s"',mfilename',sStimParamsSettings.strStimType));
else
	% evaluate and assign pre-defined values to structure
	cellFields = fieldnames(sStimParamsSettings);
	for intField=1:numel(cellFields)
		try
			sStimParamsSettings.(cellFields{intField}) = eval(sStimParamsSettings.(cellFields{intField}));
		catch
			sStimParamsSettings.(cellFields{intField}) = sStimParamsSettings.(cellFields{intField});
		end
	end
end

%% set output locations for logs
strOutputPath = sStimParamsSettings.strOutputPath;
strTempObjectPath = sStimParamsSettings.strTempObjectPath;
strThisFilePath = mfilename('fullpath');
[strFilename,strLogDir,strTempDir,strTexDir] = RE_assertPaths(strOutputPath,strRecording,strTempObjectPath,strThisFilePath);
fprintf('Saving output in directory %s; loading textures from %s\n',strLogDir,strTexDir);

%% initialize connection with SpikeGLX
if boolUseSGL
	%check if data are supplied
	if exist('sExpMeta','var') && isfield(sExpMeta,'hSGL') && isfield(sExpMeta,'strRunName') && isfield(sExpMeta,'sParamsSGL')
		%get data
		hSGL = sExpMeta.hSGL;
		strRunName = sExpMeta.strRunName;
		sParamsSGL = sExpMeta.sParamsSGL;
		
		%start recording
		intOutFlag = StartRecordingSGL(hSGL);
	else
		%start connection
		fprintf('Opening SpikeGLX connection & starting recording "%s" [%s]...\n',strRecording,getTime);
		[hSGL,strRunName,sParamsSGL] = InitSGL(strRecording,strHostAddress);
	end
	fprintf('SGL saving to "%s", matlab saving to "%s.mat" [%s]...\n',strRunName,strFilename,getTime);
	
	%retrieve some parameters
	intStreamNI = -1;
	dblSampRateNI_rec = GetSampleRate(hSGL, intStreamNI);
    intStreamIM = 0; %needs to be adjusted if there are more than one probe
	dblSampRateIM_rec = GetSampleRate(hSGL, intStreamIM);
    
	%% check disk space available
	%strDataDirSGL = GetDataDir(hSGL);
	%jFileObj = java.io.File(strDataDirSGL);
	%dblFreeGB = (jFileObj.getFreeSpace)/(1024^3);
	%if dblFreeGB < 100,warning([mfilename ':LowDiskSpace'],'Low disk space available (%.0fGB) for Neuropixels data (dir: %s)',dblFreeGB,strDataDirSGL);end
else
	sParamsSGL = struct;
end

%% build structEP
%load presets
if ~exist('sStimPresets','var') || ~strcmp(sStimPresets.strExpType,mfilename)
	sStimPresets = loadStimPreset(intStimSet,mfilename);
end

% evaluate and assign pre-defined values to structure
structEP = struct; %structureElectroPhysiology
cellFieldsSP = fieldnames(sStimPresets);
for intField=1:numel(cellFieldsSP)
	try
		structEP.(cellFieldsSP{intField}) = eval(sStimPresets.(cellFieldsSP{intField}));
	catch
		structEP.(cellFieldsSP{intField}) = sStimPresets.(cellFieldsSP{intField});
	end
end
structEP.intStimTypes = numel(sStimPresets.vecPulseITI);

%% combine data & pre-allocate
%combine
sStimParams = catstruct(sStimParamsSettings,sStimPresets);
%extract
cellFields = fieldnames(sStimParams);
for intField=1:numel(cellFields)
	eval([(cellFields{intField}) ' = sStimParams.(cellFields{intField});']);
end

%build pres vectors
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

%% initialize NI I/O box
if boolUseNI && sStimParamsSettings.intUseDaqDevice > 0
	%% setup connection
	%query connected devices
	objDevice = daq.getDevices;
	strCard = objDevice.Model;
	strID = objDevice.ID;
	
	%create connection
	objDAQOut = daq.createSession(objDevice(sStimParamsSettings.intUseDaqDevice).Vendor.ID);
	
	%set variables
	objDAQOut.IsContinuous = true;
	objDAQOut.Rate=round(dblSamplingRate); %1ms precision
	objDAQOut.NotifyWhenScansQueuedBelow = 100;
	
	%add picospritzer output channels
	%[chOut0,dblIdx0] = addAnalogOutputChannel(objDAQOut, strID, 'ao0', 'Voltage');
	
	%add opto LED output channels
	[chOut1,dblIdx1] = addAnalogOutputChannel(objDAQOut, strID, strPortOut, 'Voltage');
	
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
structEP.vecPulseDur = vecPulseDur;%secs
structEP.dblPulseWaitSignal = dblPulseWaitSignal;
structEP.dblPulseWaitPause = dblPulseWaitPause;

structEP.sStimParams = sStimParams;
structEP.sParamsSGL = sParamsSGL;
structEP.objDAQOut = objDAQOut;

%timestamp start
structEP.strStartDate = getDate();
structEP.strStartTime = getTime();

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
	warning('off','CalinsNetMex:connectionClosed');
	
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
		save(fullfile(strTempDir,[strFilename '_Temp']),...
			'vecPulseVolt_Temp','cellPulseData_Temp','cellPulseITI_Temp','cellPulseDur_Temp','vecStimOnNI_Temp','vecStimOffNI_Temp');
		
		%get new pulse data
		matData = vecPulseVolt(intTrial)*double(cellPulseData{intTrial});
		
		%msg
		fprintf('Trial %d/%d [%s]\n',intTrial,intTrialNum,getTime);
		
		%check for escape in-between pulse runs
		if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
		
		%prep stimulus
		if boolUseNI && sStimParamsSettings.intUseDaqDevice > 0
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
		if boolUseNI && sStimParamsSettings.intUseDaqDevice > 0,startBackground(objDAQOut);end
		
		%log NI timestamp
		if boolUseSGL
			dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampRateNI_rec;
		else
			dblStimOnNI = nan;
		end
		
		%wait
		if boolUseNI && sStimParamsSettings.intUseDaqDevice > 0
			dblTimeout = (size(matData,1)/dblSamplingRate)*1.5;
			wait(objDAQOut,dblTimeout);
		end
		
		%log NI timestamp
		if boolUseSGL
			dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampRateNI_rec;
		else
			dblStimOffNI = nan;
		end
		
		%log timestamps
		vecStimOnNI(intTrial) = dblStimOnNI;
		vecStimOffNI(intTrial) = dblStimOffNI;
		
		%msg
		fprintf('\b; trial finished at %.3fs [%s]\n',toc(hTicTrial),getTime);
	end
	warning('on','CalinsNetMex:connectionClosed');
	
	%save data
	structEP.vecPulseVolt = vecPulseVolt(1:intTrial);
	structEP.cellPulseData = cellPulseData(1:intTrial);
	structEP.cellPulseITI = cellPulseITI(1:intTrial);
	structEP.cellPulseDur = cellPulseDur(1:intTrial);
	structEP.vecStimOnNI = vecStimOnNI(1:intTrial);
	structEP.vecStimOffNI = vecStimOffNI(1:intTrial);
    if exist('dblSampRateNI_rec','var')
	save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL','dblSampRateNI_rec','dblSampRateIM_rec');
    else
    save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL');
    end
	
	
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
	if sStimParamsSettings.intUseDaqDevice > 0
		try
			closeDaqOutput(objDAQOut);
			if boolDaqIn
				closeDaqInput(objDAQIn);
			end
		catch
		end
	end
	
catch ME
	%% check if escape
	if strcmp(ME.identifier,'RunOptoStim:EscapePressed')
		fprintf('\nEscape pressed at [%s], closing down and cleaning up...\n',getTime);
		
		%save data
		structEP.vecPulseVolt = vecPulseVolt(1:intTrial);
		structEP.cellPulseData = cellPulseData(1:intTrial);
		structEP.cellPulseITI = cellPulseITI(1:intTrial);
		structEP.cellPulseDur = cellPulseDur(1:intTrial);
		structEP.vecStimOnNI = vecStimOnNI(1:intTrial);
		structEP.vecStimOffNI = vecStimOffNI(1:intTrial);
        if exist('dblSampRateNI_rec' ,'var')
		save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL','dblSampRateNI_rec','dblSampRateIM_rec');
        else
        save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL');    
        end
        
		%clean up
		fprintf('\nExperiment is finished at [%s], closing down and cleaning up...\n',getTime);
		
		%% close Daq IO
		if boolUseNI && ~(exist('sExpMeta','var') && isfield(sExpMeta,'objDaqOut'))
			try
				closeDaqOutput(objDaqOut);
			catch
			end
		end
		
	else
		%% catch me and throw me
		fprintf('\n\n\nError occurred! Trying to save data and clean up...\n\n\n');
		
		%save data
		structEP.vecPulseVolt = vecPulseVolt(1:intTrial);
		structEP.cellPulseData = cellPulseData(1:intTrial);
		structEP.cellPulseITI = cellPulseITI(1:intTrial);
		structEP.cellPulseDur = cellPulseDur(1:intTrial);
		structEP.vecStimOnNI = vecStimOnNI(1:intTrial);
		structEP.vecStimOffNI = vecStimOffNI(1:intTrial);
        if exist('dblSampRateNI_rec','var')
        save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL','dblSampRateNI_rec','dblSampRateIM_rec');
        else
        save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL');
        end
		
		
		%% close Daq IO
		if boolUseNI && ~(exist('sExpMeta','var') && isfield(sExpMeta,'objDaqOut'))
			try
				closeDaqOutput(objDaqOut);
			catch
			end
		end
		
		%% show error
		rethrow(ME);
	end
end
%end
