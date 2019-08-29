%function structMP = RunReceptiveFieldMapping
%8 seconds per trial
%8 trial types (max 64 seconds per rep)
%10 repetitions = 11 minutes
%80 trials in total

%% suppress m-lint warnings
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>

%% define paths
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
strLogDir = 'E:\Jorrit\Files\Logs'; %where are the logs saved?
strTexSubDir = 'StimulusTextures';
strTexDir = strcat(strThisPath,strTexSubDir); %where are the stimulus textures saved?

%% query user input
%define output filename
fprintf('\n%s started...\n',mfilename);
thisDir = which(mfilename);
intOffset = length(mfilename) + 2;
strDir = thisDir(1:end-intOffset);
fprintf('Saving logs in directory %s; loading textures from %s\n',strLogDir,strTexDir);
strOldPath = cd(strLogDir);
cd(strTexDir);
cd(strOldPath);
boolAcceptInput = false;
while ~boolAcceptInput
	strMouse = input('Block name and mouse (e.g., B3_MouseX): ', 's');
	c = clock;
	strFilename = sprintf('%04d%02d%02d_%s_%s',c(1),c(2),c(3),mfilename,strMouse);
	if isa(strFilename,'char') && ~isempty(strFilename)
		if exist([strLogDir filesep strFilename],'file') || exist([strLogDir filesep strFilename '.mat'],'file')
			warning('off','backtrace')
			warning([mfilename ':PathExists'],'File "%s" already exists!',strFilename);
			warning('on','backtrace')
			strResp = input('Do you want to overwrite the file? (Y/N)','s');
			if strcmpi(strResp,'Y')
				boolAcceptInput = true;
			else
				boolAcceptInput = false;
			end
		else
			boolAcceptInput = true;
		end
	end
end
fprintf('Saving output to file "%s.mat"\n',strFilename);

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
%general variable definitions
sDas = struct;
sDas.dasno = 0;
structEP = struct; %structureElectroPhysiology

%get default settings in Set
runSettingsEphys;

%assign filename
structEP.strFile = mfilename;

%Das Card variable
intDasCard = 1; %0: debug; 1; new USB on Leonie's setup 2: old PCI on Leonie's setup

%screen params
structEP.debug = 0;

%% stimulus params
%visual space parameters
sStimParams = struct;
sStimParams.strStimType = 'SparseCheckers'; %{'SparseCheckers','FlickerCheckers'};
sStimParams.dblSubjectPosX_cm = 0; % cm; relative to center of screen
sStimParams.dblSubjectPosY_cm = -5; % cm; relative to center of screen
sStimParams.dblScreenDistance_cm = 12; % cm; measured 16
sStimParams.vecUseMask = 1; %[1] if mask to emulate retinal-space, [0] use screen-space

%screen variables
sStimParams.intUseScreen = 2; %which screen to use
sStimParams.intCornerTrigger = 1; % integer switch; 0=none,1=upper left, 2=upper right, 3=lower left, 4=lower right
sStimParams.dblCornerSize = 1/30; % fraction of screen width
sStimParams.dblScreenWidth_cm = 51; % cm; measured [51]
sStimParams.dblScreenHeight_cm = 29; % cm; measured [29]
sStimParams.dblScreenWidth_deg = 2 * atand(sStimParams.dblScreenWidth_cm / (2 * sStimParams.dblScreenDistance_cm));
sStimParams.dblScreenHeight_deg = 2 * atand(sStimParams.dblScreenHeight_cm / (2 * sStimParams.dblScreenDistance_cm));

%get screen size from PTB
intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
vecRect=Screen('Rect', sStimParams.intUseScreen);
sStimParams.intScreenWidth_pix = vecRect(3) - vecRect(1);
sStimParams.intScreenHeight_pix = vecRect(4) - vecRect(2);

%receptive field size&location parameters
sStimParams.dblCheckerSizeX_deg = 7; % width of checker
sStimParams.dblCheckerSizeY_deg = 7; % height of checker
sStimParams.intOnOffCheckers = 3; %3/6; how many are on/off at any frame? If flicker, this number is doubled

%stimulus control variables
sStimParams.intUseParPool = 0; %number of workers in parallel pool; [2]
sStimParams.intUseGPU = 1; %set to non-zero to use GPU for rendering stimuli
sStimParams.intAntiAlias = 1; %which level k of anti-alias to use? Grid size is 2^k - 1
sStimParams.dblBackground = 0.5; %background intensity (dbl, [0 1])
sStimParams.intBackground = round(mean(sStimParams.dblBackground)*255);
sStimParams.dblContrast = 100; %contrast; [0-100]
sStimParams.dblFlickerFreq = 5; %Hz
dblInversionDurSecs = (1/sStimParams.dblFlickerFreq)/2; %Hz

%get retinal map
matMapDegsXYD = buildRetinalSpaceMap(sStimParams);

%prepare checker-board stimuli for incremental on-the-fly stimulus creation
[sStimParams,sStimObject,matMapDegsXY_crop,intStimsForMinCoverage] = getSparseCheckerCombos(sStimParams,matMapDegsXYD);

%% initialize parallel pool
if sStimParams.intUseParPool > 0 && isempty(gcp('nocreate'))
	parpool(sStimParams.intUseParPool * [1 1]);
end

%% trial timing variables
structEP.dblSecsBlankAtStart = 3;
structEP.dblSecsBlankPre = 0.3;
structEP.dblSecsStimDur = 0.6;
structEP.dblSecsBlankPost = 0.1;
structEP.dblSecsBlankAtEnd = 3;
dblTrialDur = structEP.dblSecsBlankPre + structEP.dblSecsStimDur + structEP.dblSecsBlankPost ;


%% initialize DasCard & variables
%set bits
sDas.intDasCard = intDasCard;
sDas.TrialBit = 0;  %Marks start of the trial
sDas.StimOnBit = 1; %Stimulus ON bit
sDas.StimOffBit = 2; %Stimulus OFF bit
sDas.ResponseBit = 3; %sync bit (black-white-black for a second, send bit on white) EVERY 100 TRIALS OR SO
sDas.WordDataSwitch = 4;
sDas.WordBitShifter = 5;
sDas.WordDataPorts = [6 7];

%initialize
if intDasCard == 1
	dasinit(sDas.dasno, 2);
	for i = [0 1 2 3 4 5 6 7] %set all to 0
		dasbit(i,0);
	end
elseif intDasCard == 2
	dasinit(sDas.dasno, 2);
	for i = [0 1 2 3 4 5 6 7] %set all to 0
		dasbit(i,0);
	end
	dasclearword;
end

try
	%% INITALIZE SCREEN
	fprintf('Starting PsychToolBox extension...\n');
	%open window
	AssertOpenGL;
	%Screen('Preference', 'SkipSyncTests', 1);
	KbName('UnifyKeyNames');
	intScreen = sStimParams.intUseScreen;
	intOldVerbosity2 = Screen('Preference', 'Verbosity',1); %stop PTB spamming
	if ~exist('intOldVerbosity','var'),intOldVerbosity=intOldVerbosity2;end
	[ptrWindow,vecRect] = Screen('OpenWindow', sStimParams.intUseScreen,sStimParams.intBackground);
	%window variables
	sStimParams.ptrWindow = ptrWindow;
	sStimParams.vecRect = vecRect;
	sStimParams.intScreenWidth_pix = vecRect(3)-vecRect(1);
	sStimParams.intScreenHeight_pix = vecRect(4)-vecRect(2);
	
	%% MAXIMIZE PRIORITY
	priorityLevel=MaxPriority(ptrWindow);
	Priority(priorityLevel);
	
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
	%stim-based logs
	structEP.intStimNumber = 0;
	structEP.TrialNumber = [];
	structEP.ActOnSecs = [];
	structEP.ActOffSecs = [];
	
	%show trial summary
	fprintf('\nFinished preparation at [%s], minimum coverage will take %d presentations (approximately %.2fs)\nWill present sparse checkers until "ESC"\n\n   Waiting for "ENTER"\n',...
		getTime,intStimsForMinCoverage,intStimsForMinCoverage*dblTrialDur);
	
	%wait for enter
	boolEnterPressed = false;
	while ~boolEnterPressed
		boolEnterPressed = CheckEnter();
		pause(0.01);
	end
	
	%set timers
	refTime = tic;
	dblInitialFlip = Screen('Flip', ptrWindow);
	
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
		
		%Send trial start
		if intDasCard > 0
			dasbit(sDas.TrialBit,1);
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
		
		% Send stimulus identification
		if intDasCard == 1
			doWord(intThisTrial);
		elseif intDasCard == 2
			dasword(intThisTrial);
		end
		
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
		while dblPreBlankDur <= (dblStimOnSecs - dblStartSecs - dblStimFrameDur)
			%do nothing
			Screen('FillRect',ptrWindow, sStimParams.intBackground);
			dblLastFlip = Screen('Flip', ptrWindow,dblLastFlip+dblInterFlipInterval/2);
			dblPreBlankDur = dblLastFlip - dblTrialStartFlip;
		end
		
		%% show stimulus
		Screen('DrawTexture',ptrWindow,ptrTex);
		dblLastFlip = Screen('Flip', ptrWindow,dblLastFlip+dblInterFlipInterval/2);
		dblStimOnFlip = dblLastFlip;
		%send trigger pulse
		if intDasCard>0
			dasbit(sDas.StimOnBit, 1);
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
		
		%send trigger for stimulus off
		if intDasCard>0
			dasbit(sDas.StimOffBit, 1);
		end
		
		%close texture and wait for post trial seconds
		Screen('Close',ptrTex);
		clear ptrTex;
		if exist('ptrTexInverted','var')
			Screen('Close',ptrTexInverted);
			clear ptrTexInverted;
		end
		
		%% reset DAS card
		if intDasCard==1
			%reset all bits to null
			for i = [0 1 2 3 4]
				dasbit(i,0);
			end
			
		elseif intDasCard==2
			%reset all bits to null
			for i = [0 1 2 3 4 5 6 7]
				dasbit(i,0);
			end
			dasclearword;
		end
		
		%% save stimulus object
		try
			sObject = sStimObject(end);
			save(strcat(strTempDir,filesep,'Object',num2str(numel(sStimObject)),'.mat'),'sObject');
		catch
			warning([mfilename ':SaveError'],'Error saving temporary stimulus object');
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
		
		%show trial summary
		dblPercDone = 100*sum(sStimObject(end).UsedLinLocOff(:))/numel(sStimObject(end).UsedLinLocOff);
		fprintf('Completed trial %d at time=%.3fs (stim dur=%.3fs); coverage is now %.1f%%; Stim creation took %.3fs\n',intThisTrial,dblLastFlip - dblInitialFlip,dblStimOffFlip-dblStimOnFlip,dblPercDone,dblCreationDur);
	end
	
	%% save data
	%save data
	structEP.sStimParams = sStimParams;
	structEP.sStimObject = sStimObject;
	save([strLogDir filesep strFilename], 'structEP','sDas');
	
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
catch
	%% catch me and throw me
	fprintf('\n\n\nError occurred! Trying to save data and clean up...\n\n\n');
	
	%save data
	structEP.sStimParams = sStimParams;
	structEP.sStimObject = sStimObject;
	save([strLogDir filesep strFilename], 'structEP','sDas');
	
	%% catch me and throw me
	Screen('Close');
	Screen('CloseAll');
	ShowCursor;
	Priority(0);
	Screen('Preference', 'Verbosity',intOldVerbosity);
	
	%% close DAS
	%Reset all bits
	if intDasCard==1
		%reset all bits to null
		for i = [0 1 2 3 4 5 6 7]
			dasbit(i,0);
		end
	elseif intDasCard==2
		%reset all bits to null
		for i = [0 1 2 3 4 5 6 7]
			dasbit(i,0);
		end
		dasclearword;
	end
	
	%% show error
	rethrow(lasterror); %#ok<LERR>
end
%end
