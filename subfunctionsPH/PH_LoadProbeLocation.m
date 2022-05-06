function PH_LoadProbeLocation(hMain,sProbeCoords,sAtlas)
	% Load histology points
	
	% Get guidata
	sGUI = guidata(hMain);
	
	% Get guidata
	matHistoPoints = sProbeCoords.cellPoints{sProbeCoords.intProbeIdx};
	
	%plot histology points
	delete(sGUI.handles.probe_points);
	sGUI.handles.probe_points = scatter3(sGUI.handles.axes_atlas,matHistoPoints(:,1),matHistoPoints(:,2),matHistoPoints(:,3),20,[0 0 0.8],'.','Linewidth',1);
	
	%get vector from points
	if isfield(sProbeCoords,'sProbeAdjusted') && isfield(sProbeCoords.sProbeAdjusted,'probe_vector_sph')
		vecSphereVector = sProbeCoords.sProbeAdjusted.probe_vector_sph;
	else
		[vecSphereVector,vecLocBrainIntersect,matRefVector] = PH_Points2vec(sProbeCoords,sAtlas);
	end
	
	% Update probe coordinates
	PH_UpdateProbeCoordinates(hMain,vecSphereVector);
	
end