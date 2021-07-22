function PH_UpdateProbeCoordinates(probe_atlas_gui,varargin)
	
	% Get guidata
	sGUI = guidata(probe_atlas_gui);
	
	%get coords
	probe_vector = cell2mat(get(sGUI.handles.probe_line,{'XData','YData','ZData'})');
	probe_n_coords = sqrt(sum(diff(probe_vector,[],2).^2));
	[probe_xcoords,probe_ycoords,probe_zcoords] = deal( ...
		linspace(probe_vector(1,1),probe_vector(1,2),probe_n_coords), ...
		linspace(probe_vector(2,1),probe_vector(2,2),probe_n_coords), ...
		linspace(probe_vector(3,1),probe_vector(3,2),probe_n_coords));

	% Get the positions of the probe and trajectory reference
	trajectory_brain_intersect = PH_GetBrainIntersection(probe_vector,sGUI.av);
	
	% (if the probe doesn't intersect the brain, don't update)
	if isempty(trajectory_brain_intersect)
		return
	end
	
	%plot entry point
	sGUI.handles.probe_intersect.XData = trajectory_brain_intersect(1);
	sGUI.handles.probe_intersect.YData = trajectory_brain_intersect(2);
	sGUI.handles.probe_intersect.ZData = trajectory_brain_intersect(3);
	
	%get areas
	pixel_space = 5;
	probe_areas = interp3(single(sGUI.av(1:pixel_space:end,1:pixel_space:end,1:pixel_space:end)), ...
		round(probe_zcoords/pixel_space),round(probe_xcoords/pixel_space),round(probe_ycoords/pixel_space),'nearest')';
	probe_area_boundaries = intersect(unique([find(~isnan(probe_areas),1,'first'); ...
		find(diff(probe_areas) ~= 0);find(~isnan(probe_areas),1,'last')]),find(~isnan(probe_areas)));
	probe_area_centers = probe_area_boundaries(1:end-1) + diff(probe_area_boundaries)/2;
	probe_area_labels = sGUI.st.safe_name(probe_areas(round(probe_area_centers)));
	
	% Get position of brain intersect relative to bregma
	probe_bregma_coordinate = round((sGUI.bregma([1,3])' - trajectory_brain_intersect(1:2))*10);
	
	% Get the depth of the bottom of the probe (sign: hack by z offset)
	probe_depth = round(sqrt(sum((trajectory_brain_intersect - probe_vector(:,2)).^2))*10)* ...
		sign(probe_vector(3,2)-trajectory_brain_intersect(3));
	
	% Update the text
	probe_text = ['Brain intersection at: ' ....
		num2str(probe_bregma_coordinate(1)) ' AP, ', ...
		num2str(-probe_bregma_coordinate(2)) ' ML; ', ...
		'Probe depth ' num2str(probe_depth) ', ' ...
		num2str(round(sGUI.probe_angle(1))) char(176) ' AP angle, ' ...
		num2str(round(sGUI.probe_angle(2))) char(176) ' ML angle'];
	set(sGUI.probe_coordinates_text,'String',probe_text);
	
	% Update the probe areas
	yyaxis(sGUI.handles.axes_probe_areas,'right');
	set(sGUI.handles.probe_areas_plot,'YData',[1:length(probe_areas)]*10,'CData',probe_areas);
	set(sGUI.handles.axes_probe_areas,'YTick',probe_area_centers*10,'YTickLabels',probe_area_labels);
	
	% Upload gui_data
	guidata(probe_atlas_gui, sGUI);
	
end

