function matMapDegsXYD = buildRetinalSpaceMap(sStimParams)
	%buildRetinalSpaceMap Outputs 3D map with X (deg), Y (deg) and distance
	%						(cm) of pixels on screen to the subject
	%
	%	matMapDegsXYD = buildRetinalSpaceMap(sStimParams)
	%
	%	Version History:
	%	2019-01-25	Created by Jorrit Montijn
	
	%check whether gpu computing is requested
	if sStimParams.intUseGPU > 0
		try
		objDevice = gpuDevice();
		if objDevice.Index ~= sStimParams.intUseGPU
			fprintf('GPU processing on device %d requested\n',sStimParams.intUseGPU);
			objDevice = gpuDevice(sStimParams.intUseGPU);
			fprintf('\b; Device "%s" selected; Compute capability is %s\n',objDevice.Name,objDevice.ComputeCapability);
		end
		catch
			fprintf('GPU processing failed...\n');
			sStimParams.intUseGPU = 0;
		end
	end
	
	if sStimParams.vecUseMask(1) == 1
		%% use spheroid-projection mask
		%extract required variables
		intScreenWidth_pix = sStimParams.intScreenWidth_pix;
		intScreenHeight_pix = sStimParams.intScreenHeight_pix;
		dblScreenWidth_cm = sStimParams.dblScreenWidth_cm;
		dblScreenHeight_cm = sStimParams.dblScreenHeight_cm;
		dblSubjectPosX_cm = sStimParams.dblSubjectPosX_cm;
		dblSubjectPosY_cm = sStimParams.dblSubjectPosY_cm;
		dblScreenDistance_cm = sStimParams.dblScreenDistance_cm;
		
		%get size of map
		intSizeMap = 2*min(intScreenHeight_pix,intScreenWidth_pix); %larger size to enable rotations
		
		%get locations in pixels
		vecX_pix = ((1:intSizeMap)-intSizeMap/2);
		vecY_pix = ((intSizeMap:-1:1)-intSizeMap/2); %invert y to make high values be up
		
		%transfer to GPU
		if sStimParams.intUseGPU > 0
			vecX_pix = gpuArray(vecX_pix);
			vecY_pix = gpuArray(vecY_pix);
		end
		
		%get locations in cm
		vecX_cm = (vecX_pix/intScreenWidth_pix)*dblScreenWidth_cm - dblSubjectPosX_cm;
		vecY_cm = (vecY_pix/intScreenHeight_pix)*dblScreenHeight_cm - dblSubjectPosY_cm;
		[matMapX_cm,matMapY_cm]=meshgrid(vecX_cm,vecY_cm);
		
		%transform to spherical coordinates and degrees
		[matAzimuth,matElevation,matDistance_cm] = cart2sph(matMapX_cm,dblScreenDistance_cm*ones(size(matMapX_cm)),matMapY_cm);
		matMapX_deg = rad2deg(matAzimuth-pi/2);
		matMapY_deg = rad2deg(matElevation);
		
		%build grid
		matMapDegsXYD = cat(3,matMapX_deg,matMapY_deg,matDistance_cm);
		
	elseif sStimParams.vecUseMask(1) == 0
		%% use flat map
		%extract required variables
		intScreenWidth_pix = sStimParams.intScreenWidth_pix;
		intScreenHeight_pix = sStimParams.intScreenHeight_pix;
		dblScreenWidth_deg = sStimParams.dblScreenWidth_deg;
		dblScreenHeight_deg = sStimParams.dblScreenHeight_deg;
		
		%get linear maps
		vecDegX = linspace(dblScreenWidth_deg/intScreenWidth_pix,dblScreenWidth_deg,intScreenWidth_pix);
		vecDegX = vecDegX-mean(vecDegX);
		vecDegY = linspace(dblScreenHeight_deg/intScreenHeight_pix,dblScreenHeight_deg,intScreenHeight_pix);
		vecDegY = vecDegY-mean(vecDegY);
		
		%get grids
		[matMapX_deg,matMapY_deg] = meshgrid(vecDegX,vecDegY);
		matDistance_cm = ones(size(matMapX_deg)); %placeholder
		
		%build grid
		matMapDegsXYD = cat(3,matMapX_deg,matMapY_deg,matDistance_cm);
		
	else
		%% unknown switch
		error([mfilename ':UnknownSwitch'],sprintf('Switch "%d" for UseMask is not recognized',sStimParams.vecUseMask(1)));
	end
end