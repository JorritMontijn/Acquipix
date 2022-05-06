function vecSphereVector = PH_CartVec2SphVec(matCartVector)
	%PH_CartVec2SphVec Transforms 2-point cartesian vector to 1-point spherical vector
	%   vecSphereVector = PH_CartVec2SphVec(matCartVector)
	%
	%matCartVector = [x1 y1 z1; x2 y2 z2]
	%vecSphereVector = [x1 y1 z1 deg-AP deg-ML length]
	
	%get dx,dy,dz
	vecRefVector = matCartVector(1,:) - matCartVector(2,:);
	%calculate angle
	[azimuth,elevation,r] = cart2sph(vecRefVector(1),vecRefVector(2),vecRefVector(3));%ML, AP,depth (DV)
	
	%extract angles in degrees
	dblInverterML = double(vecRefVector(2) < 0)*2-1;
	dblAngleAP = rad2deg(azimuth);
	dblAngleML = rad2deg(elevation);
	vecAngles = mod([dblAngleAP dblAngleML-90],360);
	vecSphereVector = [matCartVector(1,:) vecAngles r];
end

