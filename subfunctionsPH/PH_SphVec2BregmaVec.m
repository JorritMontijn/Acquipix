function vecBregmaVector = PH_SphVec2BregmaVec(vecSphereVector,vecLocBrainIntersect,sAtlas)
	%PH_SphVec2BregmaVec Calculates  bregma-centered Paxinos coordinates of brain entry, probe depth
	%						in microns and ML and AP angles in degrees
	%   vecBregmaVector = PH_SphVec2BregmaVec(vecSphereVector,vecLocBrainIntersect,sAtlas)
	%
	%In Paxinos coordinates, coordinates relative to bregma (bregma - X) mean that -AP is posterior,
	%+AP is anterior, -DV is dorsal, +DV is ventral
	
	vecBregmaVector = vecSphereVector;
	%brain entry
	vecBregmaVector(1:3) = (sAtlas.Bregma - vecLocBrainIntersect(:)') .* sAtlas.VoxelSize;
	%ML angle
	if mod(vecSphereVector(4),360) > 180
		vecBregmaVector(4) = mod(vecSphereVector(4),360) - 360;
	end
	%AP angle
	if mod(vecSphereVector(5),360) > 180
		vecBregmaVector(5) = mod(vecSphereVector(5),360) - 360;
	end
	%depth
	vecD = vecLocBrainIntersect(:)' - vecSphereVector(1:3);
	[azimuth,elevation,dblDepth] = cart2sph(vecD(1),vecD(2),vecD(3));%ML, AP,depth (DV)
	vecBregmaVector(end) = dblDepth * sAtlas.VoxelSize(end); %will be wrong if voxels are not isometric
	
end

