function matTexture = buildStimulusTexture(sStimObject,sStimParams)
	%loadStimulusTexture Creates stimulus texture according to object specs
	%	matTexture = loadStimulusTexture(sStimObject)
	
	%% extract screen details
	ptrWindow = sStimParams.ptrWindow;
	intScreenWidth_pix = sStimParams.intScreenWidth_pix;
	intScreenHeight_pix = sStimParams.intScreenHeight_pix;
	
	%% get mapping of retinal degrees to screen
	matMapDegsXY = buildRetinalSpaceMap(sStimParams);
	
	%% build stimulus
	if (strcmp(sStimObject.StimType,'SquareGrating') || strcmp(sStimObject.StimType,'SineGrating'))
		%time-based variables
		dblTemporalFrequency = sStimObject.TemporalFrequency;
		intFramesPerCycle = ceil(sStimObject.FrameRate/dblTemporalFrequency);
		
		%build grating object
		sGratingObject = struct;
		sGratingObject.ptrWindow = ptrWindow;
		sGratingObject.StimType = sStimObject.StimType;
		sGratingObject.CornerTrigger = sStimObject.CornerTrigger;
		sGratingObject.CornerSize = sStimObject.CornerSize;
		sGratingObject.ScreenPixX = intScreenWidth_pix;
		sGratingObject.ScreenPixY = intScreenHeight_pix;
		sGratingObject.StimPosX_deg = sStimObject.StimPosX_deg;
		sGratingObject.StimPosY_deg = sStimObject.StimPosY_deg;
		sGratingObject.StimulusSize_deg = sStimObject.StimulusSize_deg;
		sGratingObject.SoftEdge_deg = sStimObject.SoftEdge_deg;
		sGratingObject.Background = sStimObject.Background;
		sGratingObject.Contrast = sStimObject.Contrast;
		sGratingObject.Luminance = sStimObject.Luminance;
		sGratingObject.Orientation = sStimObject.Orientation;
		sGratingObject.DegsPerSpatCycle = 1/sStimObject.SpatialFrequency;
		sGratingObject.AntiAlias = sStimObject.AntiAlias;
		sGratingObject.UseGPU = sStimParams.intUseGPU;
		
		%% run
		matTexture = zeros(intScreenHeight_pix,intScreenWidth_pix,intFramesPerCycle,'uint8');
		for intFrame=1:intFramesPerCycle
			fprintf('Building frame %d/%d\n',intFrame,intFramesPerCycle);
			pause(0.001);
			sGratingObject.Phase01 = mod(intFrame/intFramesPerCycle,1);
			matSingleFrame = buildGratingTexture(sGratingObject,matMapDegsXY);
			matTexture(:,:,intFrame)=gather(matSingleFrame(:,:,1));
		end
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		Screen('Flip', ptrWindow);
		
	elseif strcmp(sStimObject.StimType,'SineGrating')
		error([mfilename ':TypeUnsupported'],sprintf('Stimulus type "%s" has not been programmed yet...',sStimObject.StimType));
	elseif strcmp(sStimObject.StimType,'Line')
		error([mfilename ':TypeUnsupported'],sprintf('Stimulus type "%s" has not been programmed yet...',sStimObject.StimType));
	elseif strcmp(sStimObject.StimType,'NatMov')
		error([mfilename ':TypeUnsupported'],sprintf('Stimulus type "%s" has not been programmed yet...',sStimObject.StimType));
	else
		error([mfilename ':TypeUnsupported'],sprintf('Stimulus type "%s" is not supported',sStimObject.StimType));
	end
end