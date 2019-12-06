% default options are in parenthesis after the comment
clear all;

%% set recording
strMouse = 'MP2';
strExperiment = 'Exp2019-11-20';
strRecording = '20191120_MP2_RunDriftingGratingsR01_g0';
dblInvertLeads = true; %is ch1 deepest?
dblCh1DepthFromPia = 2500;

%% set & generate paths
strThisPath = mfilename('fullpath');
strThisPath = strThisPath(1:(end-numel(mfilename)));
strDataPath = 'P:\Montijn\DataNeuropixels\';
strPathDataTarget = ['P:\Montijn\DataPreProcessed' filesep strExperiment filesep];
strChanMapFile = strcat(strThisPath,'subfunctionsPP\neuropixPhase3B2_kilosortChanMap.mat');
strPathStimLogs = [strDataPath strExperiment filesep strMouse filesep];
strPathEphys = [strDataPath strExperiment filesep strRecording filesep];
strPathEyeTracking = [strDataPath strExperiment filesep 'EyeTracking' filesep];
fprintf('Processing recording at %s [%s]\n',strPathEphys,getTime);

%% load eye-tracking
%find video file
fprintf('Loading pre-processed eye-tracking data at %s [%s]\n',strPathEyeTracking,getTime);
strSearchEyeFile = ['EyeTrackingProcessed*' strrep(strExperiment,'Exp','') '*.mat'];
sEyeFiles = dir(strcat(strPathEyeTracking,strSearchEyeFile));
if numel(sEyeFiles) == 1
	sEyeTracking = load([sEyeFiles(1).folder filesep sEyeFiles(1).name]);
	sPupil = sEyeTracking.sPupil;
	clear sEyeTracking;
else
	error([mfilename ':AmbiguousInput'],'Multiple video files found, please narrow search parameters');
end

% plot
figure
plot(sPupil.vecPupilTime,sPupil.vecPupilRawCenterX);
hold on
plot(sPupil.vecPupilTime,sPupil.vecPupilCenterX);
hold off
title(sprintf('Pupil x-pos, %s',sEyeFiles(1).name),'Interpreter','none');
xlabel('Time (s)');
ylabel('Horizontal position (pixels)');
fixfig


%% load NI sync stream times
strFileNI = strcat(strRecording,'_t0.nidq.bin');
fprintf('Loading syncing data %s [%s]\n',strFileNI,getTime);
% Parse the corresponding metafile
sMetaNI = DP_ReadMeta(strFileNI, strPathEphys);
dblSampRateNI = DP_SampRate(sMetaNI);

% Get NI data
matDataNI = -DP_ReadBin(0, inf, sMetaNI, strFileNI, strPathEphys);
[boolVecPhotoDiode,dblCritValPD] = DP_GetUpDown(matDataNI(1,:));
[boolVecSyncPulses,dblCritValSP] = DP_GetUpDown(matDataNI(2,:));
clear matDataNI;
boolVecStimPresent = boolVecPhotoDiode;

%% load stimulus info
%load logging file
fprintf('Synchronizing multi-stream data [%s]\n',getTime);
dblLastStop = 0;
sFiles = dir([strPathStimLogs '*_' strMouse '_*.mat']);
intLogs = numel(sFiles);
cellStim = cell(1,intLogs);
for intLogFile = 1:intLogs
	%% calculate stimulus times
	cellStim{intLogFile} = load([strPathStimLogs sFiles(intLogFile).name]);
	intThisNumTrials = numel(~isnan(cellStim{intLogFile}.structEP.ActOffSecs));
	if isfield(cellStim{intLogFile}.structEP,'ActOnNI')
		vecStimActOnNI = cellStim{intLogFile}.structEP.ActOnNI;
		vecStimActOffNI = cellStim{intLogFile}.structEP.ActOffNI;
		dblLastStop = vecStimActOffNI(end)/dblSampRateNI + 0.01;
	else
		%approximate timings
		vecStimOn = (find(diff(boolVecStimPresent) == 1)+1)/dblSampRateNI;
		vecStimOff = (find(diff(boolVecStimPresent) == -1)+1)/dblSampRateNI;
		%remove prior entries
		vecStimOn(vecStimOn < dblLastStop) = [];
		vecStimOff(vecStimOff < dblLastStop) = [];
		%ensure identical size
		if vecStimOff(1) < vecStimOn(1),vecStimOff(1) = [];end
		if numel(vecStimOn) > numel(vecStimOff),vecStimOn(end) = [];end
		%calc dur
		vecStimDur = vecStimOff - vecStimOn;
		
		%remove all durations shorter than single frame
		vecRemStims = vecStimDur <= cellStim{intLogFile}.structEP.dblStimFrameDur;
		vecStimDur(vecRemStims) = [];
		vecStimOn(vecRemStims) = [];
		vecStimOff(vecRemStims) = [];
		%check first stimulus that falls within 1sd of median
		dblMedDur = median(vecStimDur);
		dblSdDur = std(vecStimDur);
		vecPossibleStims = (vecStimDur > (dblMedDur - dblSdDur)) & (vecStimDur < (dblMedDur + dblSdDur));
		%select onset/offset
		intStartStim = find(vecPossibleStims,1);
		intEndStim = intStartStim + intThisNumTrials - 1;
		dblStartOnT = vecStimOn(intStartStim);
		dblStartOffT = vecStimOff(intStartStim);
		dblLastStop = vecStimOff(intEndStim) + 0.01;
		
		%get real but inaccurate timings
		vecStimActOnNI = cellStim{intLogFile}.structEP.ActOnSecs;
		vecStimActOffNI = cellStim{intLogFile}.structEP.ActOffSecs;
		%ensure same starting time
		vecStimActOnNI = vecStimActOnNI - vecStimActOnNI(1) + dblStartOnT;
		vecStimActOffNI = vecStimActOffNI - vecStimActOffNI(1) + dblStartOffT;
		%convert to sample time
		vecStimActOnNI = round(vecStimActOnNI*dblSampRateNI);
		vecStimActOffNI = round(vecStimActOffNI*dblSampRateNI);
	end
	
	%get ON times
	vecPresStimOnT = vecStimActOnNI/dblSampRateNI;
	vecSignalOnT = (find(diff(boolVecStimPresent) == 1)+1)/dblSampRateNI; 
	[vecStimOnTime,cellTextOnS,vecDiffOnT] = OT_getStimT(vecPresStimOnT,vecPresStimOnT,vecSignalOnT,{'ON'},0.1);
	%get OFF times
	vecPresStimOffT = vecStimActOffNI/dblSampRateNI;
	vecSignalOffT = (find(diff(boolVecStimPresent) == -1)+1)/dblSampRateNI; 
	[vecStimOffTime,cellTextOffS,vecDiffOffT] = OT_getStimT(vecPresStimOffT,vecPresStimOffT,vecSignalOffT,{'OFF'},0.1);
	
	% save to cell array
	cellStim{intLogFile}.structEP.vecStimOnTime = vecStimOnTime;
	cellStim{intLogFile}.structEP.vecStimOffTime = vecStimOffTime;
	
	%% align eye-tracking data
	vecPupilSyncLum = sPupil.vecPupilSyncLum;
	vecPupilTime = sPupil.vecPupilTime;
	dblSampRatePupil = 1/median(diff(vecPupilTime));
	
	%filter to 0.1-30Hz
	vecWindow2 = [0.5 30]./(dblSampRatePupil./2);
	[fb,fa] = butter(2,vecWindow2,'bandpass');
	vecFiltSyncLum = filtfilt(fb,fa, double(vecPupilSyncLum));
	boolPupilSync = vecFiltSyncLum>(-std(vecFiltSyncLum)/2);
	
	figure
	subplot(2,1,1)
	hold on
	plot(vecPupilTime,vecPupilSyncLum - mean(vecPupilSyncLum));
	plot(vecPupilTime,boolPupilSync);
	hold off
	xlabel('Time (s)');
	ylabel('Screen signal');
	hold off;
	fixfig(gca,[],1);
	
	subplot(2,1,2)
	hold on
	plot(vecPupilTime,vecFiltSyncLum);
	plot(vecPupilTime,boolPupilSync);
	hold off
	xlabel('Time (s)');
	ylabel('Screen signal');
	fixfig(gca,[],1);
	
	
	%ask when the stimuli start
	dblStartT = input(sprintf('\nPlease enter a time point during the final blanking prior to start of stim1 for stimulation block %d (s):\n',intLogFile));
	intStartT = round(dblStartT*dblSampRatePupil);
	
	%find first onset
	boolPupilSync(1:intStartT) = 0;
	intStartHiDef = find(boolPupilSync==1,1);
	dblStartHiDefT = intStartHiDef/dblSampRatePupil;
	if intLogFile == 1
	%ask when the stimuli start
	dblStopT = input(sprintf('\nPlease enter a time point during the final stimulus presentation for stimulation block %d (s):\n',intLogFile));
	intStopT = round(dblStopT*dblSampRatePupil);
	close;
	fprintf('Processing block %d... [%s]\n',intLogFile,getTime);

	%find last offset
	boolPupilSyncOff = boolPupilSync;
	boolPupilSyncOff(1:intStopT) = 1;
	intStopHiDef = find(boolPupilSyncOff==0,1);
	dblStopHiDefT = intStopHiDef/dblSampRatePupil;
	
	%calculate real framerate
	dblRealDur = vecStimOffTime(end) - vecStimOnTime(1);
	dblVidDur = dblStopHiDefT - dblStartHiDefT;
	intVidFr = intStopHiDef - intStartHiDef;
	dblReportedFrameRate = intVidFr/dblVidDur;
	dblRealFrameRate = intVidFr/dblRealDur;
	dblCorrectionFactor = dblReportedFrameRate/dblRealFrameRate;
	dblSampRatePupil = dblRealFrameRate;
	end
	
	%assign new timepoints
	if ~isfield(sPupil,'vecPupilRawTime'),sPupil.vecPupilRawTime = vecPupilTime;end
	vecPupilTime = vecPupilTime*dblCorrectionFactor;
	sPupil.vecPupilTime = vecPupilTime;
	
	%build approximate onsets
	vecEyeStimOnT = vecStimOnTime - vecStimOnTime(1) + dblStartHiDefT*dblCorrectionFactor;
	vecEyeStimOffT = vecStimOffTime - vecStimOnTime(1) + dblStartHiDefT*dblCorrectionFactor;
	
	%get ON times
	vecLumOnT = (find(diff(boolPupilSync) == 1)+1)/dblSampRatePupil; 
	[vecPupilStimOnTime,cellTextOnE,vecDiffOnT] = OT_getStimT(vecEyeStimOnT,vecEyeStimOnT,vecLumOnT,{'ON'},0.1);
	%get OFF times
	vecLumOffT = (find(diff(boolPupilSync) == -1)+1)/dblSampRatePupil; 
	[vecPupilStimOffTime,cellTextOffE,vecDiffOffT] = OT_getStimT(vecEyeStimOffT,vecEyeStimOffT,vecLumOffT,{'OFF'},0.1);
	
	%assign stim on/off times
	vecPupilStimOnFrame = round(vecPupilStimOnTime * dblSampRatePupil);
	vecPupilStimOffFrame = round(vecPupilStimOffTime * dblSampRatePupil);
	cellStim{intLogFile}.structEP.vecPupilStimOnTime = vecPupilStimOnTime;
	cellStim{intLogFile}.structEP.vecPupilStimOffTime = vecPupilStimOffTime;
	cellStim{intLogFile}.structEP.vecPupilStimOnFrame = vecPupilStimOnFrame;
	cellStim{intLogFile}.structEP.vecPupilStimOffFrame = vecPupilStimOffFrame;
end

%% load clustered data into matlab using https://github.com/cortex-lab/spikes
% load some of the useful pieces of information from the kilosort and manual sorting results into a struct
fprintf('Loading clustered spiking data at %s [%s]\n',strPathEphys,getTime);
sSpikes = loadKSdir(strPathEphys);
vecAllSpikeTimes = sSpikes.st;
vecAllSpikeClust = sSpikes.clu;
%get channel depth from pia
sChanMap=load(strChanMapFile);
vecChannelDepth = sChanMap.ycoords;
vecChannelDepth = vecChannelDepth - max(vecChannelDepth);
if dblInvertLeads,vecChannelDepth = vecChannelDepth(end:-1:1);end
vecChannelDepth = vecChannelDepth + dblCh1DepthFromPia;

%% load the information from the cluster_groups.csv file with cluster labels
% cids is length nClusters, the cluster ID numbers; cgs is length nClusters, the "cluster group":
% 0 = noise; 1 = mua; 2 = good; 3 = unsorted
[vecClusterIdx, vecClusterType] = readClusterGroupsCSV([strPathEphys filesep 'cluster_groups.csv']);
intClusterNum = numel(vecClusterType);

%% get spike times and depth per cluster
fprintf('Assigning spikes to clusters... [%s]\n',getTime);
[spikeAmps, vecAllSpikeDepth] = templatePositionsAmplitudes(sSpikes.temps, sSpikes.winv, sSpikes.ycoords, sSpikes.spikeTemplates, sSpikes.tempScalingAmps); 
vecAllSpikeDepth = dblCh1DepthFromPia - vecAllSpikeDepth;
indSingleUnits = vecClusterType==2;
indMultiUnits = vecClusterType==1;
vecSU_idx = vecClusterIdx(indSingleUnits);
vecMU_idx = vecClusterIdx(indMultiUnits);
intNumSU = numel(vecSU_idx);
intNumMU = numel(vecMU_idx);
%assign single unit spikes
SU_st = cell(1,intNumSU); %single unit spike times
SU_depth = nan(1,intNumSU); %single unit depths
for intClustSUA=1:intNumSU
	vecSpikeIDs = vecSU_idx(intClustSUA)==vecAllSpikeClust;
	SU_depth(intClustSUA) = mean(vecAllSpikeDepth(vecSpikeIDs));
	SU_st{intClustSUA} = vecAllSpikeTimes(vecSpikeIDs);
end
%assign multi unit spikes
MU_st = cell(1,intNumMU); %multi unit spike times
MU_depth = nan(1,intNumMU); %single unit depths
for intClustMUA=1:intNumMU
	vecSpikeIDs = vecMU_idx(intClustMUA)==vecAllSpikeClust;
	MU_depth(intClustMUA) = mean(vecAllSpikeDepth(vecSpikeIDs));
	MU_st{intClustMUA} = vecAllSpikeTimes(vecSpikeIDs);
end

%% load LFP data
strFileLFP = strcat(strRecording,'_t0.imec0.lf.bin');
fprintf('Filtering LFP data at %s [%s]\n',strFileLFP,getTime);
sMetaLFP = DP_ReadMeta(strFileLFP, strPathEphys);
matLFP = DP_ReadBin(0, inf, sMetaLFP, strFileLFP, strPathEphys, 'single');

dblSampRateLFP = DP_SampRate(sMetaLFP);
vecTimestampsLFP = (1:size(matLFP,2))/dblSampRateLFP;

%filter each channel
for intCh=1:size(matLFP,1)
	%get data
	vecFiltered = double(matLFP(intCh,:));
	
	%filter 50Hz
	vecWindow = [49.95 50.05]./(dblSampRateLFP./2);
	[fb,fa] = butter(2,vecWindow,'stop');
	vecFiltered = filtfilt(fb,fa,vecFiltered);
	
	%filter to 0.01-300Hz
	vecWindow2 = [0.01 300]./(dblSampRateLFP./2);
	[fb,fa] = butter(2,vecWindow2,'bandpass');
	vecFiltered = filtfilt(fb,fa,vecFiltered);
	matLFP(intCh,:) = cast(vecFiltered,'like',matLFP);
	
	%calc power
	%[vecFreq,vecPower] = getPowerSpectrum(vecFiltered,dblSampRateLFP,2);
	%loglog(vecFreq(5:end-4),conv(vecPower,normpdf(-4:4,0,2),'valid'));
end
	
%% combine all data and save to post-processing data file
%build Acquipix post-processing structure
fprintf('Combining data and saving to disk... [%s]\n',getTime);
sAP = struct;
strFileOut = strcat(strExperiment,'_',strMouse,'_AP');
strFileAP = strcat(strPathDataTarget,strFileOut,'.mat');
strSecondPathAP = 'D:\Data\Processed\Neuropixels\';
strFileAP2 = strcat(strSecondPathAP,strFileOut,'.mat');
%save LFP separately because of large size
sAP_LFP = struct; 
strFileOutLFP = strcat(strFileOut,'_LFP');
strFileLFP = strcat(strPathDataTarget,strFileOutLFP,'.mat');

%LFP
sAP_LFP.vecTimestampsLFP = vecTimestampsLFP;
sAP_LFP.matLFP = matLFP;
sAP_LFP.sMetaLFP = sMetaLFP;

%stimulation & eye-tracking timings
sAP.cellStim = cellStim;

%pupil
sAP.sPupil = sPupil;
sAP.cellStim = cellStim;

%probe data
sAP.vecChannelDepth = vecChannelDepth;
sAP.vecClusterIdx = vecClusterIdx;
sAP.vecClusterType = vecClusterType;
sAP.vecSU_idx = vecSU_idx;
sAP.vecMU_idx = vecMU_idx;

%spikes
sAP.SU_depth = SU_depth;
sAP.SU_st = SU_st;
sAP.MU_depth = MU_depth;
sAP.MU_st = MU_st;

%NI meta file
sAP.sMetaNI = sMetaNI;
sAP.strFileLFP = strFileLFP;

%save AP
fprintf('Saving AP data to %s [%s]\n',strFileAP,getTime);
save(strFileAP,'sAP');
fprintf('Saving AP data to %s [%s]\n',strFileAP2,getTime);
save(strFileAP2,'sAP');

%save LFP
fprintf('Saving LFP data to %s [%s]\n',strFileLFP,getTime);
save(strFileLFP,'sAP_LFP','-v7.3');
fprintf('Done\n');!