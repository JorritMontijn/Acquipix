function [vecSceneFrames,matMovieRGB] = buildSceneTexture(sSceneObject,matMapDegsXYD)
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
	ptrWindow =	sSceneObject.ptrWindow;
	objVideo = sSceneObject.Video;
	strStimType = sSceneObject.StimType;
	intCornerTrigger = sSceneObject.CornerTrigger;
	dblCornerSize =  sSceneObject.CornerSize;
	intScreenWidth_pix = sSceneObject.ScreenPixX;
	intScreenHeight_pix = sSceneObject.ScreenPixY;
	dblScreenHeight_cm = sSceneObject.ScreenHeight_cm;
	dblScreenDistance_cm = sSceneObject.ScreenDistance_cm;
	
	intScreenFrames = sSceneObject.ScreenFrames;
	dblScreenFrameRate = sSceneObject.ScreenFrameRate;
	intScenePixX = sSceneObject.ScenePixX;
	intScenePixY = sSceneObject.ScenePixY;
	intSceneFrames = sSceneObject.SceneFrames;
	dblSceneFrameRate = sSceneObject.SceneFrameRate;
	dblSceneSizeDeg = sSceneObject.SceneSize_deg;
	
	dblDegShiftX = sSceneObject.StimPosX_deg;
	dblDegShiftY = sSceneObject.StimPosY_deg;
	dblStimSizeDeg = sSceneObject.StimulusSize_deg;
	dblSoftEdgeDeg = sSceneObject.SoftEdge_deg;
	dblBackground = sSceneObject.Background;
	dblContrast = sSceneObject.Contrast;
	dblLuminance = sSceneObject.Luminance;
	intUseGPU = sSceneObject.UseGPU;
	intAntiAlias = sSceneObject.AntiAlias;
	
	%% check whether gpu computing is requested
	if intUseGPU > 0
		objDevice = gpuDevice();
		if objDevice.Index ~= intUseGPU
			fprintf('GPU processing on device %d requested\n',intUseGPU);
			objDevice = gpuDevice(intUseGPU);
			fprintf('\b; Device "%s" selected; Compute capability is %s\n',objDevice.Name,objDevice.ComputeCapability);
		end
		if ~existsOnGPU(matMapDegsXYD)
			matMapDegsXYD = gpuArray(matMapDegsXYD);
		end
	elseif strcmp(class(matMapDegsXYD),'gpuArray')
		warning([mfilename ':InconsistentInputGPU'],'GPU processing not requested, but input is GPU array! Gathering array to RAM');
		matMapDegsXYD = gather(matMapDegsXYD);
	end
	
	%% use flat map
	%get approximate flattened cm to deg
	%dblScreenHeight_deg = atand((dblScreenHeight_cm/2)/dblScreenDistance_cm)*2;
	%dblDegPerPix = dblScreenHeight_deg/intScreenHeight_pix;
	dblDegPerPix = (dblSceneSizeDeg / intScenePixY);
	
	%rescale scene maps
	[matSceneX_pix,matSceneY_pix] = meshgrid((1:intScenePixX)-intScenePixX/2,(1:intScenePixY)-intScenePixY/2);
	matSceneX_deg = matSceneX_pix*dblDegPerPix;
	matSceneY_deg = matSceneY_pix*dblDegPerPix;
	
	%get retinal screen maps
	matMapX_deg = matMapDegsXYD(:,:,1) - dblDegShiftX;
	matMapY_deg = matMapDegsXYD(:,:,2) - dblDegShiftY;
	[intSizeY,intSizeX] = size(matMapX_deg);
	vecOrigSize = size(matMapX_deg);
	
	% supersample?
	if intAntiAlias > 0
		matMapX_deg = interp2(matMapX_deg,intAntiAlias);
		matMapY_deg = interp2(matMapY_deg,intAntiAlias);
	end
	[intNewSizeY,intNewSizeX] = size(matMapX_deg);
	
	%% prep variables & move to GPU
	dblContFact = dblContrast/100;
	dblMovBG = double(dblBackground*intmax('uint8'));
	if intUseGPU > 0
		dblContFact = gpuArray(dblContFact);
		dblMovBG = gpuArray(dblMovBG);
		matSceneX_deg = gpuArray(matSceneX_deg);
		matSceneY_deg = gpuArray(matSceneY_deg);
	end
	
	%% build frames
	vecSceneFrames = round(linspace(1,intSceneFrames,intScreenFrames));
	matMovieRGB = zeros(intScreenHeight_pix,intScreenWidth_pix,3,intSceneFrames,'uint8');
	%run
	hTic = tic;
	for intSceneFrame=1:intSceneFrames
		%% get original image
		if intUseGPU > 0
			matSceneFrame = gpuArray(double(read(objVideo, intSceneFrame)));
		else
			matSceneFrame = double(read(objVideo, intSceneFrame));
		end
		matSceneFrame = ((matSceneFrame - dblMovBG) * dblContFact) + dblMovBG;
		matSceneFrame = matSceneFrame(end:-1:1,:,:);
		
		%% build new image
		if intUseGPU > 0
			matWarpedIm = zeros(intNewSizeY,intNewSizeX,3,'gpuArray');
		else
			matWarpedIm = zeros(intNewSizeY,intNewSizeX,3);
		end
		
		for intColor=1:3
			matWarpedIm(:,:,intColor) = interp2(matSceneX_deg,matSceneY_deg,matSceneFrame(:,:,intColor),matMapX_deg,matMapY_deg,'linear');
		end
		matWarpedIm(isnan(matWarpedIm)) = 0;
		
		%% add window
		%for window
		matWindowMapDegsXY(:,:,1) = matMapX_deg;
		matWindowMapDegsXY(:,:,2) = matMapY_deg;
		
		%build the circular ramp using another function and also create an inverse mask
		if dblStimSizeDeg > 0
			matRampGrid = buildCircularCosineRamp(matWindowMapDegsXY,dblStimSizeDeg,dblSoftEdgeDeg);
			matRampGridInverse = abs(matRampGrid - 1);
			matStimPart = (matWarpedIm .* matRampGrid); %multiply the ramped mask with the stimulus
			matBackgroundPart = dblMovBG .* matRampGridInverse; %and multiple the inverse of that mask with the background
			matStim = (matStimPart + matBackgroundPart)*(dblLuminance/100); %add them together and we're done!
		else
			matStim = matWarpedIm*(dblLuminance/100); %add them together and we're done!
		end
		
		%% subsample?
		if intAntiAlias
			if intUseGPU
				strMethod = 'bicubic';
			else
				strMethod = 'bilinear';
			end
			matScene = imresize(matStim,vecOrigSize,strMethod);
		else
			matScene = matStim;
		end
		
		%% extract screen pixels
		intOffsetX = 1+(intSizeX-intScreenWidth_pix)/2;
		intOffsetY = 1+(intSizeY-intScreenHeight_pix)/2;
		vecSelectRect = [intOffsetX intOffsetY (intScreenWidth_pix)+intOffsetX-1 (intScreenHeight_pix)+intOffsetY-1];
		matImageRGB = uint8(gather(matScene(vecSelectRect(2):vecSelectRect(4),vecSelectRect(1):vecSelectRect(3),:)));
		
		%% add small set of pixels to corner of stimulus
		if intCornerTrigger > 0 && intSceneFrame < (intSceneFrames/2)
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
			ptrTex = Screen('MakeTexture', ptrWindow, matImageRGB);
			Screen('DrawTexture',ptrWindow,ptrTex);
			Screen('Flip',ptrWindow);
			pause(0.01);
			matImageRGB = Screen('GetImage', ptrWindow);
			Screen('Close',ptrTex);
		end
		
		%% add to movie matrix
		matMovieRGB(:,:,:,intSceneFrame) = matImageRGB;
		
		%% msg
		if toc(hTic) > 5
			hTic = tic;
			fprintf('Finished frame %d/%d [%s]...\n',intSceneFrame,intSceneFrames,getTime);
		end
	end
end