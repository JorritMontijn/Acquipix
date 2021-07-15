function probe_vector_ccf = PH_GetProbeVector(probe_atlas_gui)
	
	% Get guidata
	gui_data = guidata(probe_atlas_gui);
	
	%get probe location
	probe_vector_ccf(:,1) = gui_data.handles.probe_line.XData;
	probe_vector_ccf(:,2) = gui_data.handles.probe_line.ZData;
	probe_vector_ccf(:,3) = gui_data.handles.probe_line.YData;
end