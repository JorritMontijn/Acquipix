function sLocCh = getBrainAreasPerChannel(varIn,sAtlas,boolCalcDistToBound,probe_n_coords)
	%getBrainAreasPerChannel Retrieves brain area for each channel using Allen Brain Atlas
	%   sLocCh = getBrainAreasPerChannel(varIn,sAtlas,boolCalcDistToBound,probe_n_coords)
	%
	%Input can be sAP structure, sFile structure, sProbeCoords structure or a probe location matrix
	%
	%Update 20221202: new coordinate system to work with UPF files. Requires UniversalProbeFinder.
	
	%load ABA data
	if ~exist('probe_n_coords','var') || isempty(probe_n_coords)
		probe_n_coords = 384;
	end
	if ~exist('boolCalcDistToBound','var') || isempty(boolCalcDistToBound)
		boolCalcDistToBound = true;
	end
	if ~exist('sAtlas','var') || isempty(sAtlas)
		sRP=RP_populateStructure();
		strAllenCCFPath = sRP.strAllenCCFPath;
		sAtlas = AL_PrepABA(strAllenCCFPath);
	end
	tv = sAtlas.tv;
	av = sAtlas.av;
	st = sAtlas.st;
	st.parent_structure_id = int32(st.parent_structure_id);
	st.id = int32(st.id);
	st.index = uint16(st.index);
	
	%compile data
	if isfield(varIn,'sSources')
		sProbeAdjusted = varIn.sSources.sProbeCoords.sProbeAdjusted;
		%matProbeVector = varIn.sSources.sProbeCoords.sProbeAdjusted.probe_vector_cart([1 3 2],:)';
	elseif isfield(varIn,'sProbeCoords')
		sProbeAdjusted = varIn.sProbeCoords.sProbeAdjusted;
		%matProbeVector = varIn.sProbeCoords.sProbeAdjusted.probe_vector_cart([1 3 2],:)';
	elseif isfield(varIn,'sProbeAdjusted')
		sProbeAdjusted = varIn.sProbeAdjusted;
		%matProbeVector = varIn.sProbeAdjusted.probe_vector_cart([1 3 2],:)';
	else
		error([mfilename ':FormatNotRecognized'],'Input does not contain "sProbeAdjusted"');
	end
	% get coords
	dblProbeLength = sProbeAdjusted.stereo_coordinates.ProbeLength;
	matProbeVector = sProbeAdjusted.probe_vector_cart;
	if numel(probe_n_coords) == 1
		vecFracDepth = linspace(0,1,probe_n_coords);
	elseif max(probe_n_coords) <= 1 && min(probe_n_coords) >= 0
		%fractional vector; [0-1]
		vecFracDepth = probe_n_coords;
	else
		%micron vector
		vecFracDepth = probe_n_coords/dblProbeLength;
	end
	if size(vecFracDepth,1) == 1,vecFracDepth=vecFracDepth';end
	if max(vecFracDepth) > (1+1/dblProbeLength) || min(vecFracDepth) < 0
		error([mfilename ':SizeError'],'Supplied depths contain values outside the probe; please check for unit mismatch. Depths should be in microns');
	end
	
	%transform to atlas
	matProbeVoxels = vecFracDepth*(matProbeVector(1,:) - matProbeVector(2,:)) + matProbeVector(2,:);
	probe_xcoords = matProbeVoxels(:,1);
	probe_ycoords = matProbeVoxels(:,2);
	probe_zcoords = matProbeVoxels(:,3);
	
	%get areas
	intSubSample = 1; %default: 5
	av_red = single(av(1:intSubSample:end,1:intSubSample:end,1:intSubSample:end));
	probe_area_av = interp3(av_red, ... %for interp3, coords are in y,x,z...
		round(probe_ycoords/intSubSample),round(probe_xcoords/intSubSample),round(probe_zcoords/intSubSample),'nearest');
	probe_area_av(isnan(probe_area_av)) = 1;
	if size(probe_area_av,1)==1
		probe_area_av=probe_area_av';
	end
	
	%find locations along probe
	vecAreaBoundaries = intersect(unique([find(~isnan(probe_area_av),1,'first'); ...
		find(diff(probe_area_av) ~= 0);find(~isnan(probe_area_av),1,'last')]),find(~isnan(probe_area_av)));
	vecAreaCenters = vecAreaBoundaries(1:end-1) + diff(vecAreaBoundaries)/2;
	vecIdx=probe_area_av(round(vecAreaCenters));
	vecAreaLabels = st.safe_name(vecIdx);
	
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
	
	%find locations along probe
	vecParentAreaBoundaries = intersect(unique([find(~isnan(probe_ParentArea_id),1,'first'); ...
		find(diff(probe_ParentArea_id) ~= 0);find(~isnan(probe_ParentArea_id),1,'last')]),find(~isnan(probe_ParentArea_id)));
	vecParentAreaCenters = vecParentAreaBoundaries(1:end-1) + diff(vecParentAreaBoundaries)/2;
	[dummy,vecIdx]=ismember(probe_ParentArea_id(round(vecParentAreaCenters)),double(st.id));
	vecParentAreaLabels = st.safe_name(vecIdx);
	
	%calculate distance to boundary
	vecDistToBoundaryPerCh = nan(numel(vecParentAreaPerCh_av),1);
	matCoordsPerCh = cat(2,probe_xcoords,probe_ycoords,probe_zcoords);
	if boolCalcDistToBound
		error('check this')
		
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
		
		%find boundaries
		[Y,X,Z] = meshgrid(1:intSubSample:size(av,2),1:intSubSample:size(av,1),1:intSubSample:size(av,3));
		for intCh=1:numel(vecParentAreaPerCh_av)
			vecUseX = round(((-10:intSubSample:10) + probe_xcoords(intCh))/intSubSample); %AP,DV,ML
			if min(vecUseX) < 1,vecUseX = vecUseX - min(vecUseX) + 1;end
			if max(vecUseX) > size(av_red_parent,1),vecUseX = vecUseX - max(vecUseX) + size(av_red_parent,1);end
			
			vecUseY = round(((-10:intSubSample:10) + probe_ycoords(intCh))/intSubSample); %AP,DV,ML
			if min(vecUseY) < 1,vecUseY = vecUseY - min(vecUseY) + 1;end
			if max(vecUseY) > size(av_red_parent,2),vecUseY = vecUseY - max(vecUseY) + size(av_red_parent,2);end
			
			vecUseZ = round(((-10:intSubSample:10) + probe_zcoords(intCh))/intSubSample); %AP,DV,ML
			if min(vecUseZ) < 1,vecUseZ = vecUseZ - min(vecUseZ) + 1;end
			if max(vecUseZ) > size(av_red_parent,3),vecUseZ = vecUseZ - max(vecUseZ) + size(av_red_parent,3);end
			
			matSubAv= av_red_parent(vecUseX,vecUseY,vecUseZ);
			matX = X(vecUseX,vecUseY,vecUseZ);
			matY = Y(vecUseX,vecUseY,vecUseZ);
			matZ = Z(vecUseX,vecUseY,vecUseZ);
			
			%adjust by voxel size
			matXd = ((matX-probe_xcoords(intCh)).*sAtlas.VoxelSize(1)).^2;
			matYd = ((matY-probe_ycoords(intCh)).*sAtlas.VoxelSize(2)).^2;
			matZd = ((matZ-probe_zcoords(intCh)).*sAtlas.VoxelSize(3)).^2;
			matDist = sqrt(matXd + matYd + matZd);
			intThisArea = vecParentAreaPerCh_av(intCh);
			vecAllDist = matDist(matSubAv~=intThisArea);
			if isempty(vecAllDist)
				vecDistToBoundaryPerCh(intCh) = max(matDist(:));
			else
				vecDistToBoundaryPerCh(intCh) = min(vecAllDist);
			end
		end
	end
	
	%construct output
	sLocCh.vecAreaPerChAv = probe_area_av;
	sLocCh.cellAreaPerCh = cellAreaPerCh;
	sLocCh.cellParentAreaPerCh = cellParentAreaPerCh;
	sLocCh.vecParentAreaPerCh_av = vecParentAreaPerCh_av;
	sLocCh.vecAreaBoundaries = vecAreaBoundaries;
	sLocCh.vecAreaCenters = vecAreaCenters;
	sLocCh.vecAreaLabels = vecAreaLabels;
	sLocCh.vecParentAreaBoundaries = vecParentAreaBoundaries;
	sLocCh.vecParentAreaCenters = vecParentAreaCenters;
	sLocCh.vecParentAreaLabels = vecParentAreaLabels;
	sLocCh.vecDistToBoundaryPerCh = vecDistToBoundaryPerCh;
	sLocCh.matCoordsPerCh = matCoordsPerCh;
end

