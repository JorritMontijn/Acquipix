%% recordings
clear all;close all;
%sites
cellRec{1}{1} = 'P:\Montijn\DataNeuropixels\Exp2020-11-10\20201110_Teddy1_54690_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\Montijn\DataNeuropixels\Exp2020-11-11\20201111_teddy1_54690_set1_RunNaturalMovieR01_g0';

matRunPre = [...
	1 1;...
	1 2];

%											0=none, 1=KS, 2=eye,3=post,4=area+depth

for intRunPrePro=1:size(matRunPre,1)
%% clear variables and select session to preprocess
clearvars -except cellRec matRunPre intRunPrePro
runPreGLX = matRunPre(intRunPrePro,:);
fprintf('Starting pre-processing of "%s" [%s]\n',cellRec{runPreGLX(1)}{runPreGLX(2)},getTime);

%% path definitions
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
addpath(genpath('C:\Code\Acquisition\Kilosort2')); % path to kilosort folder
addpath('C:\Code\Acquisition\npy-matlab'); % for converting to Phy
rootZ = cellRec{runPreGLX(1)}{runPreGLX(2)}; % the raw data binary file is in this folder
strTempDirDefault = 'E:\_TempData'; % path to temporary binary file (same size as data, should be on fast SSD)
strPathToConfigFile = strcat(strThisPath,'subfunctionsPP',filesep); % take from Github folder and put it somewhere else (together with the master_file)
chanMapFile = 'neuropixPhase3B2_kilosortChanMap.mat';

%% check which temp folder to use & clear data
sTempFiles = dir(fullfile(strTempDirDefault,'*.dat'));
for intTempFile=1:numel(sTempFiles)
	boolDir = sTempFiles(intTempFile).isdir;
	strFile = sTempFiles(intTempFile).name;
	if ~boolDir
		delete(fullfile(strTempDirDefault,strFile));
		fprintf('Deleted "%s" from temporary path "%s" [%s]\n',strFile,strTempDirDefault,getTime);
	end
end
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
objFile      = java.io.File('C:\');
dblFreeBytes   = objFile.getFreeSpace;
dblFileSize = fs(1).bytes;
fprintf('Processing "%s" (%.1fGB)\n',fs(1).name,dblFileSize/(1024.^3));
if dblFreeBytes > (dblFileSize*1.05)
	strTempDir = strTempDirDefault;
	fprintf('Using temp dir "%s" (%.1fGB free)\n',strTempDir,dblFreeBytes/(1024.^3));
else
	strTempDir(1) = 'D';
	fprintf('Not enough space on SSD (%.1fGB free). Using temp dir "%s"\n',dblFreeBytes/(1024.^3),strTempDir);
end

%% load SpikeGLX data and fill in some values
%get initial ops struct
ops = struct;
run(fullfile(strPathToConfigFile, 'configFile384_Montijn.m'));
ops.fbinary = fullfile(rootZ, fs(1).name);

%load GLX data
sMeta = DP_ReadMeta(ops.fbinary);
ops.fs = DP_SampRate(sMeta); %sampling rate
[AP,LF,SY] = DP_ChannelCountsIM(sMeta); %IM channels
ops.trange = [0 Inf]; % time range to sort
ops.NchanTOT    = AP + LF + SY; % total number of channels
ops.fproc       = fullfile(strTempDir, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(strPathToConfigFile, chanMapFile);

%% this block runs all the steps of the algorithm
fprintf('Looking for data inside %s \n', rootZ)

% is there a channel map file in this folder?
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
    ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
ops.fbinary = fullfile(rootZ, fs(1).name);

% preprocess data to create temp_wh.dat
rez = preprocessDataSub(ops);

% time-reordering as a function of drift
rez = clusterSingleBatches(rez);

% saving here is a good idea, because the rest can be resumed after loading rez
save(fullfile(rootZ, 'rez.mat'), 'rez', '-v7.3');

% main tracking and template matching algorithm
rez = learnAndSolve8b(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% final splits by amplitudes
rez = splitAllClusters(rez, 0);

% decide on cutoff
rez = set_cutoff(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, rootZ);

%% if you want to save the results to a Matlab file...
% discard features in final rez file (too slow to save)
rez.cProj = [];
rez.cProjPC = [];

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(rootZ, 'rez2.mat');
save(fname, 'rez', '-v7.3');
end