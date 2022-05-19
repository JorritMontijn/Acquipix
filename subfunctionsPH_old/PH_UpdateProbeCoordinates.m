function PH_UpdateProbeCoordinates(hMain,varargin)
	
	% Get guidata
	sGUI = guidata(hMain);
	
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
	probe_area_ids = interp3(single(sGUI.av(1:pixel_space:end,1:pixel_space:end,1:pixel_space:end)), ...
		round(probe_zcoords/pixel_space),round(probe_xcoords/pixel_space),round(probe_ycoords/pixel_space),'nearest')';
	probe_area_ids(isnan(probe_area_ids))=1;
	probe_area_boundaries = intersect(unique([find(~isnan(probe_area_ids),1,'first'); ...
		find(diff(probe_area_ids) ~= 0);find(~isnan(probe_area_ids),1,'last')]),find(~isnan(probe_area_ids)));
	probe_area_centers = probe_area_boundaries(1:end-1) + diff(probe_area_boundaries)/2;
	probe_area_labels = sGUI.st.acronym(probe_area_ids(round(probe_area_centers)));
	
	%get parent structure
	[a,probe_areas_parent]=ismember(sGUI.st.parent_structure_id(probe_area_ids),sGUI.st.id);
	probe_areas_parent(isnan(probe_areas_parent) | probe_areas_parent==0)=1;
	probe_area_boundaries_parent = intersect(unique([find(~isnan(probe_areas_parent),1,'first'); ...
		find(diff(probe_areas_parent) ~= 0);find(~isnan(probe_areas_parent),1,'last')]),find(~isnan(probe_areas_parent)));
	probe_area_centers_parent = probe_area_boundaries_parent(1:end-1) + diff(probe_area_boundaries_parent)/2;
	probe_area_labels_parent = sGUI.st.acronym(probe_areas_parent(round(probe_area_centers_parent)));
	
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
		num2str(round(sGUI.probe_angle(2))) char(176) ' ML angle, ' ...
		num2str(round(sGUI.step_size*100)) '% step size'];
	set(sGUI.probe_coordinates_text,'String',probe_text);
	
	% Update the probe areas
	yyaxis(sGUI.handles.axes_probe_areas,'right');
	set(sGUI.handles.probe_areas_plot,'YData',[1:length(probe_area_ids)]*10,'CData',probe_area_ids);
	set(sGUI.handles.axes_probe_areas,'YTick',probe_area_centers*10,'YTickLabels',probe_area_labels);
	yyaxis(sGUI.handles.axes_probe_areas2,'right');
	set(sGUI.handles.probe_areas_plot2,'YData',[1:length(probe_area_ids)]*10,'CData',probe_area_ids);
	set(sGUI.handles.axes_probe_areas2,'YTick',probe_area_centers*10,'YTickLabels',probe_area_labels);
	
	%save current data
	sGUI.output.probe_vector = probe_vector;
	sGUI.output.probe_areas = probe_area_ids;
	sGUI.output.probe_areas_parent = probe_areas_parent;
	sGUI.output.probe_intersect = trajectory_brain_intersect;
	
	%% plot boundaries
	cellHandleName = {'probe_clust_bounds','probe_zeta_bounds','probe_xcorr_bounds'};
	cellAxesHandles = {sGUI.handles.probe_clust,sGUI.handles.probe_zeta,sGUI.handles.probe_xcorr};
	for intPlot=1:numel(cellHandleName)
		delete(sGUI.handles.(cellHandleName{intPlot}));
		hAx = cellAxesHandles{intPlot};
		boundary_lines = gobjects;
		vecLimX = get(hAx,'xlim');
		%vecBoundY = probe_area_boundaries_parent*10;
		vecBoundY = probe_area_boundaries*10;
		for intBound = 1:length(vecBoundY)
			%boundary_lines(intBound,1) = line(hAx,vecLimX, ...
			%	repmat(vecBoundY(intBound),1,2),'color','b','linewidth',1);
			boundary_lines(intBound,1) = cline(hAx,vecLimX, ...
				repmat(vecBoundY(intBound),1,2),[],0.5*[1 1 1],1);
			boundary_lines(intBound,1).EdgeAlpha = 0.5;
			boundary_lines(intBound,1).LineWidth = 1;
			if intPlot==3
				%boundary_lines(intBound+length(vecBoundY),1) = line(hAx,repmat(vecBoundY(intBound),1,2), ...
				%	vecLimX,'color','b','linewidth',1);
				boundary_lines(intBound+length(vecBoundY),1) = cline(hAx,repmat(vecBoundY(intBound),1,2), ...
					vecLimX,[],0.5*[1 1 1],1);
				boundary_lines(intBound+length(vecBoundY),1).EdgeAlpha = 0.5;
				boundary_lines(intBound+length(vecBoundY),1).LineWidth = 1;
				
			end
		end
		sGUI.handles.(cellHandleName{intPlot}) = boundary_lines;
	end
	
	% Upload gui_data
	guidata(hMain, sGUI);
	
end

