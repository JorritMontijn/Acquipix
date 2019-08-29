function rampGrid = buildCircularCosineRampPix(imSize,windowDiameter,rampWidth)
	%buildCircularCosineRamp outputs a mask with 1s at center and a circular
	%cosine ramp going from 1 to 0 with the specified sizes
	%   syntax: rampGrid = buildCircularCosineRamp(imSize,windowDiameter,rampWidth)
	%		windowDiameter specifies the size of the inner non-ramped part;
	%		the ramp starts outside this circle extends to windowDiameter/2
	%		+ rampWidth to either side
	%
	%	Version History:
	%	2012-03-27	Created by Jorrit Montijn
	
	
	%some default values to test the script
	%imSize = 200;
	%windowDiameter = 73;
	%rampWidth = 17;

	%create grid
	[xGrid,yGrid] = meshgrid(1:imSize);
	xGrid = (xGrid -imSize/2); %center x to 0
	yGrid = (yGrid -imSize/2); %center y to 0
	distGrid = sqrt(xGrid.^2 + yGrid.^2); %calculate distance to center

	innerCircle = abs(distGrid) < windowDiameter/2; %mask for inner circle (stimulus)
	outerCircle = abs(distGrid) > (windowDiameter/2 + rampWidth); %mask for outer circle (background)

	%in-between innerCircle and outerCircle is the ramp:
	offsetDistGrid = distGrid - windowDiameter/2; %set the value in the grid for the start of the ramp at 0
	distNormToWavelengthGrid = (offsetDistGrid / rampWidth) * pi; %transform the grid so that the end of the ramp has value pi
	
	cosGrid = (cos(distNormToWavelengthGrid) + 1)/2; %take the cosine of the grid

	rampBand = (~innerCircle & ~outerCircle); %calculate band-shaped mask for the ramp
	rampGrid = cosGrid.*rampBand; %multiply the mask with the cosine grid

	rampGrid = double(innerCircle) + rampGrid; %add the innerCircle (1s at center) to the ramp (going from 1 to 0) and we're done!
end