function sStimBlock = PP_TransformStimToAP(sStimBlock)
	%remove substructure
	if isfield(sStimBlock,'structEP')
		sStimBlock = sStimBlock.structEP;
	end
	
	%get all fields
	cellFields = fieldnames(sStimBlock);
	
	%define order of preference for time indices & stim type indicator, remove all others
	for intType=1:3
		%define fields in order
		if intType == 1
			cellVarPrefOrder = {'vecStimOnTime','ActOnNI','ActOnSecs','ActStartSecs',...
				'vecTrialStartSecs','vecTrialStimOnSecs'};
		elseif intType == 2
			cellVarPrefOrder = {'vecStimOffTime','ActOffNI','ActOffSecs','ActStopSecs','ActEndSecs',...
				'vecTrialStimOffSecs','vecTrialEndSecs'};
		elseif intType == 3
			%rename ActStimType and vecActStimTypes to vecTrialStimTypes
			cellVarPrefOrder = {'vecTrialStimTypes','ActStimType','vecActStimTypes'};
		end
		strKeepField = '';
		cellRemFields = {};
		for intFieldIdx=1:numel(cellVarPrefOrder)
			intField = find(contains(cellFields,cellVarPrefOrder{intFieldIdx}),1);
			if ~isempty(intField)
				if isempty(strKeepField)
					strKeepField = cellVarPrefOrder{intFieldIdx};
				else
					cellRemFields{end+1} = cellVarPrefOrder{intFieldIdx};
				end
			end
		end
		%remove
		sStimBlock = rmfield(sStimBlock,cellRemFields);
		%rename field if not identical to preferred name
		if ~strcmp(cellVarPrefOrder{1},strKeepField) && ~isempty(strKeepField)
			sStimBlock.(cellVarPrefOrder{1}) = sStimBlock.(strKeepField);
			sStimBlock = rmfield(sStimBlock,strKeepField);
		end
	end
	
	%add corrected pupil times
	if isfield(sStimBlock,'vecPupilOnsetCorrections') && isfield(sStimBlock,'vecStimOnTime')
		sStimBlock.vecPupilStimOn = sStimBlock.vecStimOnTime + sStimBlock.vecPupilOnsetCorrections;
		sStimBlock.vecPupilStimOff = sStimBlock.vecStimOffTime + sStimBlock.vecPupilOnsetCorrections;
	end
	
	%always remove these fields
	cellFields = fieldnames(sStimBlock);
	cellAlwaysRemFields = {'vecPupilOnsetCorrections','vecPupilStimOnFrame','vecPupilStimOffFrame','vecPupilStimOnTime','vecPupilStimOffTime','dblSecsBlankAtStart','dblSecsBlankPre','dblSecsStimDur','dblSecsBlankPost','dblSecsBlankAtEnd'};
	cellRemFields = cellAlwaysRemFields(cellfun(@(x) any(cellfun(@strcmpi,cellfill(x,size(cellFields)),cellFields)),cellAlwaysRemFields));
	sStimBlock = rmfield(sStimBlock,cellRemFields);
	
	%delete all fields that exist in sStimObject except protected and
	%stochastic variables, such as Phase and OrientationNoise
	if isfield(sStimBlock,'sStimObject')
		cellProtectedNames = {'vecStimOnTime','vecStimOffTime','vecTrialStimTypes',...
			'Phase','OrientationNoise'};
		cellStimObjectFields = fieldnames(sStimBlock.sStimObject);
		cellStimBlockFields = fieldnames(sStimBlock);
		indRemove = contains(cellStimBlockFields,cellStimObjectFields) & ~contains(cellStimBlockFields,cellProtectedNames);
		sStimBlock = rmfield(sStimBlock,cellStimBlockFields(indRemove));
	end
	
	%sort fields by type; char>scalar>vector>matrix>cell>struct>other
	indIsChar = structfun(@ischar,sStimBlock);
	indIsScalar = structfun(@isnumeric,sStimBlock) & structfun(@isscalar,sStimBlock) & ~indIsChar;
	indIsVector = structfun(@isnumeric,sStimBlock) & structfun(@isvector,sStimBlock) & ~indIsChar & ~indIsScalar;
	indIsMatrix = structfun(@isnumeric,sStimBlock) & structfun(@ismatrix,sStimBlock) & ~indIsChar & ~indIsScalar & ~indIsVector;
	indIsCell = structfun(@iscell,sStimBlock) & ~indIsChar & ~indIsScalar & ~indIsVector & ~indIsMatrix;
	indIsStruct = structfun(@isstruct,sStimBlock) & ~indIsChar & ~indIsScalar & ~indIsVector & ~indIsMatrix & ~indIsCell;
	indIsOther = ~indIsChar & ~indIsScalar & ~indIsVector & ~indIsMatrix & ~indIsCell & ~indIsStruct;
	%get new order
	vecNewOrder = [find(indIsChar);find(indIsScalar);find(indIsVector);...
		find(indIsMatrix);find(indIsCell);find(indIsStruct);find(indIsOther)];
	if ~all((1:numel(vecNewOrder))'==sort(vecNewOrder))
		error([mfilename 'E:FieldReorderError'],'Error reordering fields');
	end
	sStimBlock = orderfields(sStimBlock,vecNewOrder);
end