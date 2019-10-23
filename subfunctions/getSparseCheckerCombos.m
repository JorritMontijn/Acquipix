function [sStimParams,sStimObject,matMapDegsXY_crop,intStimsForMinCoverage] = getSparseCheckerCombos(sStimParams,matMapDegsXY)
	%getSparseCheckerCombos Prepares sparse checker board stimuli
	%	 [sStimParams,sStimObject,matMapDegsXY,intStimsForMinCoverage] = getSparseCheckerCombos(sStimParams,matMapDegsXY)
	
	%% create variable if none supplied
	if ~exist('sStimParams','var');sStimParams=struct;end
	
	%% assign defaults
	cellFieldDefaults = ...
		{...
		%stimulus type
		'strStimType','SparseCheckers';...
		
		%subject parameters
		'dblSubjectPosX_cm',0;... % cm; relative to center of screen
		'dblSubjectPosY_cm',0;... % cm; relative to center of screen
		'dblScreenDistance_cm',16;... % cm; measured
		'vecUseMask',[1];... %[1] if mask to emulate retinal-space, [0] use screen-space
		
		%screen variables
		'intUseScreen',1;... %which screen to use
		'dblScreenWidth_cm',33;... % cm; measured [51]
		'dblScreenHeight_cm',25;... % cm; measured [29]
		'intScreenWidth_pix',nan;... % cm
		'intScreenHeight_pix',nan;... % cm
		
		%stimulus control variables
		'intCornerTrigger',0;... % integer switch; 0=none,1=upper left, 2=upper right, 3=lower left, 4=lower right
		'dblCornerSize',1/30;... % fraction of screen width
		'intAntiAlias',1;... % anti-alias? set to "0" to improve performance
		'intUseGPU',0;... % set to non-zero to specify which GPU to render stimuli
		'intUseParPool',0;... % set to non-zero to specify how many workers to use
		'dblCheckerSizeX_deg',5;... % deg;  width of checker
		'dblCheckerSizeY_deg',5;... % deg; height of checker
		'intOnOffCheckers',6;... % how many are on/off at any frame?
		'dblContrast',[100];... %contrast [0-100]
		'dblLuminance',[100];...%luminance [0-100]
		'dblBackground',0.5;...%background intensity (dbl, [0 1])
		'dblFlickerFreq',0;...%flicker frequency, 0 for none
		};
	
	%% assign supplied or default values
	sStimParamsChecked = struct;
	for intDefaultField=1:size(cellFieldDefaults,1)
		%get field name and default value
		strField = cellFieldDefaults{intDefaultField,1};
		varDefaultValue = cellFieldDefaults{intDefaultField,2};
		%check if supplied version exists
		if isfield(sStimParams,strField)
			sStimParamsChecked.(strField) = sStimParams.(strField);
		else
			sStimParamsChecked.(strField) = varDefaultValue;
		end
	end
	
	%% assign derived values
	sStimParamsChecked.intBackground = round(mean(sStimParamsChecked.dblBackground)*255);
	sStimParamsChecked.dblScreenWidth_deg = atand((sStimParamsChecked.dblScreenWidth_cm / 2) / sStimParamsChecked.dblScreenDistance_cm) * 2;
	sStimParamsChecked.dblScreenHeight_deg = atand((sStimParamsChecked.dblScreenHeight_cm / 2) / sStimParamsChecked.dblScreenDistance_cm) * 2;
	dblSubjectPosX_deg = atand((sStimParamsChecked.dblSubjectPosX_cm / 2) / sStimParamsChecked.dblScreenDistance_cm) * 2;
	dblSubjectPosY_deg = atand((sStimParamsChecked.dblSubjectPosY_cm / 2) / sStimParamsChecked.dblScreenDistance_cm) * 2;
	
	%% check if all supplied fields are used
	cellSuppliedFields = fieldnames(sStimParams);
	cellUsedFields = cat(1,fieldnames(sStimParamsChecked));
	indUsedFields = ismember(cellSuppliedFields,cellUsedFields);
	if any(~indUsedFields)
		error([mfilename ':IncorrectFieldsSupplied'],sprintf('Did not recognize the following fields: "%s", please check',cell2str(cellSuppliedFields(~indUsedFields))));
	end
	sStimParams = sStimParamsChecked;
	clear sStimParamsChecked;
	
	%% check stimulus type
	strStimType = sStimParams.strStimType;
	cellStimTypes = {'SparseCheckers','FlickerCheckers'};
	intStimType = find(ismember(cellStimTypes,strStimType), 1);
	if isempty(intStimType),error([mfilename ':StimTypeError'],sprintf('Stimulus type "%s" is not recognized [%s]',strStimType,getTime));end
	
	%% check if GPU should be used, and specify device
	if sStimParams.intUseGPU > 0
		objDevice = gpuDevice();
		if objDevice.Index ~= sStimParams.intUseGPU
			fprintf('GPU processing on device %d requested\n',sStimParams.intUseGPU);
			objDevice = gpuDevice(sStimParams.intUseGPU);
			fprintf('\b; Device "%s" selected; Compute capability is %s\n',objDevice.Name,objDevice.ComputeCapability);
		end
	end
	
	%% check if screen size is supplied
	if isnan(sStimParams.intScreenWidth_pix) || isnan(sStimParams.intScreenHeight_pix)
		intOldVerbosity = Screen('Preference', 'Verbosity',1); %stop PTB spamming
		vecRect=Screen('Rect', sStimParams.intUseScreen);
		Screen('Preference', 'Verbosity',intOldVerbosity); %enable PTB spamming
		sStimParams.intScreenWidth_pix = vecRect(3) - vecRect(1);
		sStimParams.intScreenHeight_pix = vecRect(4) - vecRect(2);
	end
	intScreenWidth_pix = sStimParams.intScreenWidth_pix;
	intScreenHeight_pix = sStimParams.intScreenHeight_pix;
	
	%% check if retinal map is supplied, otherwise calculate flat pixel-based map
	if ~exist('matMapDegsXY','var') || isempty(matMapDegsXY)
		if ~isnan(intScreenWidth_pix) && ~isnan(intScreenHeight_pix)
			vecPixX_deg = ((1:intScreenWidth_pix)/intScreenWidth_pix)*dblScreenWidth_deg-dblSubjectPosX_deg;
			vecPixY_deg = ((1:intScreenHeight_pix)/intScreenHeight_pix)*dblScreenWidth_deg-dblSubjectPosY_deg;
			%move to gpu
			if sStimParams.intUseGPU > 0
				vecPixX_deg = gpuArray(vecPixX_deg);
				vecPixY_deg = gpuArray(vecPixY_deg);
			end
			[mapX,mapY] = meshgrid(vecPixX_deg,vecPixY_deg);
			matMapDegsXY(:,:,1) = cat(3,mapX,mapY);
		else
			error
		end
	end
	
	%% crop retinal map to screen area
	[intSizeY,intSizeX] = size(matMapDegsXY(:,:,1));
	intOffsetX = 1+(intSizeX-intScreenWidth_pix)/2;
	intOffsetY = 1+(intSizeY-intScreenHeight_pix)/2;
	vecSelectRect = [intOffsetX intOffsetY (intScreenWidth_pix)+intOffsetX-1 (intScreenHeight_pix)+intOffsetY-1];
	matMapDegsX = matMapDegsXY(vecSelectRect(2):vecSelectRect(4),vecSelectRect(1):vecSelectRect(3),1);
	matMapDegsY = matMapDegsXY(vecSelectRect(2):vecSelectRect(4),vecSelectRect(1):vecSelectRect(3),2);
	matMapDegsXY_crop(:,:,1) = matMapDegsX;
	matMapDegsXY_crop(:,:,2) = matMapDegsY;
	
	%% build checker board
	vecDegRangeX = [min(matMapDegsX(:)) max(matMapDegsX(:))];
	vecDegRangeY = [min(matMapDegsY(:)) max(matMapDegsY(:))];
	dblCheckerSizeX_deg = sStimParams.dblCheckerSizeX_deg;
	dblCheckerSizeY_deg = sStimParams.dblCheckerSizeY_deg;
	vecCheckersX = vecDegRangeX(1):dblCheckerSizeX_deg:(max(matMapDegsX(:))+dblCheckerSizeX_deg);
	[dummy,intVal] = min(abs(vecCheckersX));
	vecCheckersEdgeX = vecCheckersX - vecCheckersX(intVal);
	vecCheckersY = vecDegRangeY(1):dblCheckerSizeY_deg:(max(matMapDegsY(:))+dblCheckerSizeY_deg);
	[dummy,intVal] = min(abs(vecCheckersY));
	vecCheckersEdgeY = vecCheckersY - vecCheckersY(intVal);
	intNumTotalCheckers = (numel(vecCheckersEdgeX)-1) * (numel(vecCheckersEdgeY)-1);
	intOnOffCheckers = sStimParams.intOnOffCheckers;
	dblStimsForMinCoverage = intNumTotalCheckers/intOnOffCheckers;
	intStimsForMinCoverage = ceil(dblStimsForMinCoverage);
	%% build x-y combinations
	%subdivide in partial coverages
	%level1: have on-field at every location, have off-field at every location
	%level2: have on-field and off-field at every location, in different
	%combinations from level1
	%etc..
	
	%use on stimuli as primaries, then assign off stimuli to non-used
	%locations
	matLinLoc = reshape(1:intNumTotalCheckers,[numel(vecCheckersEdgeY)-1 numel(vecCheckersEdgeX)-1]);
	matUsedLocOn = zeros(size(matLinLoc));
	matUsedLocOff = zeros(size(matLinLoc));
	
	%% make stim object structure
	intStim=1;
	sStimObject = struct;
	%stim variables
	sStimObject(intStim).StimType = strStimType;
	sStimObject(intStim).CornerTrigger = sStimParams.intCornerTrigger;
	sStimObject(intStim).CornerSize =  sStimParams.dblCornerSize;
	sStimObject(intStim).CheckersEdgeX = vecCheckersEdgeX;
	sStimObject(intStim).CheckersEdgeY = vecCheckersEdgeY;
	sStimObject(intStim).LinLoc = matLinLoc;
	sStimObject(intStim).LinLocOn = []; %placeholder
	sStimObject(intStim).LinLocOff = []; %placeholder
	sStimObject(intStim).UsedLinLocOn = matUsedLocOn;
	sStimObject(intStim).UsedLinLocOff = matUsedLocOff;
	
	%stimulus control variables
	sStimObject(intStim).CheckerSizeX_deg = sStimParams.dblCheckerSizeX_deg;
	sStimObject(intStim).CheckerSizeY_deg = sStimParams.dblCheckerSizeY_deg;
	sStimObject(intStim).OnOffCheckers = sStimParams.intOnOffCheckers;
	sStimObject(intStim).Contrast = sStimParams.dblContrast;
	sStimObject(intStim).Luminance = sStimParams.dblLuminance;
	sStimObject(intStim).Background = sStimParams.dblBackground;
	sStimObject(intStim).AntiAlias = sStimParams.intAntiAlias;
	sStimObject(intStim).UseGPU = sStimParams.intUseGPU;
	
	%screen & viewing variables
	sStimObject(intStim).ScreenDistance_cm = sStimParams.dblScreenDistance_cm;
	sStimObject(intStim).SubjectPosX_cm = sStimParams.dblSubjectPosX_cm;
	sStimObject(intStim).SubjectPosY_cm = sStimParams.dblSubjectPosY_cm;
	sStimObject(intStim).UseMask = sStimParams.vecUseMask;
	sStimObject(intStim).ScreenWidth_cm = sStimParams.dblScreenWidth_cm; % cm; measured [51]
	sStimObject(intStim).ScreenHeight_cm = sStimParams.dblScreenHeight_cm; % cm; measured [29]
	sStimObject(intStim).ScreenWidth_pix = sStimParams.intScreenWidth_pix; % cm
	sStimObject(intStim).ScreenHeight_pix = sStimParams.intScreenHeight_pix; % cm
end

