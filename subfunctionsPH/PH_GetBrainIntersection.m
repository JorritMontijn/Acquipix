function vecLocationBrainIntersection = PH_GetBrainIntersection(probe_vector_cart,av)
	
	%calculate ref vector from probe vector
	r0 = mean(probe_vector_cart,1);
	xyz = bsxfun(@minus,probe_vector_cart,r0);
	[~,~,V] = svd(xyz,0);
	histology_probe_direction = V(:,1);
	
	probe_eval_points = [-1000 1000];
	probe_end_relative = bsxfun(@times,probe_eval_points,histology_probe_direction);
	probe_line_endpoints = bsxfun(@plus,probe_end_relative',r0);
	
	% Place the probe on the histology best-fit axis
	probe_ref_top = probe_line_endpoints(1,[1,2,3]);
	probe_ref_bottom = probe_line_endpoints(2,[1,2,3]);
	probe_ref_vector = [probe_ref_top;probe_ref_bottom];
	
	% Get the positions of the probe and trajectory reference
	intAtlasDownsample = 5;
	trajectory_n_coords = max(abs(diff(probe_ref_vector,[],1)))/intAtlasDownsample;
	[trajectory_xcoords,trajectory_ycoords,trajectory_zcoords] = deal( ...
		linspace(probe_ref_vector(1,1),probe_ref_vector(2,1),trajectory_n_coords), ...
		linspace(probe_ref_vector(1,2),probe_ref_vector(2,2),trajectory_n_coords), ...
		linspace(probe_ref_vector(1,3),probe_ref_vector(2,3),trajectory_n_coords));
	
	% Get brain labels across the probe and trajectory, and intersection with brain
	trajectory_areas = interp3(single(av(1:intAtlasDownsample:end,1:intAtlasDownsample:end,1:intAtlasDownsample:end)), ...
		round(trajectory_xcoords/intAtlasDownsample),round(trajectory_ycoords/intAtlasDownsample),round(trajectory_zcoords/intAtlasDownsample),'nearest');
	
	%if vecRefVector(1) >= 0
		trajectory_brain_idx = find(trajectory_areas > 1,1,'first');
	%else
	%	trajectory_brain_idx = find(trajectory_areas > 1,1,'last');
	%end
	vecLocationBrainIntersection = ...
		[trajectory_xcoords(trajectory_brain_idx),trajectory_ycoords(trajectory_brain_idx),trajectory_zcoords(trajectory_brain_idx)]';
end