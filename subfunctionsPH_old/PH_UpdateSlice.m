function PH_UpdateSlice(probe_atlas_gui,hFig)

% Get guidata
gui_data = guidata(probe_atlas_gui);

% Only update the slice if it's visible
if strcmp(gui_data.handles.slice_plot(1).Visible,'on')
    
    % Get current position of camera
    curr_campos = campos;
    
    % Get probe vector
    probe_ref_top = gui_data.probe_ref_line(:,1)';
    probe_ref_bottom = gui_data.probe_ref_line(:,2)';
    probe_vector = probe_ref_top - probe_ref_bottom;
    
    % Get probe-camera vector
    probe_camera_vector = probe_ref_top - curr_campos;
    
    % Get the vector to plot the plane in (along with probe vector)
    plot_vector = cross(probe_camera_vector,probe_vector);
    
    % Get the normal vector of the plane
    normal_vector = cross(plot_vector,probe_vector);
    
    % Get the plane offset through the probe
    plane_offset = -(normal_vector*probe_ref_top');
    
    % Define a plane of points to index
    % (the plane grid is defined based on the which cardinal plan is most
    % orthogonal to the plotted plane. this is janky but it works)
    slice_px_space = 3;
    %[~,cam_plane] = max(abs((campos - camtarget)./norm(campos - camtarget)));
    
    [~,cam_plane] = max(abs(normal_vector./norm(normal_vector)));
    
    switch cam_plane
        
        case 1
            [plane_y,plane_z] = meshgrid(1:slice_px_space:size(gui_data.tv,3),1:slice_px_space:size(gui_data.tv,2));
            plane_x = ...
                (normal_vector(2)*plane_y+normal_vector(3)*plane_z + plane_offset)/ ...
                -normal_vector(1);
            
        case 2
            [plane_x,plane_z] = meshgrid(1:slice_px_space:size(gui_data.tv,1),1:slice_px_space:size(gui_data.tv,2));
            plane_y = ...
                (normal_vector(1)*plane_x+normal_vector(3)*plane_z + plane_offset)/ ...
                -normal_vector(2);
            
        case 3
            [plane_x,plane_y] = meshgrid(1:slice_px_space:size(gui_data.tv,1),1:slice_px_space:size(gui_data.tv,3));
            plane_z = ...
                (normal_vector(1)*plane_x+normal_vector(2)*plane_y + plane_offset)/ ...
                -normal_vector(3);
            
    end
    
    % Get the coordiates on the plane
    x_idx = round(plane_x);
    y_idx = round(plane_y);
    z_idx = round(plane_z);
    
    % Find plane coordinates in bounds with the volume
    use_xd = x_idx > 0 & x_idx < size(gui_data.tv,1);
    use_yd = y_idx > 0 & y_idx < size(gui_data.tv,3);
    use_zd = z_idx > 0 & z_idx < size(gui_data.tv,2);
    use_idx = use_xd & use_yd & use_zd;
    
    curr_slice_idx = sub2ind(size(gui_data.tv),x_idx(use_idx),z_idx(use_idx),y_idx(use_idx));
    
    % Find plane coordinates that contain brain
    curr_slice_isbrain = false(size(use_idx));
    curr_slice_isbrain(use_idx) = gui_data.av(curr_slice_idx) > 1;
    
    % Index coordinates in bounds + with brain
    grab_pix_idx = sub2ind(size(gui_data.tv),x_idx(curr_slice_isbrain),z_idx(curr_slice_isbrain),y_idx(curr_slice_isbrain));
    
    % Grab pixels from (selected) volume
    curr_slice = nan(size(use_idx));
    switch gui_data.handles.slice_volume
        case 'tv'
            curr_slice(curr_slice_isbrain) = gui_data.tv(grab_pix_idx);
            colormap(gui_data.handles.axes_atlas,'gray');
            caxis([0,255]);
        case 'av'
            curr_slice(curr_slice_isbrain) = gui_data.av(grab_pix_idx);
            colormap(gui_data.handles.axes_atlas,gui_data.cmap);
            caxis([1,size(gui_data.cmap,1)]);
    end
    
    % Update the slice display
    set(gui_data.handles.slice_plot,'XData',plane_x,'YData',plane_y,'ZData',plane_z,'CData',curr_slice);
    
    % Upload gui_data
    guidata(probe_atlas_gui, gui_data);
    
end

end