function [sTrialData,sStimParams]=RunAsyncStim()
	
	%% switches
	boolDebug = false;
	
	%% start memory maps
	mmapSignal = JoinMemMap('dataswitch');
	
	%% load stim params
	mmapParams = JoinMemMap('sStimParams');
	sStimParams = mmapParams.Data;
	if isscalar(sStimParams) && sStimParams == 0
		error([mfilename ':DataMapNotInitialized'],'Data transfer failed. Did you start the other matlab first?');
	end
	strHostAddress = sStimParams.strHostAddress;
	
	%% connect to spikeglx
	hSGL = SpikeGL(strHostAddress);
	
	%% start PTB
	try
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
		
		% MAXIMIZE PRIORITY
		intOldPriority = 0;
		if boolDebug == 0
			intPriorityLevel=MaxPriority(ptrWindow);
			intOldPriority = Priority(intPriorityLevel);
		end
		
		% get refresh rate
		dblStimFrameRate=Screen('FrameRate', ptrWindow);
		intStimFrameRate = round(dblStimFrameRate);
		dblStimFrameDur = mean(1/dblStimFrameRate);
		dblInterFlipInterval = Screen('GetFlipInterval', ptrWindow);
		if dblStimFrameDur/dblInterFlipInterval > 1.05 || dblStimFrameDur/dblInterFlipInterval < 0.95
			warning([mfilename ':InconsistentFlipDur'],sprintf('Something iffy with flip speed and monitor refresh rate detected; frame duration is %fs, while flip interval is %fs!',dblStimFrameDur,dblInterFlipInterval));
		end
		
		%% pre-allocate
		sTrialData=struct;
		sTrialData.TrialNumber = [];
		sTrialData.ActStimType = [];
		sTrialData.ActOnNI = [];
		sTrialData.ActOffNI = [];
		
		%% run until we get the signal to stop
		intStimNumber = mmapSignal.Data(1);
		intTrialCounter = 0;
		while intStimNumber ~= -1
			%check if we need to show a new stimulus
			intStimNumber = mmapSignal.Data(1);
			intStimType = mmapSignal.Data(2);
			if intStimNumber > 0
				%% set counter
				intTrialCounter = intTrialCounter + 1;
				
				%% call PresentFlyOver
				[dblStimOnNI,dblStimOffNI]=PresentFlyOver(hSGL,ptrWindow,intStimNumber,intStimType,sStimParams);
				
				%% save data
				sTrialData.TrialNumber(intTrialCounter) = intStimNumber;
				sTrialData.ActStimType(intTrialCounter) = intStimType;
				sTrialData.ActOnNI(intTrialCounter) = dblStimOnNI;
				sTrialData.ActOffNI(intTrialCounter) = dblStimOffNI;
				
				%% reset signal
				mmapSignal.Data=[0 0];
			end
			%pause to avoid cpu overload
			pause(0.01);
		end
		
		%% export all data
		mmapData = InitMemMap('sTrialData',sTrialData);
		
		%signal we're done
		mmapSignal.Data(1) = -2;
		mmapSignal.Data(2) = -2;
		
		%% close PTB
		Screen('Close',ptrWindow);
		Screen('CloseAll');
		ShowCursor;
		Priority(0);
		Screen('Preference', 'Verbosity',intOldVerbosity);
		
		%% wait until data has been received
		while mmapSignal.Data(1) ~= -3
			pause(0.1);
		end
		
	catch ME
		%% catch me and throw me
		Screen('Close');
		Screen('CloseAll');
		ShowCursor;
		Priority(0);
		Screen('Preference', 'Verbosity',intOldVerbosity);
		%% show error
		rethrow(ME);
	end
end