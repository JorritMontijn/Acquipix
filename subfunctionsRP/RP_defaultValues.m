function sRP = RP_defaultValues()
	%% default data paths
	sRP.strOutputPath = 'D:\Data\Processed\Neuropixels';
	sRP.strTempPath = 'E:\_TempData'; %fast & reliable ssd;
	sRP.strEphysPath = 'D:\Data\Raw\Neuropixels';
	sRP.strStimLogPath = 'D:\Data\Raw\Neuropixels';
	sRP.strEyeTrackingPath = 'D:\Data\Raw\Neuropixels';
	sRP.strProbeLocPath = 'D:\Data\Raw\Neuropixels';
	
	%% default search keys
	%spikeglx
	sRP.strEphysRegExpNidq = '\d{4}[-/]?(\d{2})[-/]?\d{2}.*[n][i][d][q].*[.][m][e][t][a]$';
	%kilosort
	sRP.strEphysFindClustered = 'spike_clusters.npy';
	%synthesis
	sRP.strEphysFindSynthesis = '*_Synthesis.mat';
	
	% stimulus files
	sRP.strStimLogRegExpStim = '(\d{4}[-/]?(\d{2})[-/]?\d{2}).*(\d{2}[-/_]?(\d{2})[-/_]?\d{2}).*([.][m][a][t]$)';
	
	% processed eye-tracking data
	%EyeTrackingProcessed2021-02-11b_R_trimmed5mins
	%PupVid_RecMA5_2021-03-01R01Processed.mat
	sRP.strEyeTrackingRegExpVid = ['([Pp][r][o][c][e][s][s][e][d]).*(\d{4}[-/]?(\d{2})[-/]?\d{2}).*([.][m][a][t]$)|'...
		'(\d{4}[-/]?(\d{2})[-/]?\d{2}).*([Pp][r][o][c][e][s][s][e][d]).*([.][m][a][t]$)'];
	
	% histology/probe location data
	sRP.strProbeLocRegExpCoords = '(\d{4}[-/]?(\d{2})[-/]?\d{2}).*[Cc][o][o][r][d][s].*([.][m][a][t]$)';
	
	%% internal configs
	strFullFile = mfilename('fullpath');
	cellPath = strsplit(strFullFile,filesep);
	strThisPath = strjoin(cellPath(1:(end-2)),filesep);
	if ~strcmp(strThisPath(end),filesep),strThisPath(end+1)=filesep;end
	sRP.strConfigFilePath = strcat(strThisPath,'subfunctionsPP',filesep); % take from Github folder and put it somewhere else (together with the master_file)
	sRP.strConfigFileName = 'configFile384_Npx3B2.m';
	sRP.strConfigFileKey = 'configFile*.m';
	sRP.strMetaVarFile = 'AcquipixMetavars.mat';
	sRP.strMetaVarFolder = sRP.strEphysPath;
	
end