function sPupilOut = PP_TransformPupilToAP(sPupilIn)
	
	%get fields
	cellFields = fieldnames(sPupilIn);
	
	%select time
	sPupilOut = struct;
	sPupilOut.vecTime = [];
	
	%rename anything with fixed & include
	vecIsFixed = find(contains(cellFields,'Fixed'));
	for intFieldIdx=1:numel(vecIsFixed)
		intField = vecIsFixed(intFieldIdx);
		strFieldIn = cellFields{intField};
		strFieldOut = strrep(strFieldIn,'Fixed','');
		strFieldOut = strrep(strFieldOut,'Pupil','');
		sPupilOut.(strFieldOut) = sPupilIn.(strFieldIn);
	end
	if ~isfield(sPupilIn,'vecPupilTimeFixed')
		sPupilOut.vecTime = sPupilIn.vecPupilTime;
	end
	
	%include
	cellInclude = {'vecPupilSyncLum'};
	vecIsIncluded = find(contains(cellFields,cellInclude));
	for intFieldIdx=1:numel(vecIsIncluded)
		intField = vecIsIncluded(intFieldIdx);
		strFieldIn = cellFields{intField};
		strFieldOut = strrep(strFieldIn,'Pupil','');
		sPupilOut.(strFieldOut) = sPupilIn.(strFieldIn);
	end
	
	%special; combine edited
	if isfield(sPupilIn,'vecPupilFixedPoints')
		sPupilOut = rmfield(sPupilOut,'vecPoints');
		vecPupilFixedPoints = sPupilIn.vecPupilFixedPoints;
	else
		vecPupilFixedPoints = zeros(size(sPupilIn.vecPupilFixedCenterX));
	end
	if isfield(sPupilIn,'vecPupilIsEdited')
		vecPupilIsEdited = sPupilIn.vecPupilIsEdited;
	else
		vecPupilIsEdited = zeros(size(sPupilIn.vecPupilFixedCenterX));
	end
	sPupilOut.vecIsEdited = vecPupilFixedPoints + vecPupilIsEdited;
	
	%move everything else to source
	vecUsed = unique(cat(1,vecIsFixed,vecIsIncluded));
	sPupilOut.sRaw = rmfield(sPupilIn,cellFields(vecUsed));
end