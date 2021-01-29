function [strEstTotDur,sStimParams,sStimObject] = RE_evaluateStimPresets(sStimStruct,strStimType)
	
	%evaluate different types
	sStimPresetsLocal = sStimStruct;
	
	%remove generic fields
	cellFields = fieldnames(sStimStruct);
	cellRemFields = {'strExpType','strOutputPath','strTempObjectPath','intUseDaqDevice'}';
	indKeepRemGenFields = contains(cellRemFields,cellFields);
	cellRemGenFields = cellRemFields(indKeepRemGenFields);
	if strcmpi(strStimType,'RunDriftingGratings')
		%remove anything not a vector
		indKeep = cellfun(@(x) strcmp(x(1:3),'vec'),cellFields);
		sStimCombos = rmfield(sStimStruct,cat(1,cellFields(~indKeep),cellRemGenFields));
		
		[sStimParams,sStimObject,sStimTypeList] = getDriftingGratingCombos(rmfield(sStimCombos,'vecOrientationNoise'));
		
	elseif strcmpi(strStimType,'RunReceptiveFieldMapping')
		%remove anything starting with 'dblSecs'
		indRem = cellfun(@(x) strcmp(x(1:7),'dblSecs'),cellFields);
		sStimCombos = rmfield(sStimStruct,cat(1,cellFields(indRem),cellRemGenFields));
		
		[sStimParams,sStimObject,matMapDegsXY_crop,intStimsForMinCoverage] = getSparseCheckerCombos(sStimCombos);
		if ~isfield(sStimPresetsLocal,'intNumRepeats')
			sStimPresetsLocal.intNumRepeats = intStimsForMinCoverage;
		end
	elseif strcmpi(strStimType,'RunNaturalMovie')
		%remove anything starting with 'dblSecs'
		indRem = cellfun(@(x) strcmp(x(1:7),'dblSecs'),cellFields);
		sStimCombos = rmfield(sStimStruct,cellFields(indRem));
		sStimCombos = rmfield(sStimCombos,'intNumRepeats');
		sStimCombos = rmfield(sStimCombos,cellRemGenFields);
		
		[sStimParams,sStimObject,sStimTypeList] = getNaturalMovieCombos(sStimCombos);
		if ~isfield(sStimPresetsLocal,'dblSecsStimDur')
			sStimPresetsLocal.dblSecsStimDur = 8.3333;
		end
	elseif strcmpi(strStimType,'RunOptoStim')
		sStimParams = sStimStruct;
		sStimObject = [];
	else
		sStimObject = [];
		warning([mfilename ':StimTypeUnknown'],sprintf('Unknown stimulus type "%s"',strStimType));
	end
	
	%set time string
	if strcmpi(strStimType,'RunOptoStim')
		totalLength = ((sum(sStimStruct.vecPulseDur) + sum(sStimStruct.vecPulseITI))*sStimStruct.intRepsPerPulse ...
			+ (sStimStruct.dblPulseWaitSignal+sStimStruct.dblPulseWaitPause)*numel(sStimStruct.vecPulseITI))*sStimStruct.intTrialNum;
		strEstTotDur = duration(seconds(totalLength),'format','mm:ss');
		%strEstTotDur = [char(strEstTotDur) ' (mm:ss)'];
		strEstTotDur = [char(strEstTotDur) ' (mm:ss); ' num2str(round(sStimPresetsLocal.intTrialNum)) 'x' num2str(round(numel(sStimStruct.vecPulseITI)))];
		
	elseif isempty(sStimObject)
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