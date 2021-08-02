function [probe_vector,trajectory_brain_intersect,probe_ref_vector] = PH_Points2vec(probe_vector_ccf,av)
	%assume the probe is pointed downward
	if size(probe_vector_ccf,2)>3,probe_vector_ccf=probe_vector_ccf';end
	[dummy,vecReorder]=sort(probe_vector_ccf(:,2),'ascend');
	probe_vector_ccf = probe_vector_ccf(vecReorder,:);
	
	%get probe vector from points
	r0 = mean(probe_vector_ccf,1);
	xyz = bsxfun(@minus,probe_vector_ccf,r0);
	[~,~,V] = svd(xyz,0);
	histology_probe_direction = V(:,1);
	
	probe_eval_points = [-1000,1000];
	probe_line_endpoints = bsxfun(@plus,bsxfun(@times,probe_eval_points',histology_probe_direction'),r0);
	if probe_line_endpoints(1,2) > probe_line_endpoints(2,2)
		probe_line_endpoints = probe_line_endpoints([2 1],:);
	end
	
	% Place the probe on the histology best-fit axis
	probe_ref_top = probe_line_endpoints(1,[1,3,2]);
	probe_ref_bottom = probe_line_endpoints(2,[1,3,2]);
	probe_ref_vector = [probe_ref_top;probe_ref_bottom]';
	
	%get intersection
	trajectory_brain_intersect = PH_GetBrainIntersection(probe_ref_vector,av)';
	
	%get angle
	[theta,phi] = cart2sph(diff(probe_ref_vector(1,:)),diff(probe_ref_vector(2,:)),diff(probe_ref_vector(3,:)));
	
	r = 384;
	[dx,dy,dz] = sph2cart(theta,phi,r);
	probe_vector = [trajectory_brain_intersect;trajectory_brain_intersect + [dx,dy,dz]]';
end
	