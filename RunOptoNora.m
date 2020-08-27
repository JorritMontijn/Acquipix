%function structEP = RunDriftingGratings

%% suppress m-lint warnings
%#ok<*MCCD,*NASGU,*ASGLU,*CTCH>
clear all;
close all;

%% define variables
intStimSet = 1;% 1=0:15:359, reps20; 2=[0 5 90 95], reps 400 with noise
boolUseSGL = false;
boolUseDaq = true;
intDebug = 0;

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

dblPrePostWait = 60;%secs
dblSamplingRate = 10000;%Hz
intRepsPerPulse = 5;%count
intTrialNum = 500;%count
dblPulseWait = 2;%secs
vecPulseITI = 1./[1 2 5 10 20 50 100];%secs
dblPulseDur = 5/1000;%secs
vecPulseDur = dblPulseDur*ones(size(vecPulseITI));%secs
end

%% generate data
cellPulseData = cell(1,intTrialNum);
cellPulseITI = cell(1,intTrialNum);
cellPulseDur = cell(1,intTrialNum);
for intTrial=1:intTrialNum
	%shuffle order
	vecRand = randperm(numel(vecPulseITI));
	vecShuffITI = vecPulseITI(vecRand);
	vecShuffDur = vecPulseDur(vecRand);
	vecData = uint8([]);
	
	for intPulseType=1:numel(vecShuffITI) 
		vecOnePulse = uint8(cat(1,ones(round(vecShuffDur(intPulseType)*dblSamplingRate),1),zeros(round(vecShuffITI(intPulseType)*dblSamplingRate),1)));
		vecPulses = repmat(vecOnePulse,[intRepsPerPulse 1]);
		vecWait = uint8(zeros(round(dblSamplingRate*dblPulseWait),1));
		vecData = cat(1,vecData,vecPulses,vecWait);
	end
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

%% general parameters
fprintf('Preparing variables...\n');
%general variable definitions
structEP = struct; %structureElectroPhysiology

%get default settings in Set
intUseDaqDevice = boolUseDaq; %set to 0 to skip I/O

%assign filename
structEP.strFile = mfilename;

%screen params
structEP.debug = intDebug;

%% stimulus params
%visual space parameters
sStimParamsSettings = struct;
sStimParamsSettings.strStimType = 'OptoNora';

%% initialize NI I/O box

try
	%% start pre-wait
	
	%% run stimuli
	%check for escape in-between pulse runs
	
	%log timestamps & save after each trial
	%cellPulseData{intTrial} = vecData;
	%cellPulseITI{intTrial} = vecShuffITI;
	%cellPulseDur{intTrial} = vecShuffDur;
	
	%[strOutputDir filesep strFilename]
	
	%% end-wait
	fprintf('\nExperiment is finished at [%s], closing down and cleaning up...\n',getTime);
	
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
