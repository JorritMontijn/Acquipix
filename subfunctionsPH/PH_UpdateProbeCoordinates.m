function PH_UpdateProbeCoordinates(hMain,vecSphereVector)
	% Get guidata
	error('somehow x and y are swapped?'
	sGUI = guidata(hMain);
	
	%calculate vectors in different spaces
	probe_vector_sph = vecSphereVector;
	probe_vector_cart = PH_SphVec2CartVec(vecSphereVector);
	vecLocationBrainIntersection = PH_GetBrainIntersection(probe_vector_cart,sGUI.sAtlas.av);
	probe_vector_bregma = PH_SphVec2BregmaVec(vecSphereVector,vecLocationBrainIntersection,sGUI.sAtlas);
	
	% (if the probe doesn't intersect the brain, don't update)
	if isempty(vecLocationBrainIntersection)
		return
	end
	
	%add new vectors to current position
	sGUI.sProbeCoords.sProbeAdjusted.probe_vector_cart = probe_vector_cart;
	sGUI.sProbeCoords.sProbeAdjusted.probe_vector_sph = probe_vector_sph;
	sGUI.sProbeCoords.sProbeAdjusted.probe_vector_intersect = vecLocationBrainIntersection;
	sGUI.sProbeCoords.sProbeAdjusted.probe_vector_bregma = probe_vector_bregma;
	
	% update gui
	set(sGUI.handles.probe_vector_cart,'XData',probe_vector_cart(:,1), ...
		'YData',probe_vector_cart(:,2),'ZData',probe_vector_cart(:,3));
	set(sGUI.handles.probe_intersect,'XData',vecLocationBrainIntersection(1), ...
		'YData',vecLocationBrainIntersection(2),'ZData',vecLocationBrainIntersection(3));
	set(sGUI.handles.probe_tip,'XData',probe_vector_cart(1,1), ...
		'YData',probe_vector_cart(1,2),'ZData',probe_vector_cart(1,3));
	guidata(hMain, sGUI);
	
	%get locations along probe
	probe_n_coords = sqrt(sum(diff(probe_vector_cart,[],1).^2));
	[probe_xcoords,probe_ycoords,probe_zcoords] = deal( ...
		linspace(probe_vector_cart(2,1),probe_vector_cart(1,1),probe_n_coords), ...
		linspace(probe_vector_cart(2,2),probe_vector_cart(1,2),probe_n_coords), ...
		linspace(probe_vector_cart(2,3),probe_vector_cart(1,3),probe_n_coords));
	
	%get areas
	intAtlasDownsample = 5;
	probe_area_ids = interp3(single(sGUI.sAtlas.av(1:intAtlasDownsample:end,1:intAtlasDownsample:end,1:intAtlasDownsample:end)), ...
		round(probe_xcoords/intAtlasDownsample),round(probe_ycoords/intAtlasDownsample),round(probe_zcoords/intAtlasDownsample),'nearest')';
	probe_area_ids(isnan(probe_area_ids))=1;
	probe_area_boundaries = intersect(unique([find(~isnan(probe_area_ids),1,'first'); ...
		find(diff(probe_area_ids) ~= 0);find(~isnan(probe_area_ids),1,'last')]),find(~isnan(probe_area_ids)));
	probe_area_centers = probe_area_boundaries(1:end-1) + diff(probe_area_boundaries)/2;
	probe_area_labels = sGUI.sAtlas.st.acronym(probe_area_ids(round(probe_area_centers)));
	
	%get parent structure
	%[a,probe_areas_parent]=ismember(sGUI.sAtlas.st.parent_structure_id(probe_area_ids),sGUI.sAtlas.st.id);
	%probe_areas_parent(isnan(probe_areas_parent) | probe_areas_parent==0)=1;
	%probe_area_boundaries_parent = intersect(unique([find(~isnan(probe_areas_parent),1,'first'); ...
	%	find(diff(probe_areas_parent) ~= 0);find(~isnan(probe_areas_parent),1,'last')]),find(~isnan(probe_areas_parent)));
	%probe_area_centers_parent = probe_area_boundaries_parent(1:end-1) + diff(probe_area_boundaries_parent)/2;
	%probe_area_labels_parent = sGUI.sAtlas.st.acronym(probe_areas_parent(round(probe_area_centers_parent)));
	
	% Update the text
	probe_text = ['Brain intersection at: ' ....
		num2str(probe_vector_bregma(1)) ' ML, ', ...
		num2str(probe_vector_bregma(2)) ' AP; ', ...
		'Probe depth ' num2str(probe_vector_bregma(6)) ', ' ...
		num2str(round(probe_vector_bregma(4))) char(176) ' ML angle, ' ...
		num2str(round(probe_vector_bregma(5))) char(176) ' AP angle, ' ...
		'Probe length ' num2str(round(sGUI.sProbeCoords.ProbeLengthMicrons)) ' microns, ' ...
		num2str(round(sGUI.step_size*100)) '% step size' ...
		];
	set(sGUI.probe_coordinates_text,'String',probe_text);
	
	% Update the probe areas
	yyaxis(sGUI.handles.axes_probe_areas,'right');
	set(sGUI.handles.probe_areas_plot,'YData',[1:length(probe_area_ids)]*10,'CData',probe_area_ids);
	set(sGUI.handles.axes_probe_areas,'YTick',probe_area_centers*10,'YTickLabels',probe_area_labels);
	yyaxis(sGUI.handles.axes_probe_areas2,'right');
	set(sGUI.handles.probe_areas_plot2,'YData',[1:length(probe_area_ids)]*10,'CData',probe_area_ids);
	set(sGUI.handles.axes_probe_areas2,'YTick',probe_area_centers*10,'YTickLabels',probe_area_labels);
	
	%save current data
	sGUI.output.probe_vector = probe_vector_cart;
	sGUI.output.probe_areas = probe_area_ids;
	%sGUI.output.probe_areas_parent = probe_areas_parent;
	sGUI.output.probe_intersect = vecLocationBrainIntersection;
	
	%% plot boundaries
	%extract boundaries
	matAreaColors = sGUI.cmap(probe_area_ids,:);
	dblAtlasSize = 10;
	vecBoundY = dblAtlasSize*find(~all(diff(matAreaColors,1,1) == 0,2));
	vecColor = [0.5 0.5 0.5 0.5];
	
	%plot
	cellHandleName = {'probe_clust_bounds','probe_zeta_bounds','probe_xcorr_bounds'};
	cellAxesHandles = {sGUI.handles.probe_clust,sGUI.handles.probe_zeta,sGUI.handles.probe_xcorr};
	for intPlot=1:numel(cellHandleName)
		delete(sGUI.handles.(cellHandleName{intPlot}));
		hAx = cellAxesHandles{intPlot};
		boundary_lines = gobjects;
		vecLimX = get(hAx,'xlim');
		boundary_lines = line(hAx,repmat(vecLimX,numel(vecBoundY),1)',repmat(vecBoundY,1,2)','Color',vecColor,'LineWidth',1);
		if intPlot==3
			boundary_lines2 = line(hAx,repmat(vecBoundY,1,2)',repmat(vecLimX,numel(vecBoundY),1)','Color',vecColor,'LineWidth',1);
			boundary_lines = cat(1,boundary_lines,boundary_lines2);
		end
		sGUI.handles.(cellHandleName{intPlot}) = boundary_lines;
	end
	
	% Upload gui_data
	guidata(hMain, sGUI);
	
	
	%% update slice
	PH_UpdateSlice(hMain);
	
end

