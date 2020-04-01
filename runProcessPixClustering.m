%% to run phy for clustering after finishing runPreProcessPix:
% 1) open anaconda
% 2) go to your output directory (e.g., E:\_TempData\20191120_MP2_RunDriftingGratingsR01_g0)
% 3) type: activate phy
% 4) type: phy template-gui params.py
%
% For more info on phy-contrib's template-gui, see: 
%	https://github.com/kwikteam/phy-contrib/blob/master/docs/template-gui.md
%

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

vecRunPre = [1 3];

%% copy files from VS02 to SSD
% clear variables
clearvars -except cellRec vecRunPre
fprintf('Starting pre-processing of "%s" [%s]\n',cellRec{vecRunPre(1)}{vecRunPre(2)},getTime);

% path definitions
strPathNetwork = cellRec{vecRunPre(1)}{vecRunPre(2)}; % the raw data binary file is in this folder
strTempDirDefault = 'E:\_TempData'; % path to temporary binary file (same size as data, should be on fast SSD)
cellSubDir = strsplit(strPathNetwork,filesep);
strSubDir = cellSubDir{end};
strTempDir = fullfile(strTempDirDefault,strSubDir);

%delete temp files
sTempFiles = dir(fullfile(strTempDirDefault,'*.dat'));
for intTempFile=1:numel(sTempFiles)
	boolDir = sTempFiles(intTempFile).isdir;
	strFile = sTempFiles(intTempFile).name;
	if ~boolDir
		delete(fullfile(strTempDirDefault,strFile));
		fprintf('Deleted "%s" from temporary path "%s" [%s]\n',strFile,strTempDirDefault,getTime);
	end
end

%copy
%[status,msg] = copyfile(strPathNetwork,strTempDir);
%loop through folders to check for script files
intStartRelativePath = length(strPathNetwork)+1;
cellExcludeDirs = {'.','..','.phy'};
cellPaths = getSubDirs(strPathNetwork,inf,cellExcludeDirs);
intFileCounter = 0;
strVariable = sprintf('%d [%s]\n',0,getTime);
fprintf('Copying file ');
fprintf(strVariable);
for intPath=1:length(cellPaths)
	sFiles=dir([cellPaths{intPath} filesep '*']);
	strRelPath = [cellPaths{intPath}(intStartRelativePath:end) filesep];
	
	[boolSuccess,strMsg]=mkdir([strTempDir strRelPath]); %create path in target folder
	for intFile=1:length(sFiles)
		strFile = sFiles(intFile).name;
		if (length(strFile) > 3 && strcmp(strFile((end-3):end),'.bin'))|| any(ismember(strFile,cellExcludeDirs))
			continue;
		end
		intFileCounter = intFileCounter + 1;
		intLastVariable = length(strVariable);
		strVariable = sprintf('%d: "%s" [%s]\n',intFileCounter,strFile,getTime);
		fprintf([repmat('\b',[1 intLastVariable]) strVariable]);
		
		[boolSuccess,strMsg] = copyfile([cellPaths{intPath} filesep strFile],[strTempDir strRelPath strFile]);
		if ~boolSuccess
			fprintf('Copying failed for file [%d] at dir [%d/%d]: [%s] Msg was: "%s" [%s]\nCopying file ',intFileCounter,intPath,length(cellPaths),[strRelPath strFile],strMsg,getTime);
			strVariable = '';
		end
	end
end

%% cluster
% 1) open anaconda
% 2) go to your output directory (e.g., E:\_TempData\20191120_MP2_RunDriftingGratingsR01_g0)
% 3) type: activate phy
% 4) type: phy template-gui params.py
fprintf(['Copying complete, please:\n'...
' 1) open anaconda\n'...
' 2) go to your output directory (e.g., E:\\_TempData\\20191120_MP2_RunDriftingGratingsR01_g0)\n'...
' 3) type: activate phy\n'...
' 4) type: phy template-gui params.py\n'...
'\n'...
'Don''t forget to copy the clustered file after you''ve finished!\n']);
return

%% load data
%load stimulation

%load rez
sLoad = load(fullfile(strTempDir,'rez2.mat'));
sRez = sLoad.rez;
vecKilosortContamination = sRez.est_contam_rate;

%load others
chanMapFile = 'neuropixPhase3B2_kilosortChanMap.mat';
chanMapDir = 'C:\Code\Acquisition\Acquipix\subfunctionsPP\';
strChanMapFile = fullfile(chanMapDir,chanMapFile);
dblInvertLeads = true;
dblCh1DepthFromPia = 3300;
% load some of the useful pieces of information from the kilosort and manual sorting results into a struct
fprintf('Loading clustered spiking data at %s [%s]\n',strTempDir,getTime);
sSpikes = loadKSdir(strTempDir);
vecAllSpikeTimes = sSpikes.st;
vecAllSpikeClust = sSpikes.clu;
vecClusters = unique(vecAllSpikeClust);

%get channel depth from pia
sChanMap=load(strChanMapFile);
vecChannelDepth = sChanMap.ycoords;
vecChannelDepth = vecChannelDepth - max(vecChannelDepth);
if dblInvertLeads,vecChannelDepth = vecChannelDepth(end:-1:1);end
vecChannelDepth = vecChannelDepth + dblCh1DepthFromPia;

for intCluster=1:numel(vecClusters)
	intClustIdx = vecClusters(intCluster);
	vecSpikeTimes = vecAllSpikeTimes(vecAllSpikeClust==intClustIdx);
	sOut = getClusterQuality(vecSpikeTimes,1)
	pause
end