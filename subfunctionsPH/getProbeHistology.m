%get brain slice

%define ABA location
strAllenCCFPath = '';
if isempty(strAllenCCFPath)
	sRP = RP_defaultValues();
	strAllenCCFPath = sRP.strAllenCCFPath;
end

%load ABA
if (~exist('tv','var') || isempty(tv)) || (~exist('av','var') || isempty(av)) || (~exist('st','var') || isempty(st))
	[tv,av,st] = RP_LoadABA(strAllenCCFPath);
	if isempty(tv),return;end
end

%load coords file
strDefaultPath = sRP.strProbeLocPath;
[cellPoints,strFile,strPath] = PH_OpenCoordsFile(strDefaultPath);
if isempty(cellPoints),return;end
[strDir,strName,strExt]= fileparts(strFile);

%select probe nr
intProbeIdx = PH_SelectProbeNr(cellPoints,strFile,tv,av,st);

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
if isempty(strEphysPath) || (numel(strEphysPath)==1 && strEphysPath==0)
	return;
end

%generate dummy sFile with minimal information
sFile = struct;
sFile.sProbeCoords.folder = strPath;
sFile.sProbeCoords.name = [strName '_Adjusted.mat'];
sFile.sProbeCoords.cellPoints = cellPoints;
sFile.sProbeCoords.intProbeIdx = intProbeIdx;
sFile.sClustered.folder = strEphysPath;

%% plot grid
[hMain,hAxAtlas,hAxAreas,hAxAreasPlot,hAxZeta,hAxClusters,hAxMua] = PH_GenGUI(av,tv,st,sFile);

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
