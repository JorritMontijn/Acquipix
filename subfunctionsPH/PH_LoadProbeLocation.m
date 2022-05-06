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
	if isfield(sProbeCoords,'sProbeAdjusted') && isfield(sProbeCoords.sProbeAdjusted,'probe_vector')
		vecSphereVector = sProbeCoords.sProbeAdjusted.probe_vector_sph;
	else
		[vecSphereVector,vecLocBrainIntersect,matRefVector] = PH_Points2vec(sProbeCoords,sAtlas);
	end
	probe_vector_sph = vecSphereVector;
	probe_vector_cart = PH_SphVec2CartVec(vecSphereVector);
	probe_vector_bregma = PH_SphVec2BregmaVec(vecSphereVector,vecLocBrainIntersect,sAtlas);
	
	%add new vectors to current position
	sProbeCoords.sProbeAdjusted.probe_vector_cart = probe_vector_cart;
	sProbeCoords.sProbeAdjusted.probe_vector_sph = probe_vector_sph;
	sProbeCoords.sProbeAdjusted.probe_vector_intersect = vecLocBrainIntersect;
	sProbeCoords.sProbeAdjusted.probe_vector_bregma = probe_vector_bregma;
	sGUI.sProbeCoords = sProbeCoords;
	
	% update gui
	set(sGUI.handles.probe_vector_cart,'XData',probe_vector_cart(:,1), ...
		'YData',probe_vector_cart(:,2),'ZData',probe_vector_cart(:,3));
	set(sGUI.handles.probe_intersect,'XData',vecLocBrainIntersect(1), ...
		'YData',vecLocBrainIntersect(2),'ZData',vecLocBrainIntersect(3));
	set(sGUI.handles.probe_tip,'XData',probe_vector_cart(1,1), ...
		'YData',probe_vector_cart(1,2),'ZData',probe_vector_cart(1,3));
	guidata(hMain, sGUI);
	
	% Update the slice and probe coordinates
	PH_UpdateSlice(hMain);
	PH_UpdateProbeCoordinates(hMain);
	
end