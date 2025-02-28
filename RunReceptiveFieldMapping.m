
%function structMP = RunReceptiveFieldMapping
%8 seconds per trial
%8 trial types (max 64 seconds per rep)
%10 repetitions = 11 minutes
%80 trials in total

%% suppress m-lint warnings & clear all variables except RunExperiment inputs
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>
clearvars -except sStimPresets sStimParamsSettings sExpMeta;

%% define variables
fprintf('Starting %s [%s]\n',mfilename,getTime);
intStimSet = 1;% 1=0:15:359, reps20; 2=[0 5 90 95], reps 400 with noise; 3= size tuning
boolUseSGL = true;
boolUseNI = true;
boolDebug = false;
if exist('sExpMeta','var')
	%defaults
	dblPupilLightMultiplier = 1; %strength of infrared LEDs
	dblSyncLightMultiplier = 0.5;
	strHostAddress = '192.87.10.238'; %default host address
	objDaqOut = [];
	
	%expand structure
	if isfield(sExpMeta,'dblPupilLightMultiplier'),dblPupilLightMultiplier=sExpMeta.dblPupilLightMultiplier;end
	if isfield(sExpMeta,'dblSyncLightMultiplier'),dblSyncLightMultiplier=sExpMeta.dblSyncLightMultiplier;end
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
if ~exist('sStimParamsSettings','var') || isempty(sStimParamsSettings) || ~strcmpi(sStimParamsSettings.strStimType,'SparseCheckers')
	%general parameters
	sStimParamsSettings = struct;
	sStimParamsSettings.strStimType = 'SparseCheckers'; %{'SparseCheckers','FlickerCheckers'};
	sStimParamsSettings.strLinLoc = 'LinLoc matrix is upside down; top of screen are bottom elements';
	sStimParamsSettings.strOutputPath = 'C:\_Data\Exp'; %appends date
	sStimParamsSettings.strTempObjectPath = 'X:\JorritMontijn\';%X:\JorritMontijn\ or F:\Data\Temp\
	
	%visual space
	sStimParamsSettings.dblSubjectPosX_cm = 0; % cm; relative to center of screen
	sStimParamsSettings.dblSubjectPosY_cm = -2.5; % cm; relative to center of screen, -3.5
	sStimParamsSettings.dblScreenDistance_cm = 17; % cm; measured, 14
	sStimParamsSettings.vecUseMask = 0; %[1] if mask to emulate retinal-space, [0] use screen-space
	
	%screen variables
	sStimParamsSettings.intCornerTrigger = 2; % integer switch; 0=none,1=upper left, 2=upper right, 3=lower left, 4=lower right
	sStimParamsSettings.dblCornerSize = 1/30; % fraction of screen width
	sStimParamsSettings.dblScreenWidth_cm = 51; % cm; measured [51]
	sStimParamsSettings.dblScreenHeight_cm = 29; % cm; measured [29]
	sStimParamsSettings.dblScreenWidth_deg = 2 * atand(sStimParamsSettings.dblScreenWidth_cm / (2 * sStimParamsSettings.dblScreenDistance_cm));
	sStimParamsSettings.dblScreenHeight_deg = 2 * atand(sStimParamsSettings.dblScreenHeight_cm / (2 * sStimParamsSettings.dblScreenDistance_cm));
	sStimParamsSettings.intUseScreen = 2; %which screen to use
	
	%get screen size from PTB
	intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
	vecRect=Screen('Rect', sStimParamsSettings.intUseScreen);
	sStimParamsSettings.intScreenWidth_pix = vecRect(3) - vecRect(1);
	sStimParamsSettings.intScreenHeight_pix = vecRect(4) - vecRect(2);
	
	%receptive field size&location parameters
	sStimParamsSettings.dblCheckerSizeX_deg = 10; % width of checker
	sStimParamsSettings.dblCheckerSizeY_deg = 10; % height of checker
	sStimParamsSettings.intOnOffCheckers = 3; %3/6; how many are on/off at any frame? If flicker, this number is doubled
	
	%stimulus control variables
	sStimParamsSettings.intUseDaqDevice = 1; %ID of DAQ device
	sStimParamsSettings.intUseParPool = 0; %number of workers in parallel pool; [2]
	sStimParamsSettings.intUseGPU = 0; %set to non-zero to use GPU for rendering stimuli
	sStimParamsSettings.intAntiAlias = 0; %which level k of anti-alias to use? Grid size is 2^k - 1
	sStimParamsSettings.dblBackground = 0.5; %background intensity (dbl, [0 1])
	sStimParamsSettings.intBackground = round(mean(sStimParamsSettings.dblBackground)*255);
	sStimParamsSettings.dblContrast = 100; %contrast; [0-100]
	sStimParamsSettings.dblFlickerFreq = 0; %Hz
else
	%get screen size from PTB
	intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
	vecRect=Screen('Rect', sStimParamsSettings.intUseScreen);
	
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
if boolDebug == 1
	intUseScreen = 0;
else
	intUseScreen = sStimParamsSettings.intUseScreen;
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
    intStreamNI = 0; %-1;
%     dblSampFreqNI = GetSampleRate(hSGL, intStreamNI);
    dblSampFreqNI = GetStreamSampleRate(hSGL, intStreamNI, strHostAddress);
	
	%% check disk space available
	strDataDirSGL = GetDataDir(hSGL);
	jFileObj = java.io.File(strDataDirSGL);
	dblFreeGB = (jFileObj.getFreeSpace)/(1024^3);
	if dblFreeGB < 100,warning([mfilename ':LowDiskSpace'],'Low disk space available (%.0fGB) for Neuropixels data (dir: %s)',dblFreeGB,strDataDirSGL);end
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
dblTrialDur = structEP.dblSecsBlankPre + structEP.dblSecsStimDur + structEP.dblSecsBlankPost ;
dblInversionDurSecs = (1/sStimParamsSettings.dblFlickerFreq)/2; %Hz

%% prepare stimulus
%get retinal map
matMapDegsXYD = buildRetinalSpaceMap(sStimParamsSettings);

%prepare checker-board stimuli for incremental on-the-fly stimulus creation
cellParamFields = fieldnames(sStimParamsSettings);
cellAllRemFields = {'strRecording','strExpType','strOutputPath','strTempObjectPath','intUseDaqDevice'}';
indKeepRemFields = contains(cellAllRemFields,cellParamFields);
cellRemFields = cellAllRemFields(indKeepRemFields);
sStimParamsCombosReduced = rmfield(sStimParamsSettings,cellRemFields);
[sStimParams,sStimObject,matMapDegsXY_crop,intStimsForMinCoverage] = getSparseCheckerCombos(sStimParamsCombosReduced,matMapDegsXYD);

%add timestamps to object
sStimObject.TrialNumber = [];
sStimObject.ActStimType = [];
sStimObject.ActStartSecs = [];
sStimObject.ActOnSecs = [];
sStimObject.ActOffSecs = [];
sStimObject.ActOnNI = [];
sStimObject.ActOffNI = [];


%% initialize parallel pool
if sStimParams.intUseParPool > 0 && isempty(gcp('nocreate'))
	parpool(sStimParams.intUseParPool * [1 1]);
end
if sStimParams.intUseGPU > 0
	objGPU = gpuDevice(sStimParams.intUseGPU);
end


%% initialize NI I/O box
if boolUseNI
	%initialize
	fprintf('Connecting to National Instruments box...\n');
	boolDaqOutRunning = false;
	if exist('objDaqOut','var') && ~isempty(objDaqOut)
		try
			%turns leds on
			stop(objDaqOut);
			outputData1 = dblSyncLightMultiplier*cat(1,linspace(3, 3, 200)',linspace(0, 0, 50)');
			outputData2 = dblPupilLightMultiplier*linspace(3, 3, 250)';
			queueOutputData(objDaqOut,[outputData1 outputData2]);
			prepare(objDaqOut);
			pause(0.1);
			startBackground(objDaqOut)
			boolDaqOutRunning = true;
		catch
		end
	end
	if ~boolDaqOutRunning
		objDaqOut = openDaqOutput(sStimParamsSettings.intUseDaqDevice);
		%turns leds on
		stop(objDaqOut);
		outputData1 = dblSyncLightMultiplier*cat(1,linspace(3, 3, 200)',linspace(0, 0, 50)');
		outputData2 = dblPupilLightMultiplier*linspace(3, 3, 250)';
		queueOutputData(objDaqOut,[outputData1 outputData2]);
		prepare(objDaqOut);
		pause(0.1);
		startBackground(objDaqOut)
	end
end

try
	%% INITALIZE SCREEN
	fprintf('Starting PsychToolBox extension...\n');
	%open window
	AssertOpenGL;
	KbName('UnifyKeyNames');
	intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
	if boolDebug == 1, vecInitRect = [0 0 640 640];else vecInitRect = [];end
	try
		Screen('Preference', 'SkipSyncTests', 0);
		[ptrWindow,vecRect] = Screen('OpenWindow', intUseScreen,sStimParams.intBackground,vecInitRect);
	catch ME
		warning([mfilename ':ErrorPTB'],'Psychtoolbox error, attempting with sync test skip [msg: %s]',ME.message);
		Screen('Preference', 'SkipSyncTests', 1);
		[ptrWindow,vecRect] = Screen('OpenWindow', intUseScreen,sStimParams.intBackground,vecInitRect);
	end
	%window variables
	sStimParams.ptrWindow = ptrWindow;
	sStimParams.vecRect = vecRect;
	sStimParams.intScreenWidth_pix = vecRect(3)-vecRect(1);
	sStimParams.intScreenHeight_pix = vecRect(4)-vecRect(2);
	
	%% MAXIMIZE PRIORITY
	intOldPriority = 0;
	if boolDebug == 0
		intPriorityLevel=MaxPriority(ptrWindow);
		intOldPriority = Priority(intPriorityLevel);
	end
	
	%% get refresh rate
	dblStimFrameRate=Screen('FrameRate', ptrWindow);
	intStimFrameRate = round(dblStimFrameRate);
	dblStimFrameDur = mean(1/dblStimFrameRate);
	dblInterFlipInterval = Screen('GetFlipInterval', ptrWindow);
	if dblStimFrameDur/dblInterFlipInterval > 1.05 || dblStimFrameDur/dblInterFlipInterval < 0.95
		warning([mfilename ':InconsistentFlipDur'],sprintf('Something iffy with flip speed and monitor refresh rate detected; frame duration is %fs, while flip interval is %fs!',dblStimFrameDur,dblInterFlipInterval));
	end
	
	%% check escape
	if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
	
	%% PRESENT STIMULI
	structEP.intStimNumber = intStimsForMinCoverage;
	structEP.TrialNumber = nan(1,structEP.intStimNumber);
	structEP.ActStimType = nan(1,structEP.intStimNumber);
	structEP.ActOnSecs = nan(1,structEP.intStimNumber);
	structEP.ActOffSecs = nan(1,structEP.intStimNumber);
	structEP.ActStartSecs = nan(1,structEP.intStimNumber);
	structEP.ActStopSecs = nan(1,structEP.intStimNumber);
	structEP.ActOnNI = nan(1,structEP.intStimNumber);
	structEP.ActOffNI = nan(1,structEP.intStimNumber);
	
	structEP.dblStimFrameDur = dblStimFrameDur;
	cellStimPropNames = fieldnames(sStimObject(1));
	cellStimPropNames = cellStimPropNames(structfun(@isscalar,sStimObject(1)));
	for intField=1:numel(cellStimPropNames)
		strField = cellStimPropNames{intField};
		structEP.(strField) = nan(1,structEP.intStimNumber);
	end
	
	%show trial summary
	fprintf('\nFinished preparation at [%s], minimum coverage will take %d presentations (approximately %.2fs)\nWill present sparse checkers until "ESC"\n\n   Waiting for "ENTER"\n',...
		getTime,intStimsForMinCoverage,intStimsForMinCoverage*dblTrialDur);
	
	%wait for signal
	opts = struct;
	opts.Default = 'Start';
	opts.Interpreter = 'tex';
	strAns = questdlg('Would you like to start the stimulation?', ...
		'Start Stimulation', ...
		'Start','Cancel',opts);
	if ~strcmp(strAns,opts.Default)
		error([mfilename ':RunCancelled'],'Cancelling');
	end
	
	%set timers
	refTime = tic;
	dblLastFlip = Screen('Flip', ptrWindow);
	dblInitialFlip = dblLastFlip;
	
	%timestamp start
	structEP.strStartDate = getDate();
	structEP.strStartTime = getTime();
	
	%% wait initial-blanking
	fprintf('Starting initial blank (dur=%.3fs) [%s]\n',structEP.dblSecsBlankAtStart,getTime);
	dblInitialBlankDur = 0;
	while dblInitialBlankDur < structEP.dblSecsBlankAtStart
		%do nothing
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblBlankStartFlip = Screen('Flip', ptrWindow);
		dblInitialBlankDur = dblBlankStartFlip - dblInitialFlip;
	end
	
	while ~CheckEsc()
		%trial start
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblLastFlip = Screen('Flip', ptrWindow);
		dblTrialStartFlip = dblLastFlip;
		
		%fill DAQ with data
		if boolUseNI
			stop(objDaqOut);
			outputData1 = dblSyncLightMultiplier*cat(1,linspace(3, 3, 200)',linspace(0, 0, 50)');
			outputData2 = dblPupilLightMultiplier*linspace(3, 3, 250)';
			queueOutputData(objDaqOut,[outputData1 outputData2]);
			prepare(objDaqOut);
		end
		
		
		%% prepare stimulus
		ptrCreationTime = tic;
		[gMatImageRGB,sStimObject] = buildCheckerStim(sStimObject,matMapDegsXY_crop);
		matImageRGB = gather(gMatImageRGB);
		intThisTrial = numel(sStimObject);
		ptrTex = Screen('MakeTexture', ptrWindow, matImageRGB);
		if sStimParams.dblFlickerFreq > 0
			ptrTexInverted = Screen('MakeTexture', ptrWindow, 255-matImageRGB);
		end
		dblCreationDur = toc(ptrCreationTime);
		
		%send warning if creation took too long
		if dblCreationDur > structEP.dblSecsBlankPre
			warning([mfilename ':InsufficientTime'],sprintf('Pre-stimulus blank (%.3fs) was insufficient to pre-render stimulus (took %.3fs)\nPlease increase pre-stimulus blanking time, disable the anti-alias, use fewer checkers, or reduce the screen resolution', structEP.dblSecsBlankPre,dblCreationDur))
		end
		
		%get timing
		dblStartSecs = dblTrialStartFlip-dblInitialFlip;
		dblStimOnSecs = dblStartSecs + structEP.dblSecsBlankPre;
		dblStimOffSecs = dblStimOnSecs + structEP.dblSecsStimDur;
		dblStimDurSecs = dblStimOffSecs - dblStimOnSecs;
		dblEndSecs = dblStimOffSecs + structEP.dblSecsBlankPost;
		
		
		%% wait pre-blanking
		dblPreBlankDur = 0;
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblLastFlip = Screen('Flip', ptrWindow);
		dblDAQ_Dur = 0; %measured time to set NI DAQ switch
		while dblPreBlankDur < (dblStimOnSecs - dblStartSecs - dblDAQ_Dur)
			%do nothing
			Screen('FillRect',ptrWindow, sStimParams.intBackground);
			dblLastFlip = Screen('Flip', ptrWindow, dblLastFlip + dblStimFrameDur/2);
			dblPreBlankDur = dblLastFlip - dblTrialStartFlip;
		end
		
		%% 250ms pulse at stim start
		if boolUseNI,startBackground(objDaqOut);end
		
		%% show stimulus
		Screen('DrawTexture',ptrWindow,ptrTex);
		dblLastFlip = Screen('Flip', ptrWindow,dblLastFlip+dblInterFlipInterval/2);
        dblStimOnFlip = dblLastFlip;

        %log NI timestamp
        if boolUseSGL
            %                     dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
            dblStimOnNI = GetStreamSampleCount(hSGL, intStreamNI, strHostAddress)/dblSampFreqNI;
        else
            dblStimOnNI = nan;
        end

        %wait until stim period is over
        boolUseInversion = true;
        dblLastInversion = 0;
        dblStimDur = 0;
		ptrUseTex = ptrTex;
		while dblStimDur <= (dblStimDurSecs - dblStimFrameDur*2)
			%check for inversion
			if dblStimDur - dblLastInversion > dblInversionDurSecs
				dblLastInversion = dblStimDur;
				if boolUseInversion
					ptrUseTex = ptrTexInverted;
				else
					ptrUseTex = ptrTex;
				end
				boolUseInversion = ~boolUseInversion;
			end
			
			%show stimulus
			Screen('DrawTexture',ptrWindow,ptrUseTex);
			dblLastFlip = Screen('Flip', ptrWindow,dblLastFlip+dblInterFlipInterval/2);
			dblStimDur = dblLastFlip - dblStimOnFlip;
		end
		
		%back to background
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblLastFlip = Screen('Flip', ptrWindow,dblLastFlip+dblInterFlipInterval/2);
        dblStimOffFlip = dblLastFlip;

        %log NI timestamp
        if boolUseSGL
            % 			dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
            dblStimOffNI =  GetStreamSampleCount(hSGL, intStreamNI, strHostAddress)/dblSampFreqNI;
        else
            dblStimOffNI = nan;
        end

        %close texture and wait for post trial seconds
        Screen('Close',ptrTex);
        clear ptrTex;
		if exist('ptrTexInverted','var')
			Screen('Close',ptrTexInverted);
			clear ptrTexInverted;
		end
		
		%% save stimulus object
		try
			%get data
			sThisStimObject = sStimObject(end);
			
			%add timestamps
			sThisStimObject.TrialNumber = intThisTrial;
			sThisStimObject.ActStimType = intThisTrial;
			sThisStimObject.ActStartSecs = dblTrialStartFlip;
			sThisStimObject.ActOnSecs = dblStimOnFlip;
			sThisStimObject.ActOffSecs = dblStimOffFlip;
			sThisStimObject.ActOnNI = dblStimOnNI;
			sThisStimObject.ActOffNI = dblStimOffNI;
			
			%save object
			sStimObject(end) = sThisStimObject;
			sObject = sThisStimObject;
			save(fullfile(strTempDir,['Object',num2str(intThisTrial),'.mat']),'sObject');
		catch ME
			warning(ME.identifier,'%s',ME.message);
		end
		
		%% wait post-blanking
		dblThisTrialDur = 0;
		boolNoFlip = true;
		while boolNoFlip || dblThisTrialDur < (dblTrialDur - dblStimFrameDur*2)
			%do nothing
			Screen('FillRect',ptrWindow, sStimParams.intBackground);
			dblLastFlip = Screen('Flip', ptrWindow,dblLastFlip+dblInterFlipInterval/2);
			dblThisTrialDur = dblLastFlip - dblTrialStartFlip;
			boolNoFlip = false;
		end
		
		%new stim-based output
		intStimNumber = intThisTrial;
		structEP.TrialNumber(intStimNumber) = intThisTrial;
		structEP.ActStimType(intStimNumber) = intThisTrial;
		structEP.ActStartSecs(intStimNumber) = dblTrialStartFlip;
		structEP.ActOnSecs(intStimNumber) = dblStimOnFlip;
		structEP.ActOffSecs(intStimNumber) = dblStimOffFlip;
		structEP.ActEndSecs(intStimNumber) = dblLastFlip;
		structEP.ActOnNI(intStimNumber) = dblStimOnNI;
		structEP.ActOffNI(intStimNumber) = dblStimOffNI;
		
		%show trial summary
		dblPercDone = 100*sum(sStimObject(end).UsedLinLocOff(:))/numel(sStimObject(end).UsedLinLocOff);
		fprintf('Completed trial %d at time=%.3fs (stim dur=%.3fs); coverage is now %.1f%%; Stim creation took %.3fs\n',intThisTrial,dblLastFlip - dblInitialFlip,dblStimOffFlip-dblStimOnFlip,dblPercDone,dblCreationDur);
	end
	
	%% save data
	%save data
	structEP.sStimParams = sStimParams;
	structEP.sStimObject = sStimObject;
	save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL');
	
	%show trial summary
	fprintf('Finished experiment & data saving at [%s], waiting for end blank (dur=%.3fs)\n',getTime,structEP.dblSecsBlankAtEnd);
	
	%% wait end-blanking
	dblEndBlankDur = 0;
	while dblEndBlankDur < structEP.dblSecsBlankAtEnd
		%do nothing
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblEndFlip = Screen('Flip', ptrWindow);
		dblEndBlankDur = dblEndFlip - dblLastFlip;
	end
	
	%clean up
	fprintf('\nExperiment is finished at [%s], closing down and cleaning up...\n',getTime);
	Screen('Close',ptrWindow);
	Screen('Close');
	Screen('CloseAll');
	ShowCursor;
	Priority(0);
	Screen('Preference', 'Verbosity',intOldVerbosity);
	
	%% close Daq IO
	if boolUseNI && ~(exist('sExpMeta','var') && isfield(sExpMeta,'objDaqOut'))
		try
			closeDaqOutput(objDaqOut);
		catch
		end
	end
	
catch ME
	%% catch me and throw me
	fprintf('\n\n\nError occurred! Trying to save data and clean up...\n\n\n');
	
	%save data
	structEP.sStimParams = sStimParams;
	structEP.sStimObject = sStimObject;
	if ~exist('sParamsSGL','var'),sParamsSGL=[];end
	save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL');
	
	%% catch me and throw me
	Screen('Close');
	Screen('CloseAll');
	ShowCursor;
	Priority(0);
	Screen('Preference', 'Verbosity',intOldVerbosity);
	
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
%end
