%function structEP = RunNaturalMovie

%% suppress m-lint warnings
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>
clear all;
close all;

%% define paths
boolUseSGL = true;
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
strSessionDir = strcat('C:\_Data\Exp',getDate()); %where are the logs saved?
strTexSubDir = 'StimulusTextures';
strTexDir = strcat(strThisPath,strTexSubDir); %where are the stimulus textures saved?
if ~exist(strTexDir,'dir'),mkdir(strTexDir);end

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
catch ME
	dispErr(ME);
	if boolUseSGL
		CloseSGL(hSGL);
	end
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
	mkdir(strTempDir);
end

%% general parameters
fprintf('Preparing variables...\n');
%general variable definitions
structEP = struct; %structureElectroPhysiology

%get default settings in Set
intUseDaqDevice = 1; %set to 0 to skip I/O

%assign filename
structEP.strFile = mfilename;

%screen params
structEP.debug = 1;

%% stimulus params
%visual space parameters
sStimParams = struct;
sStimParams.strStimType = 'NaturalMovie';
sStimParams.dblSubjectPosX_cm = 0; % cm; relative to center of screen
sStimParams.dblSubjectPosY_cm = 0; %-3.5 cm; relative to center of screen
sStimParams.dblScreenDistance_cm = 30;%14; % cm; measured
sStimParams.vecUseMask = 0; %[1] if mask to emulate retinal-space, [0] use screen-space

%receptive field size&location parameters
sStimParams.vecStimPosX_deg = 0; % deg; relative to subject
sStimParams.vecStimPosY_deg = 0; % deg; relative to subject
sStimParams.vecSceneSize_deg = 40;%stimulus will be assumed to be this size
sStimParams.vecStimulusSize_deg = 0;%circular window in degrees [35]
sStimParams.vecSoftEdge_deg = 2; %width of cosine ramp  in degrees, [0] is hard edge

%screen variables
sStimParams.intUseScreen = 2; %which screen to use
sStimParams.intCornerTrigger = 2; % integer switch; 0=none,1=upper left, 2=upper right, 3=lower left, 4=lower right
sStimParams.dblCornerSize = 1/30; % fraction of screen width
sStimParams.dblScreenWidth_cm = 51; % cm; measured [51]
sStimParams.dblScreenHeight_cm = 29; % cm; measured [29]
sStimParams.dblScreenWidth_deg = 2 * atand(sStimParams.dblScreenWidth_cm / (2 * sStimParams.dblScreenDistance_cm));
sStimParams.dblScreenHeight_deg = 2 * atand(sStimParams.dblScreenHeight_cm / (2 * sStimParams.dblScreenDistance_cm));

%stimulus control variables
sStimParams.intUseParPool = 0; %number of workers in parallel pool; [2]
sStimParams.intUseGPU = 1;
sStimParams.intAntiAlias = 0;
sStimParams.vecBackgrounds = 0.5; %background intensity (dbl, [0 1])
sStimParams.intBackground = round(mean(sStimParams.vecBackgrounds)*255);
sStimParams.vecContrasts = [100];
sStimParams.vecLuminances = [100];
sStimParams.vecScenes = [1]; %1: condor flight school
sStimParams.strScene = 'CondorFlightSchool'; %description
		
%build single-repetition list
[sStimParams,sStimObject,sStimTypeList] = getNaturalMovieCombos(sStimParams);

%% initialize parallel pool && gpu
if sStimParams.intUseParPool > 0 && isempty(gcp('nocreate'))
	parpool(sStimParams.intUseParPool * [1 1]);
end
if sStimParams.intUseGPU > 0
	objGPU = gpuDevice(sStimParams.intUseGPU);
end

%% trial timing variables
structEP.intNumRepeats = 100;
structEP.dblSecsBlankAtStart = 3;
structEP.dblSecsBlankPre = 0;
structEP.dblSecsStimDur = 20;
structEP.dblSecsBlankPost = 0;
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
%initialize
fprintf('Connecting to National Instruments box...\n');
strDataOutFile = strcat(strOutputDir,strFilename,'PhotoDiode','.csv');
boolDaqIn = boolUseSGL;
try
	if boolDaqIn,objDAQIn = openDaqInput(intUseDaqDevice,strDataOutFile);end
catch ME
	if strcmp(ME.identifier,'nidaq:ni:DAQmxResourceReserved')
		fprintf('NI DAQ is likely already being recorded by SpikeGLX: skipping PhotoDiode logging\n');
		boolDaqIn = false;
	else
		rethrow(ME);
	end
end
if boolUseSGL,objDAQOut = openDaqOutput(intUseDaqDevice);end

try
	%% INITALIZE SCREEN
	fprintf('Starting PsychToolBox extension...\n');
	%open window
	AssertOpenGL;
	KbName('UnifyKeyNames');
	intScreen = sStimParams.intUseScreen;
	intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
	if ~boolUseSGL,Screen('Preference', 'SkipSyncTests', 1);end
	[ptrWindow,vecRect] = Screen('OpenWindow', sStimParams.intUseScreen,sStimParams.intBackground);
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
	fprintf('\nChecking textures...');
	boolPreLoadTextures = true;
	for intStimType = 1:structEP.intStimTypes
		sStimObject(intStimType).FrameRate = intStimFrameRate;
		[matSceneFrames,vecSceneFrameIDs] = loadStimulusTexture(sStimObject(intStimType),strTexDir,sStimParams);
	end
	fprintf('   Done\n');
	
	%% attempt to pre-load textures
	if boolPreLoadTextures
		fprintf('\nAttempting texture pre-loading...');
		try
			%draw textures
			[matSceneFrames,vecSceneFrameIDs] = loadStimulusTexture(sStimObject(1),strTexDir,sStimParams);
			intTexD = ndims(matSceneFrames);
			intTotFrames = size(matSceneFrames,intTexD);
			intOptimizeForDrawAngle = 0; %optimize for upright
			intSpecialFlags = 0; %1 to put into square opengl texture
			vecTex = nan(1,intTotFrames);
			if intTexD == 3 %grey
				for intFrame=1:intTotFrames
					vecTex(intFrame)=Screen('MakeTexture', ptrWindow, matSceneFrames(:,:,intFrame), intOptimizeForDrawAngle, intSpecialFlags);
				end
			elseif intTexD == 4 %color
				for intFrame=1:intTotFrames
					vecTex(intFrame)=Screen('MakeTexture', ptrWindow, matSceneFrames(:,:,:,intFrame), intOptimizeForDrawAngle, intSpecialFlags);
				end
			end
			clear matSceneFrames;
			
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
	intLastType = 1;
	sThisStimObject = sStimObject(1);
	for intThisTrial = 1:structEP.intTrialNum
		%% check escape
		if CheckEsc(),error([mfilename ':EscapePressed'],'Esc pressed; exiting');end
		%% prep trial
		
		%trial start
		dblTrialStartFlip = Screen('Flip', ptrWindow);
		
		%fill DAQ with data
		if boolUseSGL
			stop(objDAQOut);
			outputData1 = cat(1,linspace(1.5, 1.5, 200)',linspace(0, 0, 50)');
			outputData2 = linspace(3, 3, 250)';
			queueOutputData(objDAQOut,[outputData1 outputData2]);
		end
		
		%get timing
		dblStartSecs = structEP.vecTrialStartSecs(intThisTrial);
		dblStimOnSecs = structEP.vecTrialStimOnSecs(intThisTrial);
		dblStimOffSecs = structEP.vecTrialStimOffSecs(intThisTrial);
		dblStimDurSecs = dblStimOffSecs - dblStimOnSecs;
		dblEndSecs = structEP.vecTrialEndSecs(intThisTrial);
		
		%retrieve stimulus info
		intStimType = structEP.vecTrialStimTypes(intThisTrial);
		if intLastType ~= intStimType
			%if stimulus type has changed, close textures
			Screen('Close',vecTex);
			clear vecTex;
			
			%load new data
			intLastType = intStimType;
			sThisStimObject = sStimObject(intStimType);
			
			%load textures
			matSceneFrames = loadStimulusTexture(sThisStimObject,strTexDir,sStimParams);
			intTexD = ndims(matSceneFrames);
			intTotFrames = size(matSceneFrames,intTexD);
			intOptimizeForDrawAngle = 0; %optimize for upright
			intSpecialFlags = 0; %1 to put into square opengl texture
			vecTex = nan(1,intTotFrames);
			if intTexD == 3 %grey
				for intFrame=1:intTotFrames
					vecTex(intFrame)=Screen('MakeTexture', ptrWindow, matSceneFrames(:,:,intFrame), intOptimizeForDrawAngle, intSpecialFlags);
				end
			elseif intTexD == 4 %color
				for intFrame=1:intTotFrames
					vecTex(intFrame)=Screen('MakeTexture', ptrWindow, matSceneFrames(:,:,:,intFrame), intOptimizeForDrawAngle, intSpecialFlags);
				end
			end
			clear matSceneFrames;
			
			%% pre-load textures
			if boolPreLoadTextures
				[boolResident,vecTexResident] = Screen('PreloadTextures', ptrWindow, vecTex);
			end
		end
		
		%% wait pre-blanking
		dblPreBlankDur = 0;
		dblDAQ_Dur = 0.1; %measured time to set NI DAQ switch
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
		dblNextFlip = 0;
		intFlipCounter = 0;
		vecStimFlips = nan(1,ceil(dblStimDurSecs/dblStimFrameDur)*2); %pre-allocate twice as many, just to be safe
		vecStimFrames = nan(size(vecStimFlips));
		boolFirstFlip = false;
		refTimeLocal = tic;
		while toc(refTimeLocal) < (dblStimDurSecs - dblStimFrameDur)
			%send trigger for stim start
			if ~boolFirstFlip
				%set switch
				boolFirstFlip = 1;
				
				%log NI timestamp
				if boolUseSGL,dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;end
			end
			
			%draw stimulus
			dblTime = toc(refTimeLocal);
			tStamp = mod(eps+dblTime,dblStimDurSecs);
			intFrame = vecSceneFrameIDs(ceil(tStamp * sThisStimObject.FrameRate));
			Screen('DrawTexture',ptrWindow,vecTex(intFrame));
			Screen('DrawingFinished', ptrWindow);
			
			%flip
			dblLastFlip = Screen('Flip', ptrWindow, dblNextFlip);
			dblNextFlip = dblLastFlip + dblStimFrameDur/2;
			intFlipCounter = intFlipCounter + 1;
			vecStimFlips(intFlipCounter) = dblLastFlip;
			vecStimFrames(intFlipCounter) = intFrame;
		end
		vecStimFlips(isnan(vecStimFlips)) = [];
		vecStimFrames(isnan(vecStimFrames)) = [];
		dblStimOnFlip = vecStimFlips(1);
		
		%back to background
		dblStimOffFlip = dblNextFlip;
		
		%log NI timestamp
		if boolUseSGL,dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;end
		
		%% save stimulus object
		try
			%add timestamps
			if boolUseSGL
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
		dblTrialDur = dblLastFlip - dblTrialStartFlip;
		while dblTrialDur < (dblEndSecs - dblStartSecs - 2*dblStimFrameDur)
			%do nothing
			Screen('FillRect',ptrWindow, sStimParams.intBackground);
			dblLastFlip = Screen('Flip', ptrWindow, dblLastFlip + dblStimFrameDur/2);
			dblTrialDur = dblLastFlip - dblTrialStartFlip;
		end
		
		%new stim-based output
		intStimNumber = intThisTrial;
		structEP.TrialNumber(intStimNumber) = intThisTrial;
		structEP.ActStimType(intStimNumber) = intStimType;
		structEP.ActStartSecs(intStimNumber) = dblTrialStartFlip;
		structEP.ActOnSecs(intStimNumber) = dblStimOnFlip;
		structEP.ActOffSecs(intStimNumber) = dblStimOffFlip;
		structEP.ActEndSecs(intStimNumber) = dblLastFlip;
		
		%add stimulus-specific properties as vectors
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
		fprintf('Completed trial %d of %d at time=%.3fs (stim dur=%.3fs); stimulus was %.1f degrees; %s\n',intThisTrial,structEP.intTrialNum,dblLastFlip - dblInitialFlip,dblStimOffFlip-dblStimOnFlip,sThisStimObject.Scene,strProps);
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
	CloseSGL(hSGL);
	
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
