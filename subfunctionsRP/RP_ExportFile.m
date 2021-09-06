function [intResultFlag,sRP] = RP_ExportFile(sFile,sRP)
	
	%load ABA
	intResultFlag = -1;
	if (~isfield(sRP,'tv') || isempty(sRP.tv)) || (~isfield(sRP,'av') || isempty(sRP.av)) || (~isfield(sRP,'st') || isempty(sRP.st))
		[tv,av,st] = RP_LoadABA(sRP.strAllenCCFPath);
		if isempty(tv),return;end
		sRP.tv = tv;
		sRP.av = av;
		sRP.st = st;
	end
	tv = sRP.tv;
	av = sRP.av;
	st = sRP.st;
	
	%get synthesized data
	sSynthesis = sFile.sSynthesis;
	sLoad = load(fullpath(sSynthesis.folder,sSynthesis.name));
	sSynthData = sLoad.sSynthData;
	
	%get probe location
	sProbeCoords = sFile.sProbeCoords;
	vecDepthAreaIdx = sProbeCoords.sProbeAdjusted.probe_areas;
	cellDepthArea = st.safe_name(vecDepthAreaIdx);
	%calculate probe angles
	vecRefVector= (sProbeCoords.sProbeAdjusted.probe_vector(:,1) - sProbeCoords.sProbeAdjusted.probe_vector(:,2));
	[azimuth,elevation,r] = cart2sph(vecRefVector(1),vecRefVector(3),vecRefVector(2));%ML, AP,depth (DV)
	dblAngleAP = rad2deg(azimuth) + 90;
	dblAngleML = rad2deg(elevation);
	vecAngles = mod([dblAngleAP dblAngleML]+180,360)-180;
	vecBrainIntersect = (flat(PH_GetBregma())-flat(sProbeCoords.sProbeAdjusted.probe_intersect([1 3 2])))*10;
	vecLoc_AP_ML = round([vecBrainIntersect(1) -vecBrainIntersect(3)]); %positive ML is right hemisphere
	intProbeDepth = round(sqrt(sum((sProbeCoords.sProbeAdjusted.probe_intersect - sProbeCoords.sProbeAdjusted.probe_vector(:,2)).^2))*10)* ...
		sign(sProbeCoords.sProbeAdjusted.probe_vector(3,2)-sProbeCoords.sProbeAdjusted.probe_intersect(3));
	intEntryStructure = av(round(sProbeCoords.sProbeAdjusted.probe_intersect(1)),...
		round(sProbeCoords.sProbeAdjusted.probe_intersect(3)),round(sProbeCoords.sProbeAdjusted.probe_intersect(2)));
	strEntryStructure = st.safe_name{intEntryStructure};
	dblProbeLength = sqrt(sum((sProbeCoords.sProbeAdjusted.probe_vector(:,1) - sProbeCoords.sProbeAdjusted.probe_vector(:,2)).^2))*10;
	
	%get cluster depths
	strPathKilosort = sFile.sClustered.folder;
	sSpikes = loadKSdir(strPathKilosort);
	vecAllSpikeClust = sSpikes.clu;
	vecClusters = unique(vecAllSpikeClust);
	
	%get cluster data
	[spikeAmps, vecAllSpikeDepth] = templatePositionsAmplitudes(sSpikes.temps, sSpikes.winv, sSpikes.ycoords, sSpikes.spikeTemplates, sSpikes.tempScalingAmps);
	%assign cluster data
	sCluster = sSynthData.sCluster;
	intClustNum = numel(vecClusters);
	for intClust=1:intClustNum
		intClustIdx = vecClusters(intClust);
		intDepth = dblProbeLength-round(median(vecAllSpikeDepth(vecAllSpikeClust==intClustIdx)));
		intDominantChannel = ceil(intDepth/10);
		sCluster(intClust).Depth = intDepth;
		sCluster(intClust).Area = cellDepthArea{intDominantChannel};
		sCluster(intClust).DepthBelowIntersect = intDepth-dblProbeLength+intProbeDepth;
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
	sJson.probe_coords = sprintf('AP=%d;ML=%d;Depth=%d;AP-ang=%d;ML-ang=%d',round([vecLoc_AP_ML intProbeDepth vecAngles]));
	sJson.entry_structure = strrep(strEntryStructure,' ','_');
	if strcmp(sJson.subject(end),'_'),sJson.subject(end)=[];end
	
	%build output name & check if it exists
	if numel(sJson.subject) > 5 && strcmp(sJson.subject(1:5),'RecMA'),sJson.subject=strrep(sJson.subject,'RecMA','MA');end
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
	strJsonFileOut = strrep(strAPFileOut,'_AP.mat','_session.json');
	strJsonTarget = fullpath(sSynthesis.folder,strJsonFileOut);
	fprintf('Saving json metadata to %s [%s]\n',strJsonTarget,getTime);
	ptrFile = fopen(strJsonTarget,'w');
	fprintf(ptrFile,strJsonData);
	fclose(ptrFile);
	
	%build AP structure
	sAP = struct;
	sAP.cellBlock = cellBlock;
	if isfield(sSynthData,'sPupil')
		sAP.sPupil = sSynthData.sPupil;
	end
	sAP.sCluster = sCluster;
	sAP.sSources = sSources;
	sAP.sJson = sJson;
	sAP.vecProbeCoords = [vecLoc_AP_ML intProbeDepth vecAngles]; %AP, ML, depth, AP-angle, ML-angle
	sAP.ProbeCoordsDesc = 'AP, ML, depth, AP-angle, ML-angle';
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