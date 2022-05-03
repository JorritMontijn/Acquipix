%align probe to atlas

%% ask what to load

%% load atlas
intUseMouseOrRat = 1;
sRP = RP_populateStructure();
if intUseMouseOrRat == 1
	%define ABA location
	strAllenCCFPath = '';
	if isempty(strAllenCCFPath)
		strAllenCCFPath = sRP.strAllenCCFPath;
	end
	
	%load ABA
	if (~exist('tv','var') || isempty(tv)) || (~exist('av','var') || isempty(av)) || (~exist('st','var') || isempty(st)) || ~all(size(av) == [1320 800 1140])
		[tv,av,st] = RP_LoadABA(strAllenCCFPath);
		if isempty(tv),return;end
	end
	
	%prep ABA
	sAtlas = RP_PrepABA(tv,av,st);
else
	%load RATlas
	strSpragueDawleyAtlasPath = 'F:\Data\Ratlas';
	if (~exist('tv','var') || isempty(tv)) || (~exist('av','var') || isempty(av)) || (~exist('st','var') || isempty(st)) || ~all(size(av) == [512 1024 512])
		[tv,av,st] = RP_LoadSDA(strSpragueDawleyAtlasPath);
		if isempty(tv),return;end
	end
	
	%prep SDA
	sAtlas = RP_PrepSDA(tv,av,st);
end

%% load coords file
strDefaultPath = sRP.strProbeLocPath;
[cellPoints,strFile,strPath,sProbeCoords] = PH_OpenCoordsFile(strDefaultPath);
if ~isempty(cellPoints)
	[strDir,strName,strExt]= fileparts(strFile);
end

%select probe nr
if isempty(sProbeCoords) && isempty(cellPoints)
	sProbeCoords.folder = '';
	sProbeCoords.name = ['default'];
	sProbeCoords.cellPoints = {};
	sProbeCoords.intProbeIdx = 0;
elseif isempty(sProbeCoords)
	intProbeIdx = PH_SelectProbeNr(cellPoints,strFile,tv,av,st);
	sProbeCoords.folder = strPath;
	sProbeCoords.name = [strName '_Adjusted.mat'];
	sProbeCoords.cellPoints = cellPoints;
	sProbeCoords.intProbeIdx = intProbeIdx;
end
sProbeCoords.dblProbeLength = 3840; % (hardcode, sometimes kilosort2 drops channels)

%% load ephys
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

%generate dummy sFile with minimal information
sFile = struct;
sFile.sClustered.folder = strEphysPath;

%global sFile
hMsg = msgbox('Loading electrophysiological data, please wait...','Loading ephys');
sEphysData = PH_LoadEphys(sFile);
if isempty(sEphysData)
	close(hMsg);
	return;
end
sClusters = PH_PrepEphys(sFile,sEphysData,sProbeCoords.dblProbeLength);

% close message
close(hMsg);

%% run GUI
[hMain,hAxAtlas,hAxAreas,hAxAreasPlot,hAxZeta,hAxClusters,hAxMua] = PH_GenGUI(sAtlas,sProbeCoords,sClusters);

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
