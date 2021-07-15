function PH_LoadProbeLocation(probe_atlas_gui,probe_vector_ccf)
	% Load histology points
	
	% Philip's GUI: not saved in native CCF order?
	% plot3(histology_points(:,3),histology_points(:,1),histology_points(:,2),'.b','MarkerSize',20);
	% line(P(:,3),P(:,1),P(:,2),'color','k','linewidth',2)
	
	%check if input is supplied; otherwise open file
	if ~exist('probe_vector_ccf','var') || isempty(probe_vector_ccf)
		[strFile,strPath] = uigetfile('*.mat','Select probe location file');
		sLoad = load(fullpath(strPath,strFile));
		if isnumeric(sLoad) && all(size(sLoad) == [3 2])
			probe_vector_ccf = sLoad;
		elseif isstruct(sLoad) && isfield(sLoad.probe_vector_ccf)
			probe_vector_ccf = sLoad.probe_vector_ccf;
		else
			errordlg('This file is not a probe location file','Wrong filetype');
			return;
		end
	end
	
	% Get guidata
	gui_data = guidata(probe_atlas_gui);
	
	r0 = mean(probe_vector_ccf,1);
	xyz = bsxfun(@minus,probe_vector_ccf,r0);
	[~,~,V] = svd(xyz,0);
	histology_probe_direction = V(:,1);
	
	probe_eval_points = [-1000,1000];
	probe_line_endpoints = bsxfun(@plus,bsxfun(@times,probe_eval_points',histology_probe_direction'),r0);
	
	% Place the probe on the histology best-fit axis
	probe_ref_top = probe_line_endpoints(1,[1,3,2]);
	probe_ref_bottom = probe_line_endpoints(2,[1,3,2]);
	probe_ref_vector = [probe_ref_top;probe_ref_bottom]';
	
	gui_data.probe_ref_line=probe_ref_vector;
	
	set(gui_data.handles.probe_line,'XData',probe_vector_ccf(:,1), ...
		'YData',probe_vector_ccf(:,3),'ZData',probe_vector_ccf(:,2));
	
	% Upload gui_data
	[theta,phi] = cart2sph(diff(probe_ref_vector(1,:)),diff(probe_ref_vector(2,:)),diff(probe_ref_vector(3,:)));
	gui_data.probe_angle = ([theta,phi]/(2*pi))*360;
	guidata(probe_atlas_gui, gui_data);
	
	% Update the slice and probe coordinates
	PH_UpdateSlice(probe_atlas_gui);
	PH_UpdateProbeCoordinates(probe_atlas_gui);
	
end