function matImage = buildGratingTexturePix(sGratingObject)
	%buildGrating outputs greyscale grating patch
	%   syntax: matStim = buildGratingTexture(sGratingObject)
	%		- Creates a grating enclosed by circular neutral-grey window
	%		  with cosine ramps around the border. For more information on
	%		  the circular window, see buildCircularCosineRamp.m
	%
	%	output: 
	%		- matStim; matrix, range 0-255
	%
	%	inputs:
	%		- SpatFreq; double, spatial frequency (cycles per degree)
	%		- StimSizeRetDeg; double, size of stimulus in retinal degree
	%		- ScrPixWidthHeight; 2-element (integer) vector, first element
	%			is screen width; second is height in pixels
	%		- ScrDegWidthHeight; 2-element (double) vector, first element
	%			is screen width; second is height in retinal degrees
	%		- phaseOffset; double, phase offset in range 0-2pi
	%
	%	Version History:
	%	2012-03-27	Created by Jorrit Montijn
	%	2019-01-24	Updated [by JM]
	
	
	%extract grating variables
	ptrWindow =	sGratingObject.ptrWindow;
	intScreenWidth_pix = sGratingObject.ScreenPixX;
	intScreenHeight_pix = sGratingObject.ScreenPixY;
	dblPixShiftX = sGratingObject.PixPosX - intScreenWidth_pix/2;
	dblPixShiftY = sGratingObject.PixPosY - intScreenHeight_pix/2;
	dblStimSizePix = sGratingObject.SizePix;
	dblSoftEdgePix = sGratingObject.EdgePix;
	dblBackground = sGratingObject.Background;
	dblContrast = sGratingObject.Contrast;
	dblLuminance = sGratingObject.Luminance;
	dblOrientation = sGratingObject.Orientation;
	dblPixPerSpatCycle = sGratingObject.PixPerSpatCycle;
	dblPhase01 = sGratingObject.Phase01;
	
	%get size
	intSizeIm = 2*min(intScreenHeight_pix,intScreenWidth_pix); %if this is not large enough, the stimulus would be off-screen anyway
	%build grid
	[matGrid]=meshgrid(1:intSizeIm); %create a grid with the size of the required image
	
	%build the grating
	matMod = mod(matGrid-1-dblPixPerSpatCycle*dblPhase01,dblPixPerSpatCycle);  %every pixPerCycle pixels the grid flips back to 0 with an offset of phaseOffset
	matGrat = (matMod >= dblPixPerSpatCycle/2)*(dblContrast/100); %create logical 1s and 0s to build the black/white grating
	matGrat = matGrat + dblBackground*(1 - dblContrast/100);
	
	%build the circular ramp using another function and also create an inverse mask
	matRampGrid = buildCircularCosineRampPix(intSizeIm,dblStimSizePix,dblSoftEdgePix);
	matRampGridInverse = abs(matRampGrid - 1);
	matStimPart = (matGrat .* matRampGrid); %multiply the ramped mask with the stimulus
	matBackgroundPart = dblBackground .* matRampGridInverse; %and multiple the inverse of that mask with the background
	matStim = (matStimPart + matBackgroundPart)*(dblLuminance/100); %add them together and we're done!
	matStim = round(matStim*255); %change to PTB-range
	
	%shift position
	intTexSizeX = size(matStim,2);
	intTexSizeY = size(matStim,1);
	intStartX = round(dblPixShiftX + (intScreenWidth_pix-intTexSizeX)/2);
	intStopX = intStartX + intTexSizeX;
	intStartY = round(-dblPixShiftY + (intScreenHeight_pix-intTexSizeY)/2);
	intStopY = intStartY + intTexSizeY;
	vecTargetRect = [intStartX intStartY intStopX intStopY];
	
	%display on screen
	ptrTex = Screen('MakeTexture', ptrWindow, matStim);
	Screen('DrawTexture',ptrWindow,ptrTex,[],vecTargetRect,360-dblOrientation); %invert to align with unit circle (or invert matMod)
	Screen('Flip',ptrWindow);
	pause(0.01);
	matImage = Screen('GetImage', ptrWindow);
	Screen('Close',ptrTex);
end