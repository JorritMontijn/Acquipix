function [sStimParams,sStimObject,sStimTypeList] = getDriftingGratingCombos(sStimParams)
	%getDriftingGratingCombos Builds drifting grating combinations from input parameters
	%	[sStimParams,sStimObject,sStimTypeList] = getDriftingGratingCombos(sStimParams)
	
	%% create variable if none supplied
	if ~exist('sStimParams','var');sStimParams=struct;end
	
	%% assign defaults
	cellFieldDefaults = ...
	{...
		%stimulus type
		'strStimType','SquareGrating';...
		'str90Deg','0 degrees is leftward motion; 90 degrees is upward motion';...
		
		%subject parameters
		'dblSubjectPosX_cm',0;... % cm; relative to center of screen
		'dblSubjectPosY_cm',0;... % cm; relative to center of screen
		'dblScreenDistance_cm',16;... % cm; measured
		
		%screen variables
		'intUseScreen',1;... %which screen to use
		'dblScreenWidth_cm',33;... % cm; measured [51]
		'dblScreenHeight_cm',25;... % cm; measured [29]
		
		%stimulus control variables
		'intAntiAlias',1;... % anti-alias? set to "0" to improve performance
		'intUseParPool',0;... % set to non-zero to specify how many workers to use
		'intUseGPU',0;... % set to non-zero to specify which GPU to render stimuli
		'intCornerTrigger',0;... % integer switch; 0=none,1=upper left, 2=upper right, 3=lower left, 4=lower right
		'dblCornerSize',1/30;... % fraction of screen width
		'vecStimPosX_deg',0;... % deg; relative to center of screen
		'vecStimPosY_deg',0;... % deg; relative to center of screen
		'vecStimulusSize_deg',[16];...%circular window in degrees
		'vecSoftEdge_deg',[2];... %width of cosine ramp, [0] hard edge
		'vecBackgrounds',[0.5];... %background intensity (dbl, [0 1])
		'vecUseMask',[1];... %[1] if mask to emulate retinal-space, [0] use screen-space
		'vecContrasts',[100];... %contrast [0-100]
		'vecLuminances',[100];...%luminance [0-100]
		'vecOrientations',[357 3 87 93 177 183 267 273];... %orientation (0 is vertical)
		'vecSpatialFrequencies',[0.08];... %Spat Frequency in cyc/deg 0.08
		'vecTemporalFrequencies',[0.5];... %Temporal frequency in cycles per second (0 = static gratings only)
		'vecPhases',[nan];... %initial phase
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
	sStimParamsChecked.intBackground = round(mean(sStimParamsChecked.vecBackgrounds)*255);
	sStimParamsChecked.dblScreenWidth_deg = atand((sStimParamsChecked.dblScreenWidth_cm / 2) / sStimParamsChecked.dblScreenDistance_cm) * 2;
	sStimParamsChecked.dblScreenHeight_deg = atand((sStimParamsChecked.dblScreenHeight_cm / 2) / sStimParamsChecked.dblScreenDistance_cm) * 2;
	
	%% check all fields starting with "vec"
	cellFields = fieldnames(sStimParamsChecked);
	cellParamIndex = {};
	cellParamValue = {};
	cellParamNames = {};
	for intField=1:numel(cellFields)
		%get field name and size
		strField = cellFields{intField};
		%check if it starts with "vec"
		if strcmpi(strField(1:3),'vec')
			%add to param list
			cellParamIndex(end+1) = {1:numel(sStimParamsChecked.(strField))};
			%check if we need to add subject position
			if strcmp(strField,'vecStimPosX_cm')
				cellParamValue(end+1) = {sStimParamsChecked.(strField) + sStimParamsChecked.dblSubjectPosX_cm};
			elseif strcmp(strField,'vecStimPosY_cm')
				cellParamValue(end+1) = {sStimParamsChecked.(strField) + sStimParamsChecked.dblSubjectPosY_cm};
			else
			cellParamValue(end+1) = {sStimParamsChecked.(strField)};
			end
			cellParamNames(end+1) = {strField};
		end
	end
	
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
	cellStimTypes = {'SquareGrating','SineGrating','Line','NatMov'};
	intStimType = find(ismember(cellStimTypes,strStimType), 1);
	if isempty(intStimType),error([mfilename ':StimTypeError'],sprintf('Stimulus type "%s" is not recognized [%s]',strStimType,getTime));end
	
	%% BUILD STIM COMBINATIONS
	%get combinations
	matStimTypeCombos = buildStimCombos(cellParamIndex);
	[intParams,intStimTypes] = size(matStimTypeCombos);
	vecStimType = 1:intStimTypes;
	
	%remove all variables with only 1 value
	indUseParams = range(matStimTypeCombos,2) > 0;
	cellUseParamIndex = cellParamIndex(indUseParams);
	cellUseParamValue = cellParamValue(indUseParams);
	cellUseParamNames = cellParamNames(indUseParams);
	
	%trial stim type
	sStimParams.vecStimType = vecStimType;
	sStimParams.matStimTypeCombos = matStimTypeCombos;
	sStimParams.intParams = intParams;
	sStimParams.intStimTypes = intStimTypes;
	
	sStimParams.cellParamIndex = cellParamIndex;
	sStimParams.cellParamValue = cellParamValue;
	sStimParams.cellParamNames = cellParamNames;
	sStimParams.cellUseParamIndex = cellUseParamIndex;
	sStimParams.cellUseParamValue = cellUseParamValue;
	sStimParams.cellUseParamNames = cellUseParamNames;
	
	%% make stim type list structure
	sStimTypeList = struct;
	%go through matStimTypeCombos and assign values to sStimTypeList
	for intParam=1:intParams
		strParam = cellParamNames{intParam}; %remove "vec"
		strNewParam = strcat('vecStimType',strParam(4:end));
		sStimTypeList.(strNewParam) = cellParamValue{intParam}(matStimTypeCombos(intParam,:));
	end
	
	%% make stim object structure
	sStimObject = struct;
	%go through matStimTypeCombos and assign values to sStimTypeList
	for intParam=0:intParams
		if intParam==0 %add strStimType & ScreenDistance_cm & SubjectPosX_cm & SubjectPosY_cm
			for intStim=1:intStimTypes
				sStimObject(intStim).StimType = strStimType;
				sStimObject(intStim).CornerTrigger = sStimParams.intCornerTrigger;
				sStimObject(intStim).CornerSize =  sStimParams.dblCornerSize;
				sStimObject(intStim).ScreenDistance_cm = sStimParams.dblScreenDistance_cm;
				sStimObject(intStim).SubjectPosX_cm = sStimParams.dblSubjectPosX_cm;
				sStimObject(intStim).SubjectPosY_cm = sStimParams.dblSubjectPosY_cm;
				sStimObject(intStim).AntiAlias = sStimParams.intAntiAlias;
				sStimObject(intStim).UseGPU = sStimParams.intUseGPU;
			end
		else
			strParam = cellParamNames{intParam}; %remove "vec"
			strNewParam = strParam(4:end);
			if strcmpi(strNewParam((end-2):end),'ies')
				strNewParam = strcat(strNewParam(1:(end-3)),'y');
			elseif strcmpi(strNewParam(end),'s')
				strNewParam = strNewParam(1:(end-1));
			end
			vecValList = cellParamValue{intParam}(matStimTypeCombos(intParam,:));
			for intStim=1:intStimTypes
				sStimObject(intStim).(strNewParam) = vecValList(intStim);
			end
		end
	end
end

