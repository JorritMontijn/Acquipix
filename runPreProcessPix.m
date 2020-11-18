%% recordings
clear all;close all;
%sites
cellRec{1}{1} = 'P:\Montijn\DataNeuropixels\Exp2019-11-20\20191120_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\Montijn\DataNeuropixels\Exp2019-11-21\20191121_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{3} = 'P:\Montijn\DataNeuropixels\Exp2019-11-22\20191122_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{4} = 'P:\Montijn\DataNeuropixels\Exp2019-11-22\20191122_MP2_R02_RunDriftingGratingsR01_g0';
cellRec{2}{1} = 'P:\Montijn\DataNeuropixels\Exp2019-12-10\20191210_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{2} = 'P:\Montijn\DataNeuropixels\Exp2019-12-11\20191211_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{3} = 'P:\Montijn\DataNeuropixels\Exp2019-12-12\20191212_MP3_RunNaturalMovieR01_g0';
cellRec{2}{4} = 'P:\Montijn\DataNeuropixels\Exp2019-12-13\20191213_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{5} = 'P:\Montijn\DataNeuropixels\Exp2019-12-16\20191216_MP3_RunNaturalMovieR01_g0';
cellRec{2}{6} = 'P:\Montijn\DataNeuropixels\Exp2019-12-17\20191217_MP3_RunDriftingGratingsR01_g0';
cellRec{3}{1} = 'P:\Montijn\DataNeuropixels\Exp2020-01-15\20200115_MP4_RunDriftingGratingsR01_g0';
cellRec{3}{2} = 'P:\Montijn\DataNeuropixels\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR01_g0';
cellRec{3}{3} = 'P:\Montijn\DataNeuropixels\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR02_g0';
cellRec{4}{1} = 'P:\Montijn\DataNeuropixels\Nora\Exp2020-09-17\20200917_NPX2_RunOptoNoraR02_g0';

matRunPre = [...
	1 3;...
	2 2;...
	2 5;...
	3 1;...
	3 2;...
	3 3;...
	1 4;...
	2 1;...
	2 3;...
	2 4;...
	2 6;...
	];
matRunPre = [4 1];

%											0=none, 1=KS, 2=eye,3=post,4=area+depth
%Rec	Mouse	Date		Quality	V+good	Processed	CORT		SUBCORT	Comments
%01:1-1	MP2		2019-11-20	Good	115/298	4			PM			LP		SUBCORT, some CORT, nice responses
%02:1-2	MP2		2019-11-21	Good	 72/285	4			V1			LP		SUBCORT, some CORT, nice responses	
%03:1-3	MP2		2019-11-22a	Fair	 54/571	4			PM			NOT		a few very nice responses, B2 only good up to T=2500
%04:1-4	MP2		2019-11-22b					2								<<RE-ANALYZE! CHECK ORIGINAL FILES>>					
%05:2-1	MP3		2019-12-10	Good	 53/283	4			PM			NOT		Some nice responses				
%06:2-2	MP3		2019-12-11	Great	182/417	4			PM			SC		Many nice cells					
%07:2-3	MP3		2019-12-12	Good	120/388	4			AM			APN		Many nice cells, mostly subcortical; Subcort vis?					
%08:2-4	MP3		2019-12-13	Great	196/512	4			PM			NOT/APN	Great recording, Eye-tracking possibly weird.. Subcort vis?					
%09:2-5	MP3		2019-12-16	Great!	232/621	4			V1			LGN		Eye-tr is ~ & missing stim1
%10:2-6	MP3		2019-12-17	Good	 72/407	4			AM			-/(LP)	Cort{PPC}, few subcort										
%11:3-1	MP4		2020-01-15	Good	133/398 4			RS/AM		NOT/APN	Eye-tr bad after t=2500s, Subcort vis, Possibly NOT: SUBCORT (+some CORT) very nice responses					
%12:3-2	MP4		2020-01-16a	Poor	 47/325	4			AM			LP		CORT{AM} (+some SUBCORT{LP}~2500)					
%13:3-3	MP4		2020-01-16b	Good	 51/216	4			RS			NOT		Subcort vis, Possibly NOT: SUBCORT, but very nice cells					

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

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 20;  % spatial smoothness constant for registration
ops.fshigh     = 300; % high-pass more aggresively
ops.nblocks    = 5; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 

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
%
% NEW STEP TO DO DATA REGISTRATION
rez = datashift2(rez, 1); % last input is for shifting data

% ORDER OF BATCHES IS NOW RANDOM, controlled by random number generator
iseed = 1;
                 
% main tracking and template matching algorithm
rez = learnAndSolve8b(rez, iseed);

% OPTIONAL: remove double-counted spikes - solves issue in which individual spikes are assigned to multiple templates.
% See issue 29: https://github.com/MouseLand/Kilosort/issues/29
%rez = remove_ks2_duplicate_spikes(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% decide on cutoff
rez = set_cutoff(rez);
% eliminate widely spread waveforms (likely noise)
rez.good = get_good_units(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, rootZ);

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