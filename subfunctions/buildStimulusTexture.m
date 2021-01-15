function [vecSceneFrames,matTexture] = buildStimulusTexture(sStimObject,sStimParams)
	%loadStimulusTexture Creates stimulus texture according to object specs
	%	[vecSceneFrames,matTexture] = loadStimulusTexture(sStimObject)
	
	%% extract screen details
	ptrWindow = sStimParams.ptrWindow;
	intScreenWidth_pix = sStimParams.intScreenWidth_pix;
	intScreenHeight_pix = sStimParams.intScreenHeight_pix;
	
	%% get mapping of retinal degrees to screen
	matMapDegsXYD = buildRetinalSpaceMap(sStimParams);
	
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
		hTic = tic;
		vecSceneFrames = 1:intFramesPerCycle;
		matTexture = zeros(intScreenHeight_pix,intScreenWidth_pix,intFramesPerCycle,'uint8');
		for intFrame=1:intFramesPerCycle
			if toc(hTic) > 5
				hTic = tic;
				fprintf('Building frame %d/%d\n',intFrame,intFramesPerCycle);
				pause(0.001);
			end
			sGratingObject.Phase01 = mod(intFrame/intFramesPerCycle,1);
			matSingleFrame = buildGratingTexture(sGratingObject,matMapDegsXYD);
			matTexture(:,:,intFrame)=gather(matSingleFrame(:,:,1));
		end
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		Screen('Flip', ptrWindow);
	elseif strcmp(sStimObject.StimType,'NaturalMovie')
		%% set natural movies
		cellScenes = cell(1,1);
		cellScenes(1) = {'Earthflight (Winged Planet) - Condor Flight School (Narrated by David Tennant).avi'};
		
		%get path
		strThisPath = mfilename('fullpath');
		strThisPath = strThisPath(1:(end-numel(mfilename)));
		strThisPath = strrep(strThisPath,['subfunctions' filesep],'');
		strSceneSubDir = 'Scenes';
		strSceneDir = strcat(strThisPath,strSceneSubDir); %where are the stimulus textures saved?
		if ~exist(strSceneDir,'dir')
			sME = struct;
			sME.identifier = [mfilename ':SceneDirMissing'];
			sME.message = sprintf('Path to natural scenes not found: %s ',strSceneDir);
			error(sME);
		end
		
		%% prep
		%extract movie
		strFile = cellScenes{sStimObject.Scene};
		
		%load movie
		strSceneFile = strcat(strSceneDir,filesep,strFile);
		objVideo = VideoReader(strSceneFile);
		intFrames = objVideo.NumberOfFrames;
		intHeight = objVideo.Height;
		intWidth = objVideo.Width;
		dblDuration = objVideo.Duration;
		%dblFrameRate = objVideo.FrameRate;
		dblFrameRate = objVideo.FrameRate;
		fprintf('Loading %s\n   [%dx%d pixels; %d frames (%.3fHz), total duration %.3fs]\n',strFile,intWidth,intHeight,intFrames,dblFrameRate,dblDuration);
	
		%build object
		sSceneObject = struct;
		sSceneObject.ptrWindow = ptrWindow;
		sSceneObject.StimType = sStimObject.StimType;
		sSceneObject.Video = objVideo;
		sSceneObject.CornerTrigger = sStimObject.CornerTrigger;
		sSceneObject.CornerSize = sStimObject.CornerSize;
		sSceneObject.ScreenPixX = intScreenWidth_pix;
		sSceneObject.ScreenPixY = intScreenHeight_pix;
		sSceneObject.ScreenHeight_cm = sStimParams.dblScreenHeight_cm;
		sSceneObject.ScreenWidth_cm = sStimParams.dblScreenWidth_cm;
		sSceneObject.ScreenDistance_cm = sStimParams.dblScreenHeight_cm;
		
		sSceneObject.DispRate = sStimObject.DispRate;
		sSceneObject.SceneFrames = intFrames;
		sSceneObject.ScreenFrameRate = sStimObject.FrameRate;
		
		if strcmpi(sSceneObject.DispRate,'Screen')
			sSceneObject.SceneFrameRate = sSceneObject.ScreenFrameRate;
		elseif strcmpi(sSceneObject.DispRate,'Source')
			sSceneObject.SceneFrameRate = dblFrameRate;
		else
			error([mfilename ':DispRateError'],'DispRate can only be "Screen" or "Source"');
		end
		sSceneObject.ScreenFrames = round(sSceneObject.SceneFrames*(sSceneObject.ScreenFrameRate/sSceneObject.SceneFrameRate));
		
		sSceneObject.ScenePixX = intWidth;
		sSceneObject.ScenePixY = intHeight;
		sSceneObject.StimPosX_deg = sStimObject.StimPosX_deg;
		sSceneObject.StimPosY_deg = sStimObject.StimPosY_deg;
		sSceneObject.StimulusSize_deg = sStimObject.StimulusSize_deg;
		sSceneObject.SceneSize_deg = sStimObject.SceneSize_deg;
		sSceneObject.SoftEdge_deg = sStimObject.SoftEdge_deg;
		sSceneObject.Background = sStimObject.Background;
		sSceneObject.Contrast = sStimObject.Contrast;
		sSceneObject.Luminance = sStimObject.Luminance;
		sSceneObject.AntiAlias = sStimObject.AntiAlias;
		sSceneObject.UseGPU = sStimParams.intUseGPU;
		
		%% build textures
		[vecSceneFrames,matTexture] = buildSceneTexture(sSceneObject,matMapDegsXYD);
		Screen('FillRect',ptrWindow, sStimParams.intBackground);
		Screen('Flip', ptrWindow);
		
	elseif strcmp(sStimObject.StimType,'SineGrating')
		error([mfilename ':TypeUnsupported'],sprintf('Stimulus type "%s" has not been programmed yet...',sStimObject.StimType));
	elseif strcmp(sStimObject.StimType,'Line')
		error([mfilename ':TypeUnsupported'],sprintf('Stimulus type "%s" has not been programmed yet...',sStimObject.StimType));
	else
		error([mfilename ':TypeUnsupported'],sprintf('Stimulus type "%s" is not supported',sStimObject.StimType));
	end
end