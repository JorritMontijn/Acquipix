%get brain slice
intUseMouseOrRat = 2;
sRP = RP_populateStructure();
if intUseMouseOrRat == 1
	%define ABA location
	strAllenCCFPath = '';
	if isempty(strAllenCCFPath)
		strAllenCCFPath = sRP.strAllenCCFPath;
	end
	
	%load ABA
	if (~exist('tv','var') || isempty(tv)) || (~exist('av','var') || isempty(av)) || (~exist('st','var') || isempty(st))
		[tv,av,st] = RP_LoadABA(strAllenCCFPath);
		if isempty(tv),return;end
	end
	
	%define misc variables
	vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
	vecVoxelSize = [10 10 10];% bregma in accf; [AP,DV,ML]
	
	%brain grid
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'brainGridData.mat'));
	matBrainGrid = sLoad.brainGridData;
	
	%color map
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'allen_ccf_colormap_2017.mat'));
	cmap=sLoad.cmap;
	
else
	%load RATlas
	strSpragueDawleyAtlasPath = 'F:\Data\Ratlas';
	[tv,av,st] = RP_LoadSDA(strSpragueDawleyAtlasPath);
	if isempty(tv),return;end
	
	%define misc variables
	%[ML,AP,DV] with dimensions 512 x 1024 x 512). The midline seems to be around ML=244
	
	%define misc variables
	%bregma in [AP,DV,ML]; c = 653, h = 440, s = 246
	vecBregma = [246,653,440];% bregma in SDA; [ML,AP,DV]
	vecVoxelSize = [39 39 39];
	
	%rat brain grid
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'brainGridData.mat'));
	matBrainGrid = sLoad.brainGridData;
	
	%color map
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'allen_ccf_colormap_2017.mat'));
	cmap=sLoad.cmap;
	
end

%load coords file
strDefaultPath = sRP.strProbeLocPath;
[cellPoints,strFile,strPath,sProbeCoords] = PH_OpenCoordsFile(strDefaultPath);
if ~isempty(cellPoints)
	[strDir,strName,strExt]= fileparts(strFile);
end

%generate dummy sFile with minimal information
sFile = struct;

%select probe nr
if isempty(sProbeCoords) && isempty(cellPoints)
	sFile.sProbeCoords.folder = '';
	sFile.sProbeCoords.name = ['default'];
	sFile.sProbeCoords.cellPoints = {};
	sFile.sProbeCoords.intProbeIdx = 0;
elseif isempty(sProbeCoords)
	intProbeIdx = PH_SelectProbeNr(cellPoints,strFile,tv,av,st);
	sFile.sProbeCoords.folder = strPath;
	sFile.sProbeCoords.name = [strName '_Adjusted.mat'];
	sFile.sProbeCoords.cellPoints = cellPoints;
	sFile.sProbeCoords.intProbeIdx = intProbeIdx;
else
	sFile.sProbeCoords = sProbeCoords;
end

%ask for path
%select file
try
	strOldPath = cd(sRP.strEphysPath);
	strNewPath = sRP.strEphysPath;
catch
	strOldPath = cd();
	strNewPath = strOldPath;
end
strEphysPath=uigetdir(strNewPath,'Select kilosort data folder');
cd(strOldPath);
%if isempty(strEphysPath) || (numel(strEphysPath)==1 && strEphysPath==0)
%	return;
%end
sFile.sClustered.folder = strEphysPath;

%% plot grid
[hMain,hAxAtlas,hAxAreas,hAxAreasPlot,hAxZeta,hAxClusters,hAxMua] = PH_GenGUI(av,tv,st,sFile,vecBregma,vecVoxelSize,matBrainGrid,cmap);

%% wait until done
waitfor(hMain,'UserData','close');
sGUI = guidata(hMain);
close(hMain);

%check if output is present
if isfield(sGUI,'sProbeAdjusted')
	sProbeAdjusted = sGUI.sProbeAdjusted;
else
	sProbeAdjusted = struct;
end
