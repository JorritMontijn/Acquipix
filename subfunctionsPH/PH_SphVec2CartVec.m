function matCartVector = PH_SphVec2CartVec(vecSphereVector)
	%PH_SphVec2CartVec Transforms 1-point spherical vector to 2-point cartesian vector
	%   matCartVector = PH_SphVec2CartVec(vecSphereVector)
	%
	%vecSphereVector = [x1 y1 z1 deg-ML deg-AP length]
	%matCartVector = [x1 y1 z1; x2 y2 z2]
	
	%get dx,dy,dz
	[dx,dy,dz] = sph2cart(deg2rad(vecSphereVector(5)),deg2rad(vecSphereVector(4)+90),vecSphereVector(6));
	
	%add dx,dy,dz
	matCartVector = [vecSphereVector(1:3);(vecSphereVector(1:3) + [dx,dy,dz])];
end

