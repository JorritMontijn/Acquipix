%% to run phy for clustering after finishing this script:
% 1) open anaconda
% 2) go to your output directory (i.e., [ops.root ops.rec]) (e.g., P:\Montijn\DataNeuropixels\Exp2019-11-20\20191120_MP2_RunDriftingGratingsR01_g0)
% 3) type: activate phy
% 4) type: phy template-gui params.py
%
% For more info on phy-contrib's template-gui, see: 
%	https://github.com/kwikteam/phy-contrib/blob/master/docs/template-gui.md
%
%You can also directly copy these lines (one by one) into the matlab
%command window  (but note that matlab is locked in the mean time)
%{
!cmd
D:
cd D:\Data\Raw\ePhys\KiloSortBinaries\Roku_20180514_B5
C:\ProgramData\Miniconda3\Scripts\activate.bat C:\ProgramData\Miniconda3
activate phy
phy template-gui params.py
exit
%}
%% recordings
clear all;close all;
%sites
cellRec{1}{1} = 'P:\Montijn\DataNeuropixels\Exp2019-11-20\20191120_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\Montijn\DataNeuropixels\Exp2019-11-21\20191121_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{3} = 'P:\Montijn\DataNeuropixels\Exp2019-11-22\20191122_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{4} = 'P:\Montijn\DataNeuropixels\Exp2019-11-22\20191122_MP2_R02_RunDriftingGratingsR01_g0';
cellRec{2}{1} = 'P:\Montijn\DataNeuropixels\Exp2019-12-10\20191210_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{2} = 'P:\Montijn\DataNeuropixels\Exp2019-12-11\20191210_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{3} = 'P:\Montijn\DataNeuropixels\Exp2019-12-12\20191210_MP3_RunDriftingGratingsR01_g0';

runPreGLX = [1 2];

%processed?
%Rec	Mouse	Date		GLX-Pre		Eye-Pre		Sorted	Post
%1-1	MP2		2019-11-20	Yes			Yes			x		x
%1-2	MP2		2019-11-21	x			Yes			x		x
%1-3	MP2		2019-11-22a	x			x			x		x
%1-4	MP2		2019-11-22b	x			x			x		x
%2-1	MP3		2019-12-10	x			x			x		x
%2-2	MP3		2019-12-11	x			x			x		x
%2-3	MP3		2019-12-12	x			x			x		x

%% path definitions
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
addpath(genpath('C:\Code\Acquisition\Kilosort2')); % path to kilosort folder
addpath('C:\Code\Acquisition\npy-matlab'); % for converting to Phy
strExpPath = 'P:\Montijn\DataNeuropixels\Exp2019-11-22\';
strRec = '20191122_MP2_R02_RunDriftingGratingsR01_g0';
rootZ = cellRec{runPreGLX(1)}{runPreGLX(2)}; % the raw data binary file is in this folder
strTempDirDefault = 'C:\_TempData'; % path to temporary binary file (same size as data, should be on fast SSD)
strPathToConfigFile = strcat(strThisPath,'subfunctionsPP',filesep); % take from Github folder and put it somewhere else (together with the master_file)
chanMapFile = 'neuropixPhase3B2_kilosortChanMap.mat';

%% check which temp folder to use
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
objFile      = java.io.File('C:\');
dblFreeBytes   = objFile.getFreeSpace;
dblFileSize = fs(1).bytes;
fprintf('Processing "%s" (%.1fGB)\n',fs(1).name,dblFileSize/(1024.^3));
if dblFreeBytes > (dblFileSize*1.05)
	strTempDir = strTempDirDefault;
	fprintf('Using temp dir "%s" (%.1fGB free)\n',strTempDir,dblFreeBytes/(1024.^3));
else
	strTempDir = strrep(strTempDirDefault,'C:\','D:\');
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
