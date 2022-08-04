function [intResultFlag,sRP] = RP_ExportFile(sFile,sRP)
	
	%get synthesized data
	sSynthesis = sFile.sSynthesis;
	sLoad = load(fullpath(sSynthesis.folder,sSynthesis.name));
	sSynthData = sLoad.sSynthData;
	sMetaVar = sRP.sMetaVar;
	sProbeCoords = sFile.sProbeCoords;
	
	%check if atlas is correct
	if ~strcmpi(sProbeCoords.AtlasType,sRP.sAtlas.Type)
		intResultFlag = 0;
		errordlg(sprintf('Current atlas is %s, but coord file atlas is %s!',sRP.sAtlas.Type,sProbeCoords.AtlasType),'Atlas mismatch');
		return;
	end
	
	%get probe location
	dblProbeLength = sProbeCoords.ProbeLengthOriginal*mean(sProbeCoords.VoxelSize);
	dblAdjustedProbeLength = sProbeCoords.sProbeAdjusted.probe_vector_sph(end)*mean(sProbeCoords.VoxelSize);
	dblResizeFactor = dblAdjustedProbeLength/dblProbeLength;
	vecIntersect = round(sProbeCoords.sProbeAdjusted.probe_vector_intersect);
	intEntryStructure = sRP.sAtlas.av(vecIntersect(1),vecIntersect(2),vecIntersect(3));
	strEntryStructure = sRP.sAtlas.st.name{intEntryStructure};
	vecXYZ = flat(sProbeCoords.sProbeAdjusted.probe_vector_cart(1,:)) - flat(sProbeCoords.sProbeAdjusted.probe_vector_intersect);
	[az,el,r] = cart2sph(vecXYZ(1),vecXYZ(2),vecXYZ(3));
	dblDepthOfTip = r*mean(sProbeCoords.VoxelSize);
	
	%get cluster depths
	vecDepthOnProbeInMicrons = sProbeCoords.sProbeAdjusted.depth_per_cluster*mean(sProbeCoords.VoxelSize);
	strPathKilosort = sFile.sClustered.folder;
	sSpikes = loadKSdir(strPathKilosort);
	vecAllSpikeClust = sSpikes.clu;
	vecClustIdx = unique(vecAllSpikeClust);
	
	%get cluster data
	[spikeAmps, vecAllSpikeDepth] = templatePositionsAmplitudes(sSpikes.temps, sSpikes.winv, sSpikes.ycoords, sSpikes.spikeTemplates, sSpikes.tempScalingAmps);
	
	%get depths
	intClustNum = numel(vecClustIdx);
	vecDepth = nan(1,intClustNum);
	vecDepthFromPia = nan(1,intClustNum);
	for intClust=1:intClustNum
		intClustIdx = vecClustIdx(intClust);
		dblTemplateDepth = round(median(vecAllSpikeDepth(vecAllSpikeClust==intClustIdx)));
		vecDepth(intClust) = dblAdjustedProbeLength-dblTemplateDepth*dblResizeFactor;
		vecDepthFromPia(intClust) = dblDepthOfTip-dblTemplateDepth*dblResizeFactor;
	end
	
	%sanity check
	rDepth = corr(vecDepthOnProbeInMicrons(:),vecDepthFromPia(:));
	if rDepth > -0.99 && rDepth < 0.99
		error([mfilename ':DepthMismatch'],'Depth information mismatch between vecDepthOnProbeInMicrons and vecDepthFromPia!');
	end
	
	%get areas
	[vecClustAreaId,cellClustAreaLabel,cellClustAreaFull] = PF_GetAreaPerCluster(sProbeCoords,vecDepth);
	
	%assign cluster data
	sCluster = sSynthData.sCluster;
	intClustNum = numel(vecClustIdx);
	for intClust=1:intClustNum
		sCluster(intClust).Depth = vecDepth(intClust);%depth on probe
		sCluster(intClust).Area = cellClustAreaFull{intClust};
		sCluster(intClust).DepthBelowIntersect = vecDepthFromPia(intClust);%depth in brain
	end
	
	%get sources
	sSources = sSynthData.sSources;
	sSources.sProbeCoords = sProbeCoords;
	
	%get json data
	sJson = sSynthData.sJson;
	if isempty(sJson.subject)
		cellRec = strsplit(sJson.recording,'_');
		sJson.subject = cellRec{1};
	end
	sJson.probe_coords = sprintf('ML=%d;AP=%d;ML-ang=%d;AP-ang=%d;Depth=%d;Length=%d',round([...
		sProbeCoords.sProbeAdjusted.stereo_coordinates.ML...
		sProbeCoords.sProbeAdjusted.stereo_coordinates.AP...
		sProbeCoords.sProbeAdjusted.stereo_coordinates.AngleML...
		sProbeCoords.sProbeAdjusted.stereo_coordinates.AngleAP...
		sProbeCoords.sProbeAdjusted.stereo_coordinates.Depth...
		sProbeCoords.sProbeAdjusted.stereo_coordinates.ProbeLength...
		]));
	
	sJson.entry_structure = strrep(strEntryStructure,' ','_');
	if strcmp(sJson.subject(end),'_'),sJson.subject(end)=[];end
	
	%build output name & check if it exists
	if numel(sJson.subject) > 3 && strcmp(sJson.subject(1:3),'Rec'),sJson.subject=sJson.subject(4:end);end
	strSubject = sJson.subject;
	strRecDate = sJson.date;
	strRecording = sJson.recording;
	strOutputRoot = strcat(strSubject,'_',strRecDate);
	strAPFileOut = strcat(strOutputRoot,'_AP.mat');
	strOutputPath = sRP.strOutputPath;
	strAPFileTarget = fullpath(strOutputPath,strAPFileOut);
	if exist(strAPFileTarget,'file')
		strOldPath = cd(strOutputPath);
		[strAPFileOut,strOutputPath] = uiputfile('*.mat','Select file to write AP output',strAPFileOut);
		cd(strOldPath);
		
		if isempty(strAPFileOut) || (numel(strAPFileOut)==1 && strAPFileOut == 0)
			return;
		end
	end
	strAPFileTarget = fullpath(strOutputPath,strAPFileOut);
	sJson.file_preproAP = strAPFileTarget;
	
	%overwrite data with current metavars
	cellFields = fieldnames(sJson);
	for intField=1:numel(cellFields)
		strField = cellFields{intField};
		if isfield(sMetaVar,strField)
			sJson.(strField) = sMetaVar.(strField);
		end
	end
	
	%% prune cellStim and move originals to sSources
	cellBlock = sSynthData.cellStim;
	sSources.cellBlock = cellBlock;
	for intBlock=1:numel(cellBlock)
		cellBlock{intBlock} = PP_TransformStimToAP(cellBlock{intBlock});
	end
	sSources.sMetaNI = sSynthData.sMetaNI;
	
	%% save json
	%save json file
	strJsonData = jsonencode(sJson);
	strJsonData = strrep(strJsonData,'\','/'); %we're not using escape characters, so just transform everything to forward slashes
	strJsonFileOut = strrep(strAPFileOut,'_AP.mat','_session.json');
	strJsonTarget = fullpath(sSynthesis.folder,strJsonFileOut);
	fprintf('Saving json metadata to %s [%s]\n',strJsonTarget,getTime);
	ptrFile = fopen(strJsonTarget,'w');
	fprintf(ptrFile,strJsonData);
	fclose(ptrFile);
	
	%build AP structure
	sAP = struct;
	sAP.cellBlock = cellBlock;
	if isfield(sSynthData,'sPupil') && ~isempty(sSynthData.sPupil)
		sAP.sPupil = PP_TransformPupilToAP(sSynthData.sPupil);
	end
	sAP.sCluster = sCluster;
	sAP.sSources = sSources;
	sAP.sJson = sJson;
	sAP.stereo_coordinates = sProbeCoords.sProbeAdjusted.stereo_coordinates;
	%add misc NI channels to AP structure
	if isfield(sSynthData,'sMiscNI')
		cellFields = fieldnames(sSynthData.sMiscNI);
		for intField=1:numel(cellFields)
			sAP.(cellFields{intField}) = sSynthData.sMiscNI.(cellFields{intField});
		end
	end
	
	%save
	fprintf('Saving AP data to %s [%s]\n',strAPFileTarget,getTime);
	save(strAPFileTarget,'sAP');
	intResultFlag = 1;
end
