


%% path definitions
%this location
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));

%chan map
strChanMapFile = 'C:\Code\Acquisition\Acquipix\subfunctionsPP\neuropixPhase3B2_kilosortChanMap.mat';
%data
strDataPath = 'D:\_Data\Exp2019-11-20\20191120_MP2_RunDriftingGratingsR01_g0\';
sFiles = dir(fullfile(strDataPath, '*.ap.bin'));
strDataFile = sFiles(1).name;

%% initialize
%load data
% Parse the corresponding metafile
sMeta = DP_ReadMeta(strDataFile, strDataPath);

% Get first one second of data
nSamp = DP_SampRate(sMeta);
matData = DP_ReadBin(0, 15*nSamp, sMeta, strDataFile, strDataPath);
intTimepoints = size(matData,2); % number of total timepoints

%load chan map
sChanMap = load(strChanMapFile);
sChanMap.NchanTOTdefault = size(matData,1);
vecChanMap = sChanMap.chanMap;

%define parameters
sP = DP_GetParamStruct(sMeta);
sP.tstart  = ceil(sP.trange(1) * sP.fs); % starting timepoint for processing data segment
sP.tend    = min(intTimepoints, ceil(sP.trange(2) * sP.fs)); % ending timepoint

%% run
% run acquisition for some period (e.g., one full repetition of stimuli)
% then compute which channels to remove
% whitening matrix, etc
[vecSpikeCh,vecSpikeT,dblTotT] = DP_DetectSpikes(matData, sP, vecChanMap);

%calculate which channels to use
[vecUseChannelsFilt,vecUseChannelsOrig] = DP_CullChannels(vecSpikeCh,vecSpikeT,dblTotT,sP,sChanMap);
vecSpikeRatePerChannel = accumarray(vecSpikeCh,1) ./ dblTotT;

%then for each batch, apply channel culling and detect spikes in remainder

