%% set default paths
strDefaultKilosort = 'C:\Code\Acquisition\Kilosort';
strDefaultNpyMATLAB = 'C:\Code\Acquisition\npy-matlab';
strDefaultTempDirSSD = 'E:\_TempData';

if ~exist('strPathKilosort','var') || isempty(strPathKilosort)
    strPathKilosort = strDefaultKilosort;
end
if ~exist('strNpyMatlab','var') || isempty(strNpyMatlab)
    strNpyMatlab = strDefaultNpyMATLAB;
end
if ~exist('strTempDirSSD','var') || isempty(strTempDirSSD)
    strTempDirSSD = strDefaultTempDirSSD;
end

%% run
for intRunPrePro=1:size(matRunPre,1)
%% clear variables and select session to preprocess
clearvars -except cellRec matRunPre intRunPrePro strPathKilosort strNpyMatlab strTempDirSSD
runPreGLX = matRunPre(intRunPrePro,:);
fprintf('Starting pre-processing of "%s" [%s]\n',cellRec{runPreGLX(1)}{runPreGLX(2)},getTime);

%% path definitions
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
addpath(genpath(strPathKilosort)); % path to kilosort folder
addpath(strNpyMatlab); % for converting to Phy
rootZ = cellRec{runPreGLX(1)}{runPreGLX(2)}; % the raw data binary file is in this folder
strPathToConfigFile = strcat(strThisPath,'subfunctionsPP',filesep); % take from Github folder and put it somewhere else (together with the master_file)
chanMapFile = 'neuropixPhase3B2_kilosortChanMap.mat';

%% check which temp folder to use & clear data
sTempFiles = dir(fullfile(strTempDirSSD,'*.dat'));
for intTempFile=1:numel(sTempFiles)
	boolDir = sTempFiles(intTempFile).isdir;
	strFile = sTempFiles(intTempFile).name;
	if ~boolDir
		delete(fullfile(strTempDirSSD,strFile));
		fprintf('Deleted "%s" from temporary path "%s" [%s]\n',strFile,strTempDirSSD,getTime);
	end
end
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
objFile      = java.io.File('C:\');
dblFreeBytes   = objFile.getFreeSpace;
dblFileSize = fs(1).bytes;
fprintf('Processing "%s" (%.1fGB)\n',fs(1).name,dblFileSize/(1024.^3));
if dblFreeBytes > (dblFileSize*1.05)
	strTempDir = strTempDirSSD;
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
ops.NchanTOT    = AP + LF + SY; % total number of channels; is this correct?
ops.fproc       = fullfile(strTempDir, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(strPathToConfigFile, chanMapFile);

%% this block runs all the steps of the algorithm
%% copied; still to edit
%{
addpath(genpath('D:\GitHub\Kilosort2')) % path to kilosort folder
addpath('D:\GitHub\npy-matlab') % for converting to Phy
rootZ = 'G:\Spikes\Sample'; % the raw data binary file is in this folder
rootH = 'H:\'; % path to temporary binary file (same size as data, should be on fast SSD)
pathToYourConfigFile = 'D:\GitHub\Kilosort2\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
chanMapFile = 'neuropixPhase3A_kilosortChanMap.mat';

ops.trange    = [0 Inf]; % time range to sort
ops.NchanTOT  = 385; % total number of channels in your recording

run(fullfile(pathToYourConfigFile, 'configFile384.m'))
ops.fproc   = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
%ops.chanMap = fullfile(pathToYourConfigFile, chanMapFile);
%% this block runs all the steps of the algorithm
fprintf('Looking for data inside %s \n', rootZ)

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 20;  % spatial smoothness constant for registration
ops.fshigh     = 300; % high-pass more aggresively
ops.nblocks    = 5; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 

% main parameter changes from Kilosort2.5 to v3.0
%ops.Th       = [9 9];

% is there a channel map file in this folder?
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
   ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
ops.fbinary = fullfile(rootZ, fs(1).name);

rez                = preprocessDataSub(ops);
rez                = datashift2(rez, 1);

[rez, st3, tF]     = extract_spikes(rez);

rez                = template_learning(rez, tF, st3);

[rez, st3, tF]     = trackAndSort(rez);

rez                = final_clustering(rez, tF, st3);

rez                = find_merges(rez, 1);

rootZ = fullfile(rootZ, 'kilosort3');
mkdir(rootZ)
rezToPhy2(rez, rootZ);
%}

%% if you want to save the results to a Matlab file...

% discard features in final rez file (too slow to save)
rez.cProj = [];
rez.cProjPC = [];

% final time sorting of spikes, for apps that use st3 directly
[~, isort]   = sortrows(rez.st3);
rez.st3      = rez.st3(isort, :);

% Ensure all GPU arrays are transferred to CPU side before saving to .mat
rez_fields = fieldnames(rez);
for i = 1:numel(rez_fields)
    field_name = rez_fields{i};
    if(isa(rez.(field_name), 'gpuArray'))
        rez.(field_name) = gather(rez.(field_name));
    end
end

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(rootZ, 'rez2.mat');
save(fname, 'rez', '-v7.3');
end