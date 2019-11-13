%function structEP = RunDriftingGratings

%% suppress m-lint warnings
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>
clear all;
close all;

%% define variables
intStimSet = 1;% 1=0:15:359, reps20; 2=[0 5 90 95], reps 800 with noise
boolUseSGL = true;
intDebug = 0;
intUseMask = 0;
dblStimSizeDegs = 120;

%% define paths
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
strSessionDir = strcat('C:\_Data\Exp',getDate()); %where are the logs saved?
strTexSubDir = 'StimulusTextures';
strTexDir = strcat(strThisPath,strTexSubDir); %where are the stimulus textures saved?


%% query user input for recording name
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
	fprintf('Saving output in directory %s; loading textures from %s\n',strSessionDir,strTexDir);
	strOldPath = cd(strTexDir);
	cd(strOldPath);
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

%% check if temporary directory exists, clean or make
strTempDir = 'X:\JorritMontijn\TempObjects';
if exist(strTempDir,'dir')
	warning('off','backtrace')
	warning([mfilename ':PathExists'],'Path "%s" already exists!',strTempDir);
	warning('on','backtrace')
	sFiles = dir(strcat(strTempDir,filesep,'*.mat'));
	intFileNum = numel(sFiles);
	if intFileNum > 0
		strCleanFiles = input(sprintf('   Do you wish to delete all %d files in the temporary folder? [y/n]',intFileNum), 's');
		if strcmpi(strCleanFiles,'y')
			fprintf('Deleting %d .mat files...\n',intFileNum);
			for intFile=1:intFileNum
				delete(strcat(strTempDir,filesep,sFiles(intFile).name));
			end
			fprintf('\b  Done!\n');
		end
	end
else
	if exist('X:\JorritMontijn\','dir')
		mkdir(strTempDir);
	else
		sME.identifier = [mfilename ':NetworkDirMissing'];
		sME.message = ['Cannot connect to ' strTempDir];
		error(sME);
	end
end

%% general parameters
fprintf('Preparing variables...\n');
%general variable definitions
structEP = struct; %structureElectroPhysiology

%get default settings in Set
intUseDaqDevice = boolUseSGL; %set to 0 to skip I/O

%assign filename
structEP.strFile = mfilename;

%screen params
structEP.debug = intDebug;

%% stimulus params
%visual space parameters
sStimParamsSettings = struct;
sStimParamsSettings.strStimType = 'SquareGrating';
sStimParamsSettings.dblSubjectPosX_cm = 0; % cm; relative to center of screen
sStimParamsSettings.dblSubjectPosY_cm = -3.5; % cm; relative to center of screen
sStimParamsSettings.dblScreenDistance_cm = 14; % cm; measured
sStimParamsSettings.vecUseMask = intUseMask; %[1] if mask to emulate retinal-space, [0] use screen-space

%receptive field size&location parameters
sStimParamsSettings.vecStimPosX_deg = -20; % deg; relative to subject
sStimParamsSettings.vecStimPosY_deg = 0; % deg; relative to subject
sStimParamsSettings.vecStimulusSize_deg = dblStimSizeDegs;%circular window in degrees [35]
sStimParamsSettings.vecSoftEdge_deg = 2; %width of cosine ramp  in degrees, [0] is hard edge

%screen variables
sStimParamsSettings.intUseScreen = 2; %which screen to use
sStimParamsSettings.intCornerTrigger = 2; % integer switch; 0=none,1=upper left, 2=upper right, 3=lower left, 4=lower right
sStimParamsSettings.dblCornerSize = 1/30; % fraction of screen width
sStimParamsSettings.dblScreenWidth_cm = 51; % cm; measured [51]
sStimParamsSettings.dblScreenHeight_cm = 29; % cm; measured [29]
sStimParamsSettings.dblScreenWidth_deg = 2 * atand(sStimParamsSettings.dblScreenWidth_cm / (2 * sStimParamsSettings.dblScreenDistance_cm));
sStimParamsSettings.dblScreenHeight_deg = 2 * atand(sStimParamsSettings.dblScreenHeight_cm / (2 * sStimParamsSettings.dblScreenDistance_cm));

%stimulus control variables
sStimParamsSettings.intUseParPool = 0; %number of workers in parallel pool; [2]
sStimParamsSettings.intUseGPU = 1;
sStimParamsSettings.intAntiAlias = 0;
sStimParamsSettings.str90Deg = '0 degrees is rightward motion; 90 degrees is upward motion';
sStimParamsSettings.vecBackgrounds = 0.5; %background intensity (dbl, [0 1])
sStimParamsSettings.intBackground = round(mean(sStimParamsSettings.vecBackgrounds)*255);
sStimParamsSettings.vecContrasts = 100; %contrast; [0-100]
sStimParamsSettings.vecSpatialFrequencies = 0.05; %Spat Frequency in cyc/deg 0.08
sStimParamsSettings.vecTemporalFrequencies = 1; %Temporal frequency in cycles per second (0 = static gratings only)
%orientations&noise
if intStimSet == 1
	intNumRepeats = 20;
	sStimParamsSettings.vecOrientations = [0:15:359]; %orientation (0 is drifting rightward)
	sStimParamsSettings.vecOrientationNoise = zeros(size(sStimParamsSettings.vecOrientations)); %noise in degrees
elseif intStimSet == 2
	intNumRepeats = 800;
	sStimParamsSettings.vecOrientations = [0 5 90 95]; %orientation (0 is drifting rightward)
	sStimParamsSettings.vecOrientationNoise = [0 2 0 2]; %noise in degrees
end

%get stimuli
[sStimParams,sStimObject,sStimTypeList] = getDriftingGratingCombos(rmfield(sStimParamsSettings,'vecOrientationNoise'));
for intObject=1:numel(sStimObject)
	sStimObject(intObject).OrientationNoise = sStimParamsSettings.vecOrientationNoise(intObject);
end

%get noise stimuli
cellStimObjectNoise = cell(1,numel(sStimObject));
vecStimsWithNoise = find(sStimParamsSettings.vecOrientationNoise > 0);
for intNoiseStim=1:numel(vecStimsWithNoise)
	intStim = vecStimsWithNoise(intNoiseStim);
	dblOri = sStimParamsSettings.vecOrientations(intStim);
	dblNoise = sStimParamsSettings.vecOrientationNoise(intStim);
	vecNoiseStims = [dblOri-dblNoise*3:0.1:dblOri+dblNoise*3];
	intNoiseStims = numel(vecNoiseStims);
	fprintf('Loading %d noise stimuli for stim %d [%s]\n',intNoiseStims,numel(vecStimsWithNoise),getTime);
	sStimParamsNoiseStim = rmfield(sStimParamsSettings,'vecOrientationNoise');
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

%% trial timing variables
if ~exist('intNumRepeats','var'),intNumRepeats = 10;end
structEP.intNumRepeats = intNumRepeats;
structEP.dblSecsBlankAtStart = 3;
structEP.dblSecsBlankPre = 0.4;
structEP.dblSecsStimDur = 1;
structEP.dblSecsBlankPost = 0.1;
structEP.dblSecsBlankAtEnd = 3;

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
if boolUseSGL
	%initialize
	fprintf('Connecting to National Instruments box...\n');
	strDataOutFile = strcat(strOutputDir,strFilename,'PhotoDiode','.csv');
	boolDaqIn = true;
	try
		objDAQIn = openDaqInput(intUseDaqDevice,strDataOutFile);
	catch ME
		if strcmp(ME.identifier,'nidaq:ni:DAQmxResourceReserved')
			fprintf('NI DAQ is likely already being recorded by SpikeGLX: skipping PhotoDiode logging\n');
			boolDaqIn = false;
		else
			rethrow(ME);
		end
	end
	objDAQOut = openDaqOutput(intUseDaqDevice);
end

try
	%% INITALIZE SCREEN
	fprintf('Starting PsychToolBox extension...\n');
	%open window
	AssertOpenGL;
	KbName('UnifyKeyNames');
	intScreen = sStimParams.intUseScreen;
	intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
	try
		Screen('Preference', 'SkipSyncTests', 0);
		[ptrWindow,vecRect] = Screen('OpenWindow', sStimParams.intUseScreen,sStimParams.intBackground);
	catch ME
		warning([mfilename ':ErrorPTB'],'Psychtoolbox error, attempting with sync test skip [msg: %s]',ME.message);
		Screen('Preference', 'SkipSyncTests', 1);
		[ptrWindow,vecRect] = Screen('OpenWindow', sStimParams.intUseScreen,sStimParams.intBackground);
	end
	%window variables
	sStimParams.ptrWindow = ptrWindow;
	sStimParams.vecRect = vecRect;
	sStimParams.intScreenWidth_pix = vecRect(3)-vecRect(1);
	sStimParams.intScreenHeight_pix = vecRect(4)-vecRect(2);
	
	%% MAXIMIZE PRIORITY
	%priorityLevel=MaxPriority(ptrWindow);
	%Priority(priorityLevel);
	
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
	structEP.ActOnSecs = nan(1,structEP.intStimNumber);
	structEP.ActOffSecs = nan(1,structEP.intStimNumber);
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
		if boolUseSGL
		stop(objDAQOut);
		outputData1 = cat(1,linspace(1.5, 1.5, 200)',linspace(0, 0, 50)');
		outputData2 = linspace(3, 3, 250)';
		queueOutputData(objDAQOut,[outputData1 outputData2]);
		prepare(objDAQOut);
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
		if boolUseSGL,startBackground(objDAQOut);end
		
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
				boolFirstFlip = 1;
				
				%log NI timestamp
				if boolUseSGL,dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;end
				
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
		if boolUseSGL,dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;end
				
		%close textures and wait for post trial seconds
		Screen('Close',vecTex);
		clear vecTex;
		
		%% save stimulus object
		try
			%add timestamps
			if boolUseSGL,
			sThisStimObject.dblStimOnNI = dblStimOnNI;
			sThisStimObject.dblStimOffNI = dblStimOffNI;
			end
			%save object
			sObject = sThisStimObject;
			save(strcat(strTempDir,filesep,'Object',num2str(intThisTrial),'.mat'),'sObject');
		catch
			warning([mfilename ':SaveError'],'Error saving temporary stimulus object');
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
		structEP.ActEndSecs(intStimNumber) = dblLastFlip;
		
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
	save([strOutputDir filesep strFilename], 'structEP','sParamsSGL');
	
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
	
	%end recording
	if boolUseSGL,CloseSGL(hSGL);end
	
	%close Daq IO
	if intUseDaqDevice > 0
		if boolDaqIn
			closeDaqInput(objDAQIn);
		end
		closeDaqOutput(objDAQOut);
	end
catch ME
	%% catch me and throw me
	fprintf('\n\n\nError occurred! Trying to save data and clean up...\n\n\n');
	
	%save data
	structEP.sStimParams = sStimParams;
	structEP.sStimObject = sStimObject;
	structEP.sStimTypeList = sStimTypeList;
	save([strOutputDir filesep strFilename], 'structEP');
	
	%% catch me and throw me
	Screen('Close');
	Screen('CloseAll');
	ShowCursor;
	Priority(0);
	Screen('Preference', 'Verbosity',intOldVerbosity);
	
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
