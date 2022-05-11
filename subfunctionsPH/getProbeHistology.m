%align probe to atlas
%change name to NeuroFinder in separate repo

%% ask what to load
%clear all;

%% load atlas
global boolIgnoreNeuroFinderRenderer;
boolIgnoreNeuroFinderRenderer = false;
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
sProbeCoords = PH_LoadProbeFile(sAtlas,strDefaultPath);

%% load ephys
%select file
try
	strOldPath = cd(sRP.strEphysPath);
	strNewPath = sRP.strEphysPath;
catch
	strOldPath = cd();
	strNewPath = strOldPath;
end
%open ephys data
sClusters = PH_OpenEphys(strNewPath);

% load or compute zeta if ephys file is not an Acquipix format
if isempty(sClusters) || strcmp(sClusters.strZetaTit,'Contamination')
	%select
	sZetaResp = PH_OpenZeta(sClusters,strNewPath);
	
	%save
	if ~isempty(sZetaResp) && isfield(sZetaResp,'vecZetaP')
		sClusters.vecDepth = sZetaResp.vecDepth;
		sClusters.vecZeta = norminv(1-(sZetaResp.vecZetaP/2));
		sClusters.strZetaTit = 'ZETA (z-score)';
	end
end

% close message
cd(strOldPath);

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
