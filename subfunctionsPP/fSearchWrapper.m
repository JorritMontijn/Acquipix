function dblSE = fSearchWrapper(vecCoords)
	%UNTITLED3 Summary of this function goes here
	%   Detailed explanation goes here
	
	%get requested bregma coords
	global vecBregmaCoords;
	global matAV;
	
	%get location with new coords
	vecFullCoords = vecCoords;
	vecFullCoords(3:5) = vecBregmaCoords(3:5);
	vecRealLoc = getRealLoc(vecFullCoords,matAV);
	
	%calc difference
	dblSE = sum((vecRealLoc(1:2) - vecBregmaCoords(1:2)).^2);
end
