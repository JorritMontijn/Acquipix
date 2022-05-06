function [vecSphereVector,vecLocBrainIntersect,matRefVector] = PH_Points2vec(sProbeCoords,sAtlas)
	
	%pre-allocate dummies
	vecSphereVector = [];
	vecLocBrainIntersect = [];
	matRefVector = [];
	
	%get probe length
	if isfield(sProbeCoords,'ProbeLength') && ~isempty(sProbeCoords.ProbeLength)
		dblProbeLength = sProbeCoords.ProbeLength;
	else
		dblProbeLength = 1000;
	end
	%assume the probe is pointed downward
	matHistoPoints = sProbeCoords.cellPoints{sProbeCoords.intProbeIdx};
	if size(matHistoPoints,2)>3,matHistoPoints=matHistoPoints';end
	[dummy,vecReorder]=sort(matHistoPoints(:,3),'descend');
	matHistoPoints = matHistoPoints(vecReorder,:);
	
	%get probe vector from points
	matRefVector = PH_GetRefVector(matHistoPoints);
	
	%get intersection
	vecLocBrainIntersect = PH_GetBrainIntersection(matRefVector,sAtlas.av);
	if isempty(vecLocBrainIntersect)
		vecProbeLoc = matRefVector(1,:);
	else
		vecProbeLoc = vecLocBrainIntersect(1:3);
	end
	
	%get angles
	vecD = diff(matRefVector);
	vecNormD = vecD./norm(vecD);
	[azimuth,elevation,r] = cart2sph(vecNormD(1),vecNormD(2),vecNormD(3));%ML, AP,depth (DV)
	
	%extract angles in degrees
	dblInverterML = double(matRefVector(2) < 0)*2-1;
	dblAngleAP = rad2deg(azimuth);
	dblAngleML = rad2deg(elevation);
	vecAngles = mod([dblAngleAP dblAngleML-90],360);
	
	%set correct probe tip & length
	vecSphereVector = [vecProbeLoc(:)'-(vecNormD*dblProbeLength) vecAngles dblProbeLength];
end
	