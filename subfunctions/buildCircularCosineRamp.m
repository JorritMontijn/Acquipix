function matCircMask = buildCircularCosineRamp(matMapDegsXY,dblWindowDiameterDegs,dblRampWidthDegs)
	%buildCircularCosineRamp outputs a mask with 1s at center and a circular
	%cosine ramp going from 1 to 0 with the specified sizes
	%   matCircMask = buildCircularCosineRamp(matMapDegsXY,dblWindowDiameterDegs,dblRampWidthDegs)
	%		windowDiameter specifies the size of the inner non-ramped part;
	%		the ramp starts outside this circle extends to windowDiameter/2
	%		+ rampWidth to either side
	%
	%	Version History:
	%	2012-03-27	Created by Jorrit Montijn
	%	2019-01-25	Fork for degree-based computation [by JM]
	
	%get grid
	matGridX = matMapDegsXY(:,:,1); %center x to 0
	matGridY = matMapDegsXY(:,:,2); %center y to 0
	matGridDist = sqrt(matGridX.^2 + matGridY.^2); %calculate distance to center

	matMaskInnerCircle = abs(matGridDist) < dblWindowDiameterDegs/2; %mask for inner circle (stimulus)
	matMaskOuterCircle = abs(matGridDist) > (dblWindowDiameterDegs/2 + dblRampWidthDegs); %mask for outer circle (background)

	%in-between innerCircle and outerCircle is the ramp:
	matMaskRampAnnulus = matGridDist - dblWindowDiameterDegs/2; %set the value in the grid for the start of the ramp at 0
	matRampNormToWavelengthGrid = (matMaskRampAnnulus / dblRampWidthDegs) * pi; %transform the grid so that the end of the ramp has value pi
	
	matCosGrid = (cos(matRampNormToWavelengthGrid) + 1)/2; %take the cosine of the grid

	matRampBand = (~matMaskInnerCircle & ~matMaskOuterCircle); %calculate band-shaped mask for the ramp
	matCircMask = matCosGrid.*matRampBand; %multiply the mask with the cosine grid

	matCircMask = double(matMaskInnerCircle) + matCircMask; %add the innerCircle (1s at center) to the ramp (going from 1 to 0) and we're done!
end