function [strEstTotDur,sStimParams,sStimObject] = RE_evaluateStimPresets(sStimStruct,strStimType)
	
	%evaluate different types
	sStimPresetsLocal = sStimStruct;
	if strcmpi(strStimType,'RunDriftingGratings')
		%remove anything not a vector
		cellFields = fieldnames(sStimStruct);
		indKeep = cellfun(@(x) strcmp(x(1:3),'vec'),cellFields);
		sStimCombos = rmfield(sStimStruct,cellFields(~indKeep));
		
		[sStimParams,sStimObject,sStimTypeList] = getDriftingGratingCombos(rmfield(sStimCombos,'vecOrientationNoise'));
		
	elseif strcmpi(strStimType,'RunReceptiveFieldMapping')
		%remove anything starting with 'dblSecs'
		cellFields = fieldnames(sStimStruct);
		indRem = cellfun(@(x) strcmp(x(1:7),'dblSecs'),cellFields);
		sStimCombos = rmfield(sStimStruct,cellFields(indRem));
		
		[sStimParams,sStimObject,matMapDegsXY_crop,intStimsForMinCoverage] = getSparseCheckerCombos(sStimCombos);
		if ~isfield(sStimPresetsLocal,'intNumRepeats')
			sStimPresetsLocal.intNumRepeats = intStimsForMinCoverage;
		end
	elseif strcmpi(strStimType,'RunNaturalMovie')
		%remove anything starting with 'dblSecs'
		cellFields = fieldnames(sStimStruct);
		indRem = cellfun(@(x) strcmp(x(1:7),'dblSecs'),cellFields);
		sStimCombos = rmfield(sStimStruct,cellFields(indRem));
		sStimCombos = rmfield(sStimCombos,'intNumRepeats');
		
		[sStimParams,sStimObject,sStimTypeList] = getNaturalMovieCombos(sStimCombos);
		if ~isfield(sStimPresetsLocal,'dblSecsStimDur')
			sStimPresetsLocal.dblSecsStimDur = 8.3333;
		end
	else
		sStimObject = [];
		warning([mfilename ':StimTypeUnknown'],sprintf('Unknown stimulus type "%s"',strStimType));
	end
	
	%set time string
	if isempty(sStimObject)
		strEstTotDur = 'Unknown stim type';
	else
		
		%calculate time
		intStimTypes = numel(sStimObject);
		intTrialNum = sStimPresetsLocal.intNumRepeats * intStimTypes;
		initialBlank = sStimPresetsLocal.dblSecsBlankAtStart;
		trialDur = sStimPresetsLocal.dblSecsBlankPre + sStimPresetsLocal.dblSecsStimDur + sStimPresetsLocal.dblSecsBlankPost;
		endBlank = sStimPresetsLocal.dblSecsBlankAtEnd;
		totalLength = initialBlank + trialDur * intTrialNum + endBlank;
		
		%convert format
		strEstTotDur = duration(seconds(totalLength),'format','mm:ss');
		%strEstTotDur = [char(strEstTotDur) ' (mm:ss)'];
		strEstTotDur = [char(strEstTotDur) ' (mm:ss); ' num2str(round(sStimPresetsLocal.intNumRepeats)) 'x' num2str(round(intStimTypes))];
	end
end