%% set default paths
%sites
if ~exist('strPath','var') || isempty(strPath)
    strPath = 'D:\Data\Processed\Neuropixels';
end
if ~exist('strPath2','var') || isempty(strPath2)
    strPath2 = 'P:\Montijn\DataPreProcessed';
end
if ~exist('strSubFormat','var') || isempty(strSubFormat)
    strSubFormat = '*S%dL%d_AP.mat';
end
if ~exist('strPathAllenCCF','var') || isempty(strPathAllenCCF)
    strPathAllenCCF = 'C:\Users\user4\Documents\AllenCCF\';
end
for intRunPrePro=1:size(matRunPrePro,1)
    %% prepare
    % clear variables and select session to preprocess
    vecRunPreProGLX = matRunPrePro(intRunPrePro,:);
    strSearch = sprintf(strSubFormat,vecRunPreProGLX(1),vecRunPreProGLX(2));
    fprintf('\nStarting pre-processing of "%s" [%s]\n',strSearch,getTime);
    
    %% find recording
    %get list of all directories
    cellPaths = getSubDirs(strPath,inf);
    
    %loop through folders to check for script files
    cellTargets = cell(0,0);
    for intPath=1:length(cellPaths)
        sDataFiles=dir([cellPaths{intPath} filesep strSearch]);
        if numel(sDataFiles) == 1
            cellTargets{end+1} = [cellPaths{intPath} filesep sDataFiles(1).name];
        end
    end
    if numel(cellTargets) == 1
        strTarget = cellTargets{1};
        cellSplit = strsplit(strTarget,filesep);
        strFilename = cellSplit{end};
    else
        error([mfilename 'E:QueryError'],sprintf('Found %d results when searching for %s',numel(cellTargets),strSearch));
    end
    
    %% load data
    sLoad = load(strTarget);
    sAP=sLoad.sAP;
    %if isfield(sAP,'vecBregmaCoords') && ~isempty(sAP.vecBregmaCoords)
    %	vecBregmaCoords = sAP.vecBregmaCoords;
    %else
    vecBregmaCoords = cellBregmaCoords{vecRunPreProGLX(1)}{vecRunPreProGLX(2)};
    sAP.vecBregmaCoords = vecBregmaCoords;
    %end
    
    [vecBregmaLoc,vecProbeAreaEdges,vecProbeAreaCenters,cellProbeAreaLabels,vecProbeAreaIdx] = ...
       getAtlasAreas(vecBregmaCoords,[],[],strPathAllenCCF);
	
    %correct channel depths
    vecChannelDepth = sAP.vecChannelDepth;
    dblDepthDiff = vecBregmaLoc(3) - vecChannelDepth(1);
    vecChannelDepth = vecChannelDepth + dblDepthDiff;
    for intCluster=1:numel(sAP.sCluster)
        sAP.sCluster(intCluster).Depth = sAP.sCluster(intCluster).Depth + dblDepthDiff;
    end
    sAP.vecChannelDepth = vecChannelDepth;
    
    %% manual check
    intClusters = numel(sAP.sCluster);
    vecZ = min(cell2mat({sAP.sCluster(:).ZetaP}'),[],2);
    indResp = 1|any(vecZ<0.05,2) | any(cell2mat({sAP.sCluster(:).MeanP}')<0.05,2);
    vecZ(isnan(vecZ)) = 0;
    
    figure
    scatter(vecZ(indResp),-cell2vec({sAP.sCluster(indResp).Depth}))
    hold on
    plot(repmat([0 max(vecZ(indResp))],[numel(vecProbeAreaEdges) 1])',repmat(-vecProbeAreaEdges,[1 2])','r--')
    text(max(vecZ(indResp))*0.5*ones(size(vecProbeAreaCenters)),-vecProbeAreaCenters,cellProbeAreaLabels)
    hold off
    %ylim([min(get(gca,'ylim')) 0]);
    %xlim([0 0.1]);
    xlabel('ZETA');
    ylabel('Depth from pia (\mum)');
    %h=colorbar;
    %ylabel(h,'ZETA');
    fixfig;
    %title(sprintf('Cortex: %d; subcortex: %d',sum(vecCorrectedDepth(indInclude) > -1000),sum(vecCorrectedDepth(indInclude) < -1500)))
    
    return
    %% assign areas to clusters
    for intCluster=1:numel(sAP.sCluster)
        intArea = find(sAP.sCluster(intCluster).Depth > vecProbeAreaEdges,1,'last');
        if isempty(intArea)
            sAP.sCluster(intCluster).Area = 'root';
        else
            sAP.sCluster(intCluster).Area = replace(cellProbeAreaLabels{intArea},'Midbrain','Nucleus of the optic tract');
        end
    end
    
    %save
    strBackup = strcat(strTarget,'.backup',getDate);
    fprintf('Saving "%s"... [%s]\n',strBackup,getTime);
    copyfile(strTarget,strBackup);
    fprintf('Saving "%s"... [%s]\n',strTarget1,getTime);
    save(strTarget1,'sAP');
    fprintf('Saving "%s"... [%s]\n',strTarget,getTime);
    save(strTarget,'sAP');
    fprintf('Done! [%s]\n',getTime);
    
end