function intProbeIdx = PH_SelectProbeNr(cellPoints,strDefName,tv,av,st)
	
	%% generate selection options
	intProbeNum = numel(cellPoints);
	cellProbes = cell(1,intProbeNum);
	for intProbe=1:intProbeNum
		%get probe vector from points
		matPoints = cellPoints{intProbe};
		[dummy,vecReorder]=sort(matPoints(:,2),'ascend');
		matPoints = matPoints(vecReorder,[1 2 3]);
		[probe_vector,vecBrainIntersection,probe_ref_vector] = PH_Points2vec(matPoints,av);
		vecBrainIntersection = round(vecBrainIntersection);
		cellPoints{intProbe} = matPoints;
		
		%get area
		intIntersectArea = av(vecBrainIntersection(1),vecBrainIntersection(3),vecBrainIntersection(2));
		cellAreas = string(st.name);
		strArea = cellAreas{intIntersectArea};
		cellProbes{intProbe} = sprintf('Probe %d, starting at %s',intProbe,strArea);
	end
	
	%% get probe nr
	%show probes
	intProbeIdx = listdlg('Name','Select probe','PromptString',sprintf('Select probe # for %s',strDefName),...
		'SelectionMode','single','ListString',cellProbes,'ListSize',[400 20*intProbeNum]);
	