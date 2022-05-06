function probe_vector_ccf = PH_GetProbeVector(hMain)
	
	% Get guidata
	sGUI = guidata(hMain);
	
	%get probe location
	probe_vector_ccf(:,1) = sGUI.handles.probe_vector_cart.XData;
	probe_vector_ccf(:,2) = sGUI.handles.probe_vector_cart.ZData;
	probe_vector_ccf(:,3) = sGUI.handles.probe_vector_cart.YData;
end