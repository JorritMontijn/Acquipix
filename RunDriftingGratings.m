%function structEP = RunDriftingGratings

%% suppress m-lint warnings
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>
clearvars -except sStimPresets sStimParamsSettings sExpMeta;

%% define variables
fprintf('Starting %s [%s]\n',mfilename,getTime);
intStimSet = 3;% 1=0:15:359, reps20; 2=[0 5 90 95], reps 400 with noise; 3= size tuning
boolUseSGL = true;
boolUseNI = true;
boolDebug = false;
boolGammaCorrectScreen = true;
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
if ~exist('sStimParamsSettings','var') || isempty(sStimParamsSettings) || ~(strcmpi(sStimParamsSettings.strStimType,'SquareGrating') || ~strcmpi(sStimParamsSettings.strStimType,'SineGrating'))
	%general
	sStimParamsSettings = struct;
	sStimParamsSettings.strStimType = 'SquareGrating';
	sStimParamsSettings.strOutputPath = 'C:\_Data\Exp'; %appends date
	sStimParamsSettings.strTempObjectPath = 'X:\JorritMontijn\';%X:\JorritMontijn\ or F:\Data\Temp\
	
	%visual space parameters
	sStimParamsSettings.dblSubjectPosX_cm = 0; % cm; relative to center of screen
	sStimParamsSettings.dblSubjectPosY_cm = -2.5; % cm; relative to center of screen, -3.5
	sStimParamsSettings.dblScreenDistance_cm = 17; % cm; measured, 14
	sStimParamsSettings.vecUseMask = 0; %[1] if mask to emulate retinal-space, [0] use screen-space
	
	%receptive field size&location parameters
	sStimParamsSettings.vecStimPosX_deg = 0; % deg; relative to subject
	sStimParamsSettings.vecStimPosY_deg = 0; % deg; relative to subject
	sStimParamsSettings.vecStimulusSize_deg = 140;%circular window in degrees [140]
	sStimParamsSettings.vecSoftEdge_deg = 2; %width of cosine ramp  in degrees, [0] is hard edge
	
	%screen variables
	sStimParamsSettings.intCornerTrigger = 2; % integer switch; 0=none,1=upper left, 2=upper right, 3=lower left, 4=lower right
	sStimParamsSettings.dblCornerSize = 1/30; % fraction of screen width
	sStimParamsSettings.dblScreenWidth_cm = 51; % cm; measured [51]
	sStimParamsSettings.dblScreenHeight_cm = 29; % cm; measured [29]
	sStimParamsSettings.dblScreenWidth_deg = 2 * atand(sStimParamsSettings.dblScreenWidth_cm / (2 * sStimParamsSettings.dblScreenDistance_cm));
	sStimParamsSettings.dblScreenHeight_deg = 2 * atand(sStimParamsSettings.dblScreenHeight_cm / (2 * sStimParamsSettings.dblScreenDistance_cm));
	sStimParamsSettings.intUseScreen = 2; %which screen to use
	
	%stimulus control variables
	sStimParamsSettings.intUseDaqDevice = 1; %ID of DAQ device
	sStimParamsSettings.intUseParPool = 0; %number of workers in parallel pool; [2]
	sStimParamsSettings.intUseGPU = 1;
	sStimParamsSettings.intAntiAlias = 0;
	sStimParamsSettings.str90Deg = '0 degrees is rightward motion; 90 degrees is upward motion';
	sStimParamsSettings.vecBackgrounds = 0.5; %background intensity (dbl, [0 1])
	sStimParamsSettings.intBackground = round(mean(sStimParamsSettings.vecBackgrounds)*255);
	sStimParamsSettings.vecContrasts = 100; %contrast; [0-100] 100 or [10 20 30 40 60 80 100]
	sStimParamsSettings.vecSpatialFrequencies = 0.05; %Spat Frequency in cyc/deg 0.08
	sStimParamsSettings.vecTemporalFrequencies = 1; %Temporal frequency in cycles per second (0 = static gratings only)
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


%% prepare stimuli
%build fields for getCombos
if ~isfield(sStimPresets,'boolGenNoise')
	sStimPresets.boolGenNoise = false;
end
if ~isfield(sStimPresets,'vecOrientationNoise')
	sStimPresets.vecOrientationNoise = 0;
end
if ~isfield(sStimParamsSettings,'strRecording')
	sStimParamsSettings.strRecording = strRecording;
end
sStimParams = catstruct(sStimParamsSettings,sStimPresets);
cellFields = fieldnames(sStimParams);
indRem = cellfun(@(x) strcmp(x(1:7),'dblSecs'),cellFields);
sStimParamsCombosReduced = rmfield(sStimParams,cellFields(indRem));
cellParamFields = fieldnames(sStimParamsCombosReduced);
cellAllRemFields = {'boolGenNoise','intNumRepeats','vecOrientationNoise','strRecording','strExpType','strOutputPath','strTempObjectPath','intUseDaqDevice'}';
indKeepRemFields = contains(cellAllRemFields,cellParamFields);
cellRemFields = cellAllRemFields(indKeepRemFields);
sStimParamsCombosReduced = rmfield(sStimParamsCombosReduced,cellRemFields);

%get stimuli
[sStimParamsEvaluated,sStimObject,sStimTypeList] = getDriftingGratingCombos(sStimParamsCombosReduced);
if isfield(sStimParams,'boolGenNoise') && sStimParams.boolGenNoise
	for intObject=1:numel(sStimObject)
		sStimObject(intObject).OrientationNoise = sStimParams.vecOrientationNoise(intObject);
	end
end
warning('off','catstruct:DuplicatesFound');
sStimParams = catstruct(sStimParamsEvaluated,sStimParams);
warning('on','catstruct:DuplicatesFound');

%get noise stimuli
cellStimObjectNoise = cell(1,numel(sStimObject));
vecStimsWithNoise = find(sStimParams.vecOrientationNoise > 0);
for intNoiseStim=1:numel(vecStimsWithNoise)
	intStim = vecStimsWithNoise(intNoiseStim);
	dblOri = sStimParams.vecOrientations(intStim);
	dblNoise = sStimParams.vecOrientationNoise(intStim);
	vecNoiseStims = [dblOri-dblNoise*3:0.1:dblOri+dblNoise*3];
	intNoiseStims = numel(vecNoiseStims);
	fprintf('Loading %d noise stimuli for stim %d [%s]\n',intNoiseStims,numel(vecStimsWithNoise),getTime);
	sStimParamsNoiseStim.vecOrientations = vecNoiseStims;
	[dummy,sThisStimObjectNoise,dummy2] = getDriftingGratingCombos(sStimParamsNoiseStim);
	cellStimObjectNoise{intStim} = sThisStimObjectNoise;
end

%% initialize parallel pool && gpu
if sStimParams.intUseParPool > 0 && isempty(gcp('nocreate'))
	parpool(sStimParams.intUseParPool * [1 1]);
end
if sStimParams.intUseGPU > 0
	objGPU = gpuDevice(sStimParams.intUseGPU);
end

%% create presentation vectors
structEP.intStimTypes = numel(sStimObject);
structEP.vecTrialStimTypes = [];
for intRep = 1:structEP.intNumRepeats
	%randomized order
	structEP.vecTrialStimTypes = [structEP.vecTrialStimTypes randperm(structEP.intStimTypes)];
end
structEP.intTrialNum = numel(structEP.vecTrialStimTypes);

initialBlank = structEP.dblSecsBlankAtStart;
trialDur = structEP.dblSecsBlankPre + structEP.dblSecsStimDur + structEP.dblSecsBlankPost;
endBlank = structEP.dblSecsBlankAtEnd;
totalLength = initialBlank + trialDur * structEP.intTrialNum + endBlank;
totalDurSecs = 	structEP.dblSecsBlankAtStart + structEP.intTrialNum * (structEP.dblSecsBlankPre + structEP.dblSecsStimDur + structEP.dblSecsBlankPost) + structEP.dblSecsBlankAtEnd;

structEP.vecTrialStartSecs = initialBlank:trialDur:(totalLength-endBlank-1);
structEP.vecTrialStimOnSecs = structEP.vecTrialStartSecs + structEP.dblSecsBlankPre;
structEP.vecTrialStimOffSecs = structEP.vecTrialStimOnSecs + structEP.dblSecsStimDur;
structEP.vecTrialEndSecs = structEP.vecTrialStimOffSecs + structEP.dblSecsBlankPost;

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
	
	%calibrate monitor
	if boolGammaCorrectScreen && exist('C:\Users\neuropixels\Desktop\GammaCorrection\gammaTable.mat','file')
		load("C:\Users\neuropixels\Desktop\GammaCorrection\gammaTable.mat");
		Screen('LoadNormalizedGammaTable', ptrWindow, gammaTable*[1 1 1]);
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
	
	%% CHECK TEXTURES
	%create base texture
	fprintf('\nChecking base textures... ');
	hTic = tic;
	boolPreLoadTextures = true;
	for intStimType = 1:structEP.intStimTypes
		sStimObject(intStimType).FrameRate = intStimFrameRate;
		matGrating = loadStimulusTexture(sStimObject(intStimType),strTexDir,sStimParams);
		if toc(hTic) > 5
			hTic = tic;
			fprintf('[%d/%d]',intStimType,structEP.intStimTypes);
		end
	end
	fprintf('\nChecking noise textures... ');
	hTic = tic;
	for intNoiseStimType=1:numel(cellStimObjectNoise)
		if isempty(cellStimObjectNoise{intNoiseStimType}),continue;end
		fprintf('\nChecking noise stimuli for base stim %d/%d... ',intNoiseStimType,numel(cellStimObjectNoise));
		hTic = tic;
		sStimObjectNoise = cellStimObjectNoise{intNoiseStimType};
		for intNoiseStim = 1:numel(sStimObjectNoise)
			sStimObjectNoise(intNoiseStim).FrameRate = intStimFrameRate;
			matGrating = loadStimulusTexture(sStimObjectNoise(intNoiseStim),strTexDir,sStimParams);
			if toc(hTic) > 5
				hTic = tic;
				fprintf('[%d/%d]',intNoiseStim,numel(sStimObjectNoise));
			end
		end
		cellStimObjectNoise{intNoiseStimType} = sStimObjectNoise;
	end
	fprintf('\n   Done\n');
	
	%% attempt to pre-load textures
	fprintf('\nAttempting texture pre-loading...');
	if boolPreLoadTextures
		try
			%draw textures
			matGrating = loadStimulusTexture(sStimObject(1),strTexDir,sStimParams);
			intTotFrames = size(matGrating,3);
			intOptimizeForDrawAngle = 0; %optimize for upright
			intSpecialFlags = 0; %1 to put into square opengl texture
			vecTex = nan(1,intTotFrames);
			for intFrame=1:intTotFrames
				vecTex(intFrame)=Screen('MakeTexture', ptrWindow, matGrating(:,:,intFrame), intOptimizeForDrawAngle, intSpecialFlags);
			end
			clear matGrating;
			
			%pre-load
			[boolResident,vecTexResident] = Screen('PreloadTextures', ptrWindow, vecTex);
			fprintf('   Done!\n');
		catch
			%set switch to false
			boolPreLoadTextures = false;
			warning([mfilename ':PreloadError'],'Could not pre-load all textures for one trial; please upgrade your GPU!');
			
			%restart PTB
			[ptrWindow,vecRect] = Screen('OpenWindow', sStimParams.intUseScreen,sStimParams.intBackground);
			sStimParams.ptrWindow = ptrWindow;
		end
	end
	
	%% PRESENT STIMULI
	%stim-based logs
	structEP.intStimNumber = structEP.intTrialNum;
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
	fprintf('Finished preparation at [%s], will present %d repetitions of %d stimuli (est. dur: %.1fs)\n\n   Waiting for start signal\n',...
		getTime,structEP.intNumRepeats,structEP.intStimTypes,totalDurSecs);
	
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
	while dblInitialBlankDur < (structEP.dblSecsBlankAtStart - dblStimFrameDur)
		%do nothing
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblLastFlipFlip = Screen('Flip', ptrWindow,dblLastFlip + dblStimFrameDur/2);
		dblInitialBlankDur = dblLastFlipFlip - dblInitialFlip;
	end
	
	for intThisTrial = 1:structEP.intTrialNum
		%% check escape
		if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
		
		%% prep trial
		%trial start
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblTrialStartFlip = Screen('Flip', ptrWindow);
		
		%fill DAQ with data
		if boolUseNI
			stop(objDaqOut);
			outputData1 = dblSyncLightMultiplier*cat(1,linspace(3, 3, 200)',linspace(0, 0, 50)');
			outputData2 = dblPupilLightMultiplier*linspace(3, 3, 250)';
			queueOutputData(objDaqOut,[outputData1 outputData2]);
			prepare(objDaqOut);
		end
		
		%retrieve stimulus info
		intStimType = structEP.vecTrialStimTypes(intThisTrial);
		sThisStimObject = sStimObject(intStimType);
		if sThisStimObject.OrientationNoise > 0
			%get random orientation
			dblRandOri = normrnd(sThisStimObject.Orientation,sThisStimObject.OrientationNoise);
			
			%select nearest object
			sStimObjectNoise = cellStimObjectNoise{intStimType};
			[dblOri,intUseObject] = min(abs(cellfun(@minus,cellfill(dblRandOri,size(sStimObjectNoise)),{sStimObjectNoise.Orientation})));
			sThisStimObject = sStimObjectNoise(intUseObject);
		end
		
		%get timing
		dblStartSecs = structEP.vecTrialStartSecs(intThisTrial);
		dblStimOnSecs = structEP.vecTrialStimOnSecs(intThisTrial);
		dblStimOffSecs = structEP.vecTrialStimOffSecs(intThisTrial);
		dblStimDurSecs = dblStimOffSecs - dblStimOnSecs;
		dblEndSecs = structEP.vecTrialEndSecs(intThisTrial);
		
		%load textures
		matGrating = loadStimulusTexture(sThisStimObject,strTexDir,sStimParams);
		intTotFrames = size(matGrating,3);
		intOptimizeForDrawAngle = 0; %optimize for upright
		intSpecialFlags = 0; %1 to put into square opengl texture
		vecTex = nan(1,intTotFrames);
		for intFrame=1:intTotFrames
			vecTex(intFrame)=Screen('MakeTexture', ptrWindow, matGrating(:,:,intFrame), intOptimizeForDrawAngle, intSpecialFlags);
		end
		clear matGrating;
		
		%% pre-load textures
		if boolPreLoadTextures
			[boolResident,vecTexResident] = Screen('PreloadTextures', ptrWindow, vecTex);
		end
		
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
		dblStimStartFlip = dblLastFlip;
		dblCycleDur = 1/sThisStimObject.TemporalFrequency;
		dblPhaseRand = dblCycleDur*rand(1);
		sThisStimObject.Phase = dblPhaseRand;
		dblNextFlip = 0;
		intFlipCounter = 0;
		vecStimFlips = nan(1,ceil(dblStimDurSecs/dblStimFrameDur)*2); %pre-allocate twice as many, just to be safe
		vecStimFrames = nan(size(vecStimFlips));
		boolFirstFlip = false;
		refTimeLocal = tic;
		while toc(refTimeLocal) < (dblStimDurSecs - 2*dblStimFrameDur)
			%draw stimulus
			dblTime = dblLastFlip-dblStimStartFlip;
			tStamp = mod(eps+dblPhaseRand+dblTime,dblCycleDur);
			intFrame = ceil(tStamp * sThisStimObject.FrameRate);
			Screen('DrawTexture',ptrWindow,vecTex(intFrame));
			Screen('DrawingFinished', ptrWindow);
			
			%flip
			dblLastFlip = Screen('Flip', ptrWindow, dblNextFlip);
			dblNextFlip = dblLastFlip + dblStimFrameDur/2;
			intFlipCounter = intFlipCounter + 1;
			vecStimFlips(intFlipCounter) = dblLastFlip;
			vecStimFrames(intFlipCounter) = intFrame;
			
			%send trigger for stim start
			if ~boolFirstFlip
				%set switch
				boolFirstFlip = true;
				
                %log NI timestamp
                if boolUseSGL
%                     dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
					dblStimOnNI = GetStreamSampleCount(hSGL, intStreamNI, strHostAddress)/dblSampFreqNI;
                else
                    dblStimOnNI = nan;
                end
				
				%log flip
				dblStimStartFlip = dblLastFlip;
			end
		end
		vecStimFlips(isnan(vecStimFlips)) = [];
		vecStimFrames(isnan(vecStimFrames)) = [];
		dblStimOnFlip = vecStimFlips(1);
		
		%back to background
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblStimOffFlip = Screen('Flip', ptrWindow, dblLastFlip + dblStimFrameDur/2);
		dblStimDur = dblStimOffFlip-dblStimOnFlip;
		
        %log NI timestamp
        if boolUseSGL
            % 			dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
            dblStimOffNI =  GetStreamSampleCount(hSGL, intStreamNI, strHostAddress)/dblSampFreqNI;
        else
            dblStimOffNI = nan;
        end
		
		%close textures and wait for post trial seconds
		Screen('Close',vecTex);
		clear vecTex;
		
		%% save stimulus object
		try
			%add timestamps
			sThisStimObject.dblStimOnNI = dblStimOnNI;
			sThisStimObject.dblStimOffNI = dblStimOffNI;
			
			%save object
			sObject = sThisStimObject;
			save(fullfile(strTempDir,['Object',num2str(intThisTrial),'.mat']),'sObject');
		catch ME
			warning(ME.identifier,'%s',ME.message);
		end
		
		%% wait post-blanking
		dblTrialDur = 0;
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		dblLastFlip = Screen('Flip', ptrWindow);
		while dblTrialDur < (dblEndSecs - dblStartSecs - 2*dblStimFrameDur)
			%do nothing
			Screen('FillRect',ptrWindow, sStimParams.intBackground);
			dblLastFlip = Screen('Flip', ptrWindow, dblLastFlip + dblStimFrameDur/2);
			dblTrialDur = dblLastFlip - dblTrialStartFlip;
		end
		dblPostBlankDur = dblLastFlip-dblStimOffFlip;
		
		%new stim-based output
		intStimNumber = intThisTrial;
		structEP.TrialNumber(intStimNumber) = intThisTrial;
		structEP.ActStimType(intStimNumber) = intStimType;
		structEP.ActStartSecs(intStimNumber) = dblTrialStartFlip;
		structEP.ActOnSecs(intStimNumber) = dblStimOnFlip;
		structEP.ActOffSecs(intStimNumber) = dblStimOffFlip;
		structEP.ActStopSecs(intStimNumber) = dblLastFlip;
		structEP.ActOnNI(intStimNumber) = dblStimOnNI;
		structEP.ActOffNI(intStimNumber) = dblStimOffNI;
		
		%add grating-specific properties as vectors
		strProps = '';
		for intField=1:numel(cellStimPropNames)
			strField = cellStimPropNames{intField};
			if strcmp(strField,'Phase')
				structEP.(strField)(intStimNumber) = dblPhaseRand*sThisStimObject.TemporalFrequency;
			else
				structEP.(strField)(intStimNumber) = sThisStimObject.(strField);
			end
			strProps = strcat(strProps,strField,'=',num2str(structEP.(strField)(intStimNumber)),';');
		end
		
		%show trial summary
		fprintf('Completed %d/%d at %.3fs (pre=%.3fs,stim=%.3fs,post=%.3fs;tot=%.3fs); %.1f degs; %s\n',intThisTrial,structEP.intTrialNum,dblLastFlip - dblInitialFlip,dblPreBlankDur,dblStimDur,dblPostBlankDur,dblTrialDur,sThisStimObject.Orientation,strProps);
	end
	
	%% save data
	%save data
	structEP.sStimParams = sStimParams;
	structEP.sStimObject = sStimObject;
	structEP.sStimTypeList = sStimTypeList;
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
	%% check if escape
	if strcmp(ME.identifier,'RunDriftingGratings:EscapePressed')
		fprintf('\nEscape pressed at [%s], closing down and cleaning up...\n',getTime);
		%save data
		structEP.sStimParams = sStimParams;
		structEP.sStimObject = sStimObject;
		structEP.sStimTypeList = sStimTypeList;
		save(fullfile(strLogDir,strFilename), 'structEP','sParamsSGL');
		
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
		
	else
		%% catch me and throw me
		fprintf('\n\n\nError occurred! Trying to save data and clean up...\n\n\n');
		
		%save data
		structEP.sStimParams = sStimParams;
		structEP.sStimObject = sStimObject;
		structEP.sStimTypeList = sStimTypeList;
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
end
%end
