function sLocCh = getBrainAreasPerChannel(varIn,tv,av,st,boolCalcDistToBound)
	%getBrainAreasPerChannel Retrieves brain area for each channel using Allen Brain Atlas
	%   sLocCh = getBrainAreasPerChannel(varIn,tv,av,st,boolCalcDistToBound)
	%
	%Input can be sAP structure, sFile structure, sProbeCoords structure or a probe location matrix
	
	%load ABA data
	if ~exist('boolCalcDistToBound','var') || isempty(boolCalcDistToBound)
		boolCalcDistToBound = true;
	end
	if ~exist('st','var') || isempty(boolCalcDistToBound)
		sRP=RP_populateStructure();
		strAllenCCFPath = sRP.strAllenCCFPath;
		[tv,av,st] = RP_LoadABA(strAllenCCFPath); %AP,DV,ML
	end
	st.parent_structure_id = int32(st.parent_structure_id);
	st.id = int32(st.id);
	st.index = uint16(st.index);
	
	%compile data
	if isfield(varIn,'sSources')
		matProbeVector = varIn.sSources.sProbeCoords.sProbeAdjusted.probe_vector([1 3 2],:)';
	elseif isfield(varIn,'sProbeCoords')
		matProbeVector = varIn.sProbeCoords.sProbeAdjusted.probe_vector([1 3 2],:)';
	elseif isfield(varIn,'sProbeAdjusted')
		matProbeVector = varIn.sProbeAdjusted.probe_vector([1 3 2],:)';
	elseif size(varIn,1) == 2 && size(varIn,2) == 3
		matProbeVector = varIn;
	end
	
	%get coords
	probe_n_coords = sqrt(sum(diff(matProbeVector,[],1).^2));
	[probe_xcoords,probe_zcoords,probe_ycoords] = deal( ...
		linspace(matProbeVector(1,1),matProbeVector(2,1),probe_n_coords), ...
		linspace(matProbeVector(1,2),matProbeVector(2,2),probe_n_coords), ...
		linspace(matProbeVector(1,3),matProbeVector(2,3),probe_n_coords));
	
	%get areas
	intSubSample = 2; %default: 5
	av_red = av(1:intSubSample:end,1:intSubSample:end,1:intSubSample:end);
	probe_area_av = interp3(single(av(1:intSubSample:end,1:intSubSample:end,1:intSubSample:end)), ...
		round(probe_zcoords/intSubSample),round(probe_xcoords/intSubSample),round(probe_ycoords/intSubSample),'nearest')';
	probe_area_av(isnan(probe_area_av)) = 1;
	%find parent structures per channel
	intNotIdx = find(contains(st.safe_name,'nucleus of the optic tract','ignorecase',true));
	intNotId = st.id(intNotIdx);
	cellAreaPerCh = cell(size(probe_area_av));
	cellParentAreaPerCh = cell(size(probe_area_av));
	probe_ParentArea_id = nan(size(probe_area_av));
	vecParentAreaPerCh_av = nan(size(probe_area_av));
	for intCh=1:numel(probe_area_av)
		intIdx = find((st.index+1)==probe_area_av(intCh),1);
		cellAreaPerCh{intCh} = st.safe_name{intIdx};
		intParentId = st.parent_structure_id(intIdx);
		if intParentId == 0 || isempty(intParentId)
			intParentId = 997;
		elseif intIdx == intNotIdx
			intParentId = intNotId;
		end
		intParentIdx = find(st.id==intParentId,1);
		vecParentAreaPerCh_av(intCh) = st.index(intParentIdx)+1;
		probe_ParentArea_id(intCh) = intParentId;
		cellParentAreaPerCh{intCh} = st.safe_name{intParentIdx};
	end
	
	%reduce annoted volume to parent structures
	vecStructures_av = unique(av_red(:));
	av_red_parent = av_red;
	for intStructure=1:numel(vecStructures_av)
		intStructAv = vecStructures_av(intStructure);
		intStructId = st.id((st.index+1)==intStructAv);
		intParentId = st.parent_structure_id(st.id==intStructId);
		if intParentId == 0 || isempty(intParentId)
			intParentId = 997;
		elseif intStructId == intNotIdx
			intParentId = intNotIdx;
		end
		intParentIdx = find(st.id==intParentId,1);
		intParentAv = st.index(intParentIdx)+1;
		av_red_parent(av_red==intStructAv)=intParentAv;
	end
	
	%find locations along probe
	vecAreaBoundaries = intersect(unique([find(~isnan(probe_ParentArea_id),1,'first'); ...
		find(diff(probe_ParentArea_id) ~= 0);find(~isnan(probe_ParentArea_id),1,'last')]),find(~isnan(probe_ParentArea_id)));
	vecAreaCenters = vecAreaBoundaries(1:end-1) + diff(vecAreaBoundaries)/2;
	[dummy,vecIdx]=ismember(probe_ParentArea_id(round(vecAreaCenters)),double(st.id));
	vecAreaLabels = st.safe_name(vecIdx);
	
	%calculate distance to boundary
	vecDistToBoundaryPerCh = nan(1,numel(vecParentAreaPerCh_av));
	if boolCalcDistToBound
		[Z,Y,X] = meshgrid(1:intSubSample:size(av,1),1:intSubSample:size(av,2),1:intSubSample:size(av,3));
		matCoordsPerCh = cat(1,probe_zcoords,probe_ycoords,probe_xcoords);
		for intCh=1:numel(vecParentAreaPerCh_av)
			vecUseZ = round(((-10:intSubSample:10) + probe_zcoords(intCh))/intSubSample); %AP,DV,ML
			if min(vecUseZ) < 1,vecUseZ = vecUseZ - min(vecUseZ) + 1;end
			if max(vecUseZ) > size(av_red_parent,1),vecUseZ = vecUseZ - max(vecUseZ) + size(av_red_parent,1);end
			
			vecUseY = round(((-10:intSubSample:10) + probe_ycoords(intCh))/intSubSample); %AP,DV,ML
			if min(vecUseY) < 1,vecUseY = vecUseY - min(vecUseY) + 1;end
			if max(vecUseY) > size(av_red_parent,2),vecUseY = vecUseY - max(vecUseY) + size(av_red_parent,2);end
			
			vecUseX = round(((-10:intSubSample:10) + probe_xcoords(intCh))/intSubSample); %AP,DV,ML
			if min(vecUseX) < 1,vecUseX = vecUseX - min(vecUseX) + 1;end
			if max(vecUseX) > size(av_red_parent,3),vecUseX = vecUseX - max(vecUseX) + size(av_red_parent,3);end
			
			matSubAv= av_red_parent(vecUseY,vecUseZ,vecUseX);
			matX = X(vecUseY,vecUseZ,vecUseX);
			matY = Y(vecUseY,vecUseZ,vecUseX);
			matZ = Z(vecUseY,vecUseZ,vecUseX);
			
			matXd = (matX-probe_xcoords(intCh)).^2;
			matZd = (matZ-probe_zcoords(intCh)).^2;
			matYd = (matY-probe_ycoords(intCh)).^2;
			matDist = sqrt(matXd + matZd + matYd);
			intThisArea = vecParentAreaPerCh_av(intCh);
			vecAllDist = matDist(matSubAv~=intThisArea);
			if isempty(vecAllDist)
				vecDistToBoundaryPerCh(intCh) = max(matDist(:))*10;
			else
				vecDistToBoundaryPerCh(intCh) = min(vecAllDist)*10;
			end
		end
	end
	
	%construct output
	sLocCh.cellAreaPerCh = cellAreaPerCh;
	sLocCh.cellParentAreaPerCh = cellParentAreaPerCh;
	sLocCh.vecParentAreaPerCh_av = vecParentAreaPerCh_av;
	sLocCh.vecAreaBoundaries = vecAreaBoundaries;
	sLocCh.vecAreaCenters = vecAreaCenters;
	sLocCh.vecAreaLabels = vecAreaLabels;
	sLocCh.vecDistToBoundaryPerCh = vecDistToBoundaryPerCh;
	sLocCh.matCoordsPerCh = matCoordsPerCh;
end

