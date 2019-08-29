function matImageRGB = buildGratingTexture(sGratingObject,matMapDegsXY)
	%buildGratingTexture Builds stimulus using retinal-degree map
	%   syntax: matImage = buildGratingTexture(sGratingObject,matMapDegsXY)
	%
	%grating object:
	%	sGratingObject = struct;
	%	sGratingObject.ptrWindow = ptrWindow;
	%	sGratingObject.StimType = sStimObject.StimType;
	%	sGratingObject.ScreenPixX = intScreenWidth_pix;
	%	sGratingObject.ScreenPixY = intScreenHeight_pix;
	%	sGratingObject.StimPosX_deg = sStimObject.StimPosX_deg;
	%	sGratingObject.StimPosY_deg = sStimObject.StimPosY_deg;
	%	sGratingObject.StimulusSize_deg = sStimObject.StimulusSize_deg;
	%	sGratingObject.SoftEdge_deg = sStimObject.SoftEdge_deg;
	%	sGratingObject.Background = sStimObject.Background;
	%	sGratingObject.Contrast = sStimObject.Contrast;
	%	sGratingObject.Luminance = sStimObject.Luminance;
	%	sGratingObject.Orientation = sStimObject.Orientation;
	%	sGratingObject.DegsPerSpatCycle = 1/sStimObject.SpatialFrequency;
	%	
	%	Version History:
	%	2019-01-25	Created by Jorrit Montijn
	
	%% extract grating variables
	ptrWindow =	sGratingObject.ptrWindow;
	strStimType = sGratingObject.StimType;
	intCornerTrigger = sGratingObject.CornerTrigger;
	dblCornerSize =  sGratingObject.CornerSize;
	intScreenWidth_pix = sGratingObject.ScreenPixX;
	intScreenHeight_pix = sGratingObject.ScreenPixY;
	dblDegShiftX = sGratingObject.StimPosX_deg;
	dblDegShiftY = sGratingObject.StimPosY_deg;
	dblStimSizeDeg = sGratingObject.StimulusSize_deg;
	dblSoftEdgeDeg = sGratingObject.SoftEdge_deg;
	dblBackground = sGratingObject.Background;
	dblContrast = sGratingObject.Contrast;
	dblLuminance = sGratingObject.Luminance;
	dblOrientation = sGratingObject.Orientation;
	dblDegsPerSpatCycle = sGratingObject.DegsPerSpatCycle;
	dblPhase01 = sGratingObject.Phase01;
	intUseGPU = sGratingObject.UseGPU;
	intAntiAlias = sGratingObject.AntiAlias;
	
	%% check whether gpu computing is requested
	if intUseGPU > 0
		objDevice = gpuDevice();
		if objDevice.Index ~= intUseGPU
			fprintf('GPU processing on device %d requested\n',intUseGPU);
			objDevice = gpuDevice(intUseGPU);
			fprintf('\b; Device "%s" selected; Compute capability is %s\n',objDevice.Name,objDevice.ComputeCapability);
		end
		if ~existsOnGPU(matMapDegsXY)
			matMapDegsXY = gpuArray(matMapDegsXY);
		end
	elseif strcmp(class(matMapDegsXY),'gpuArray')
		warning([mfilename ':InconsistentInputGPU'],'GPU processing not requested, but input is GPU array! Gathering array to RAM');
		matMapDegsXY = gather(matMapDegsXY);
	end
	
	%% supersample for grating construction, then subsample for anti-alias	
	%get maps
	matMapX_deg = matMapDegsXY(:,:,1);
	matMapY_deg = matMapDegsXY(:,:,2);
	[intSizeY,intSizeX] = size(matMapX_deg);
	
	%rotate matrix
	dblOriRad = deg2rad(-dblOrientation);
	matRotation = [cos(dblOriRad) sin(dblOriRad); -sin(dblOriRad) cos(dblOriRad)]; 
	matMapRotXY_deg = [matMapX_deg(:) matMapY_deg(:)]*matRotation;
	matMapRotX_deg = reshape(matMapRotXY_deg(:,1),size(matMapX_deg));
	%matMapRotY_deg = reshape(matMapRotXY_deg(:,2),size(matMapY_deg)); %unused
	
	%super-sample
	if intAntiAlias > 0
		matMapXSuperSample2_deg = interp2(matMapRotX_deg,intAntiAlias);
	else
		matMapXSuperSample2_deg = matMapRotX_deg;
	end
	%matMapYSuperSample2_deg = interp2(matMapRotY_deg); %unused
	
	if strcmpi(strStimType,'SquareGrating')
		%build the square-wave grating
		matMod = mod(matMapXSuperSample2_deg-dblDegsPerSpatCycle*dblPhase01,dblDegsPerSpatCycle);  %every pixPerCycle pixels the grid flips back to 0 with an offset of phaseOffset
		matGratSuperSample2 = (matMod >= dblDegsPerSpatCycle/2)*(dblContrast/100); %create logical 1s and 0s to build the black/white grating
	elseif strcmpi(strStimType,'SineGrating')
		%build the sine-wave grating
		matCycles = (matMapXSuperSample2_deg-dblDegsPerSpatCycle*dblPhase01)/dblDegsPerSpatCycle;
		matWave = sin(matCycles*2*pi)/2+0.5;  %every pixPerCycle pixels the grid flips back to 0 with an offset of phaseOffset
		matGratSuperSample2 = matWave*(dblContrast/100); %create logical 1s and 0s to build the black/white grating
	else
		error([mfilename ':StimTypeUnknown'],sprintf('Stimulus type "%s" not recognized',strStimType));
	end
	
	%resize from super-sample
	if intAntiAlias
		if intUseGPU
			strMethod = 'bicubic';
		else
			strMethod = 'bilinear';
		end
		matGrat = imresize(matGratSuperSample2,size(matMapRotX_deg),strMethod);
	else
		matGrat = matGratSuperSample2;
	end
	
	%shift window
	matWindowMapDegsXY(:,:,1) = matMapX_deg + dblDegShiftX;
	matWindowMapDegsXY(:,:,2) = matMapY_deg - dblDegShiftY;
	
	%build the circular ramp using another function and also create an inverse mask
	matRampGrid = buildCircularCosineRamp(matWindowMapDegsXY,dblStimSizeDeg,dblSoftEdgeDeg);
	matRampGridInverse = abs(matRampGrid - 1);
	matStimPart = (matGrat .* matRampGrid); %multiply the ramped mask with the stimulus
	matBackgroundPart = dblBackground .* matRampGridInverse; %and multiple the inverse of that mask with the background
	matStim = (matStimPart + matBackgroundPart)*(dblLuminance/100); %add them together and we're done!
	matStim = round(matStim*255); %change to PTB-range
	
	%% extract screen pixels
	intOffsetX = 1+(intSizeX-intScreenWidth_pix)/2;
	intOffsetY = 1+(intSizeY-intScreenHeight_pix)/2;
	vecSelectRect = [intOffsetX intOffsetY (intScreenWidth_pix)+intOffsetX-1 (intScreenHeight_pix)+intOffsetY-1];
	matImageRGB = uint8(matStim(vecSelectRect(2):vecSelectRect(4),vecSelectRect(1):vecSelectRect(3)));
	matImageRGB = repmat(matImageRGB,[1 1 3]);
	
	%% add small set of pixels to corner of stimulus
	if intCornerTrigger > 0
		%calc size
		intCornerPix = floor(dblCornerSize*intScreenWidth_pix);
		if intCornerTrigger == 1 %upper left
			matImageRGB(1:intCornerPix,1:intCornerPix,:) = 255;
		elseif intCornerTrigger == 2 %upper right
			matImageRGB(1:intCornerPix,(end-intCornerPix+1):end,:) = 255;
		elseif intCornerTrigger == 3 %lower left
			matImageRGB((end-intCornerPix+1):end,1:intCornerPix,:) = 255;
		elseif intCornerTrigger == 4 %lower right
			matImageRGB((end-intCornerPix+1):end,(end-intCornerPix+1):end,:) = 255;
		end
	end
	
	%% display on screen while building?
	intShowOnScreen = 0;
	if intShowOnScreen == 1
		%display
		imshow(matImageRGB);drawnow;
	elseif intShowOnScreen == 2
		%% display on screen
		ptrTex = Screen('MakeTexture', ptrWindow, gather(matImageRGB));
		Screen('DrawTexture',ptrWindow,ptrTex);
		Screen('Flip',ptrWindow);
		pause(0.01);
		matImageRGB = Screen('GetImage', ptrWindow);
		Screen('Close',ptrTex);
	end
end