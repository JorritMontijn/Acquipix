function PH_KeyPress(hMain,eventdata)
	
	%dummy for testing
	if ~exist('eventdata','var')
		eventdata = struct;
		eventdata.Key = 'uparrow';
		eventdata.Modifier = [];
	end
	
	% Get guidata
	gui_data = guidata(hMain);
	if toc(gui_data.lastPress) < 0.1;return;end
	gui_data.lastPress = tic;
	guidata(hMain, gui_data);
	
	if strcmp(eventdata.Key,'uparrow') || strcmp(eventdata.Key,'downarrow')
		dblSign = double(strcmp(eventdata.Key,'downarrow'))*2-1;
		dblStep = gui_data.step_size;
		if isempty(eventdata.Modifier)
			% Up: move probe anterior
			dblMoveAP = mean(gui_data.sAtlas.VoxelSize)*dblSign*dblStep;
			vecSphereVector = PH_CartVec2SphVec(PH_GetProbeVector(hMain));
			vecNewSphereVector = vecSphereVector - [0 dblMoveAP 0 0 0 0];
			PH_UpdateProbeCoordinates(hMain,vecNewSphereVector)
		elseif any(strcmp(eventdata.Modifier,'shift'))
			% Shift-up: increase AP angle
			dblRotateAP = dblSign*dblStep;
			vecSphereVector = PH_CartVec2SphVec(PH_GetProbeVector(hMain));
			vecNewSphereVector = vecSphereVector + [0 0 0 0 dblRotateAP 0];
			PH_UpdateProbeCoordinates(hMain,vecNewSphereVector)
		elseif any(strcmp(eventdata.Modifier,'alt'))
			% Alt-up: raise probe
			dblMoveUpDown = mean(gui_data.sAtlas.VoxelSize)*dblSign*dblStep;
			vecCartOld = PH_GetProbeVector(hMain);
			vecDelta = diff(vecCartOld,[],1)./ ...
				norm(diff(vecCartOld,[],1))*dblMoveUpDown;
			vecCartNew = bsxfun(@minus,vecCartOld,vecDelta);
			
			PH_UpdateProbeCoordinates(hMain,PH_CartVec2SphVec(vecCartNew));
		end
		
	elseif strcmp(eventdata.Key,'rightarrow') || strcmp(eventdata.Key,'leftarrow')
		dblSign = double(strcmp(eventdata.Key,'rightarrow'))*2-1;
		dblStep = gui_data.step_size;
		if isempty(eventdata.Modifier)
			% Right: move probe right
			dblMoveML = mean(gui_data.sAtlas.VoxelSize)*dblSign*dblStep;
			vecSphereVector = PH_CartVec2SphVec(PH_GetProbeVector(hMain));
			vecNewSphereVector = vecSphereVector - [dblMoveML 0 0 0 0 0];
			PH_UpdateProbeCoordinates(hMain,vecNewSphereVector)
		elseif any(strcmp(eventdata.Modifier,'shift'))
			% Ctrl-right: increase vertical angle
			dblRotateML = dblSign*dblStep;
			vecSphereVector = PH_CartVec2SphVec(PH_GetProbeVector(hMain));
			vecNewSphereVector = vecSphereVector - [0 0 0 dblRotateML 0 0];
			PH_UpdateProbeCoordinates(hMain,vecNewSphereVector)
		end
		
	elseif strcmp(eventdata.Key,'c')
		
		% Bring up controls again
		PH_DisplayControls;
		
	elseif strcmp(eventdata.Key,'b')
		% Toggle brain outline visibility
		current_visibility = gui_data.handles.cortex_outline.Visible;
		switch current_visibility; case 'on'; new_visibility = 'off'; case 'off'; new_visibility = 'on'; end;
		set(gui_data.handles.cortex_outline,'Visible',new_visibility);
		guidata(hMain, gui_data);
		
	elseif strcmp(eventdata.Key,'a')
		% Toggle plotted structure visibility
		if ~isempty(gui_data.structure_plot_idx)
			current_visibility = get(gui_data.handles.structure_patch(1),'Visible');
			switch current_visibility; case 'on'; new_visibility = 'off'; case 'off'; new_visibility = 'on'; end;
			set(gui_data.handles.structure_patch,'Visible',new_visibility);
			guidata(hMain, gui_data);
		end
		
	elseif strcmp(eventdata.Key,'s')
		% Toggle slice volume/visibility
		slice_volumes = {'tv','av','none'};
		new_slice_volume = slice_volumes{circshift( ...
			strcmp(gui_data.handles.slice_volume,slice_volumes),[0,1])};
		
		if strcmp(new_slice_volume,'none')
			set(gui_data.handles.slice_plot,'Visible','off');
		else
			set(gui_data.handles.slice_plot,'Visible','on');
		end
		
		gui_data.handles.slice_volume = new_slice_volume;
		guidata(hMain, gui_data);
		
		PH_UpdateSlice(hMain);
		
	elseif strcmp(eventdata.Key,'p')
		% Toggle probe visibility
		current_visibility = gui_data.handles.probe_ref_line.Visible;
		switch current_visibility; case 'on'; new_visibility = 'off'; case 'off'; new_visibility = 'on'; end;
		set(gui_data.handles.probe_ref_line,'Visible',new_visibility);
		set(gui_data.handles.probe_line,'Visible',new_visibility);
		guidata(hMain, gui_data);
		
	elseif strcmp(eventdata.Key,'r')
		% Toggle 3D rotation
		h = rotate3d(gui_data.handles.axes_atlas);
		switch h.Enable
			case 'off'
				h.Enable = 'on';
				% Update the slice whenever a rotation is completed
				h.ActionPostCallback = @update_slice;
				%(need to restore key-press functionality with rotation)
				hManager = uigetmodemanager(hMain);
				[hManager.WindowListenerHandles.Enabled] = deal(false);
				set(hMain,'KeyPressFcn',@PH_KeyPress);
			case 'on'
				h.Enable = 'off';
		end
		
	elseif strcmp(eventdata.Key,'m')
		% Set probe angle
		PH_SetProbePosition(hMain);
		
	elseif strcmp(eventdata.Key,'equal') || strcmp(eventdata.Key,'add')
		% Add structure(s) to display
		slice_spacing = 10;
		
		% Prompt for which structures to show (only structures which are
		% labelled in the slice-spacing downsampled annotated volume)
		
		if any(strcmp(eventdata.Modifier,'shift'))
			%increase step size
			gui_data.step_size = gui_data.step_size/0.9;
			guidata(hMain, gui_data);
			PH_UpdateProbeCoordinates(hMain);
			
		elseif any(strcmp(eventdata.Modifier,'control'))
			% (shift: use hierarchy search)
			plot_structures = hierarchicalSelect(gui_data.st);
			
			if ~isempty(plot_structures) % will be empty if dialog was cancelled
				% get all children of this one
				thisID = gui_data.st.id(plot_structures);
				idStr = sprintf('/%d/', thisID);
				theseCh = find(cellfun(@(x)contains(x,idStr), gui_data.st.structure_id_path));
				
				% plot the structure
				slice_spacing = 5;
				plot_structure_color = hex2dec(reshape(gui_data.st.color_hex_triplet{plot_structures},3,[]))./255;
				structure_3d = isosurface(permute(ismember(gui_data.av(1:slice_spacing:end, ...
					1:slice_spacing:end,1:slice_spacing:end),theseCh),[3,1,2]),0);
				
				structure_alpha = 0.2;
				gui_data.structure_plot_idx(end+1) = plot_structures;
				gui_data.handles.structure_patch(end+1) = patch('Vertices',structure_3d.vertices*slice_spacing, ...
					'Faces',structure_3d.faces, ...
					'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);
				guidata(hMain, gui_data);
			end
			
		else
			% (no shift/control: list in native CCF order)
			
			parsed_structures = unique(reshape(gui_data.av(1:slice_spacing:end, ...
				1:slice_spacing:end,1:slice_spacing:end),[],1));
			
			eventdata.Modifier
			
			if ~any(strcmp(eventdata.Modifier,'alt'))
				% (no alt: list all)
				plot_structures_parsed = listdlg('PromptString','Select a structure to plot:', ...
					'ListString',gui_data.st.safe_name(parsed_structures),'ListSize',[520,500]);
				plot_structures = parsed_structures(plot_structures_parsed);
			else
				% (alt: search list)
				structure_search = lower(inputdlg('Search structures'));
				structure_match = find(contains(lower(gui_data.st.safe_name),structure_search));
				list_structures = intersect(parsed_structures,structure_match);
				if isempty(list_structures)
					error('No structure search results')
				end
				
				plot_structures_parsed = listdlg('PromptString','Select a structure to plot:', ...
					'ListString',gui_data.st.safe_name(list_structures),'ListSize',[520,500]);
				plot_structures = list_structures(plot_structures_parsed);
			end
			
			if ~isempty(plot_structures)
				for curr_plot_structure = reshape(plot_structures,1,[])
					% If this label isn't used, don't plot
					if ~any(reshape(gui_data.av( ...
							1:slice_spacing:end,1:slice_spacing:end,1:slice_spacing:end),[],1) == curr_plot_structure)
						disp(['"' gui_data.st.safe_name{curr_plot_structure} '" is not parsed in the atlas'])
						continue
					end
					
					gui_data.structure_plot_idx(end+1) = curr_plot_structure;
					
					plot_structure_color = hex2dec(reshape(gui_data.st.color_hex_triplet{curr_plot_structure},2,[])')./255;
					structure_3d = isosurface(permute(gui_data.av(1:slice_spacing:end, ...
						1:slice_spacing:end,1:slice_spacing:end) == curr_plot_structure,[3,1,2]),0);
					
					structure_alpha = 0.2;
					gui_data.handles.structure_patch(end+1) = patch('Vertices',structure_3d.vertices*slice_spacing, ...
						'Faces',structure_3d.faces, ...
						'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);
				end
				guidata(hMain, gui_data);
				
			end
		end
		
	elseif strcmp(eventdata.Key,'hyphen') || strcmp(eventdata.Key,'subtract')
		if any(strcmp(eventdata.Modifier,'shift'))
			%decrease step size
			gui_data.step_size = gui_data.step_size*0.9;
			guidata(hMain, gui_data);
			PH_UpdateProbeCoordinates(hMain);
			
		else
			% Remove structure(s) already plotted
			if ~isempty(gui_data.structure_plot_idx)
				remove_structures = listdlg('PromptString','Select a structure to remove:', ...
					'ListString',gui_data.st.safe_name(gui_data.structure_plot_idx));
				delete(gui_data.handles.structure_patch(remove_structures))
				gui_data.structure_plot_idx(remove_structures) = [];
				gui_data.handles.structure_patch(remove_structures) = [];
				guidata(hMain, gui_data);
			end
		end
		
	elseif strcmp(eventdata.Key,'x')
		% Export the probe coordinates in Allen CCF to the workspace
		probe_vector_ccf = PH_GetProbeVector(hMain);
		assignin('base','probe_vector_ccf',probe_vector_ccf)
		uisave('probe_vector_ccf',['ProbeLocationFile' getDate]);
	elseif strcmp(eventdata.Key,'h')
		% Load probe histology points, plot line of best fit
		PH_LoadProbeLocation(hMain);
	end
end

