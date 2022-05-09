function vecSphereVector = PH_CartVec2SphVec(matCartVector)
	%PH_CartVec2SphVec Transforms 2-point cartesian vector to 1-point spherical vector
	%   vecSphereVector = PH_CartVec2SphVec(matCartVector)
	%
	%matCartVector = [x1 y1 z1; x2 y2 z2], where [x1 y1 z1] is probe tip
	%vecSphereVector = [x1 y1 z1 deg-ML deg-AP length]
	
	%get dx,dy,dz
	vecRefVector = matCartVector(2,:) - matCartVector(1,:);
	%calculate angle
	[azimuth,elevation,r] = cart2sph(vecRefVector(1),vecRefVector(2),vecRefVector(3));%ML, AP,depth (DV)
	
	%extract angles in degrees
	dblInverterML = double(vecRefVector(1) < 0)*2-1;
	dblAngleAP = mod(rad2deg(azimuth)-180,360);
	dblAngleML = 90-rad2deg(elevation);
	vecSphereVector = [matCartVector(1,:) dblAngleML dblAngleAP r];
end

