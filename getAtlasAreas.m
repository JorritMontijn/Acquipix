function [vecBregmaLoc,vecProbeAreaEdges,vecProbeAreaCenters,cellProbeAreaLabels,vecProbeAreaIdx] = getAtlasAreas(vecBregmaCoords,matAnnotationVolume,tabAnnotationNames,strPathAllenCCF)
	%getAtlasAreas Retrieve atlas brain areas for probe location
	%  [vecBregmaLoc,vecProbeAreaEdges,vecProbeAreaCenters,cellProbeAreaLabels,vecProbeAreaIdx] = ...
	%		getAtlasAreas(vecBregmaCoords,matAnnotationVolume,tabAnnotationNames,strPathAllenCCF)
	%
	%input:
	%	- vecBregmaCoords [1 x 5]: Bregma coordinates in microns/degrees:
	%								[AP, ML, Depth-of-tip-from-pia, AP-angle, ML-angle]  
	%	- matAnnotationVolume: matrix with AllenCCF annotations (optional: will load if not supplied)
	%	- tabAnnotationNames: table with AllenCCF annotations (optional: will load if not supplied)
	%
	%output:
	%	- vecBregmaLoc; used Bregma location
	%	- vecProbeAreaEdges; edges of areas in microns
	%	- vecProbeAreaCenters; centers of areas in microns
	%	- cellProbeAreaLabels; labels of areas
	%	- vecProbeAreaIdx; indices of areas
	%
	%Version history:
	%1.0 - March 20 2019
	%	Created by Jorrit Montijn
		
    %% check inputs
    if ~exist('strPathAllenCCF','var') || isempty(strPathAllenCCF)
            strPathAllenCCF = 'D:\Downloads\AllenCCF\';
    end
    if ~exist('matAnnotationVolume','var') || isempty(matAnnotationVolume) || ~exist('tabAnnotationNames','var') || isempty(tabAnnotationNames)
		%matTemplateVolume = readNPY(strcat(strPathAllenCCF,'template_volume_10um.npy')); % grey-scale "background signal intensity"
		matAnnotationVolume = readNPY(strcat(strPathAllenCCF,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
		tabAnnotationNames = loadStructureTree(strcat(strPathAllenCCF,'structure_tree_safe_2017.csv')); % a table of what all the labels mean
	end
	
	%% find atlas location for bregma coords relative to roof of map
	vecProbeLoc = findProbeLoc(vecBregmaCoords,matAnnotationVolume);

	%% define variables
	%define step size
	dblQueryStep = 10; %query atlas in steps of 10 microns
	
	vecBregma = [5400,...%AP
		5700,...%ML
		0];%z
	
	%set top location
	vecRefTop = [vecProbeLoc(1:2) - vecBregma(1:2) 0];
	%swap coordinates because we rotate the axes
	[z,y,x] = sph2cart(deg2rad(vecProbeLoc(5)),deg2rad(vecProbeLoc(4)),10000);
	vecRefBottom = vecRefTop + [x y -z];
	
	matRefAxis = -([vecRefTop' vecRefBottom'])/dblQueryStep;
	
	%% get reference atlas coords
	dblPointsN = sqrt(sum(diff(matRefAxis,[],2).^2));
	[vecAtlasX,vecAtlasY,vecAtlasZ] = deal( ...
		linspace(matRefAxis(1,1),matRefAxis(1,2),dblPointsN), ...
		linspace(matRefAxis(2,1),matRefAxis(2,2),dblPointsN), ...
		linspace(matRefAxis(3,1),matRefAxis(3,2),dblPointsN));
	
	% Get brain labels across the probe and trajectory, and intersection with brain
	dblAtlasStep = 5;
	vecAreaIdx = interp3(single(matAnnotationVolume(1:dblAtlasStep:end,1:dblAtlasStep:end,1:dblAtlasStep:end)), ...
		round(vecAtlasZ/dblAtlasStep),round(vecAtlasX/dblAtlasStep),round(vecAtlasY/dblAtlasStep));
	intBrainStartIdx = find(vecAreaIdx > 1,1);
	vecLocBrainStart = ...
		[vecAtlasX(intBrainStartIdx),vecAtlasY(intBrainStartIdx),vecAtlasZ(intBrainStartIdx)]';
	
	%% get locations from start of probe
	vecProbeTop = vecLocBrainStart';
	
	%swap coordinates because we rotate the axes
	[z,y,x] = sph2cart(deg2rad(vecProbeLoc(5)),deg2rad(vecProbeLoc(4)),vecProbeLoc(3)/dblQueryStep);
	vecProbeBottom = vecProbeTop - [x y -z];
	
	matProbeAxis = ([vecProbeTop' vecProbeBottom']);
	
	
	%% get areas
	dblPointsN = sqrt(sum(diff(matProbeAxis,[],2).^2));
	[vecAtlasX,vecAtlasY,vecAtlasZ] = deal( ...
		linspace(matProbeAxis(1,1),matProbeAxis(1,2),dblPointsN), ...
		linspace(matProbeAxis(2,1),matProbeAxis(2,2),dblPointsN), ...
		linspace(matProbeAxis(3,1),matProbeAxis(3,2),dblPointsN));
	
	%% get brain areas along probe
	vecProbeAreaIdxPerPoint = interp3(single(matAnnotationVolume(1:dblAtlasStep:end,1:dblAtlasStep:end,1:dblAtlasStep:end)), ...
		round(vecAtlasZ/dblAtlasStep),round(vecAtlasX/dblAtlasStep),round(vecAtlasY/dblAtlasStep))';
	vecProbeAreaEdges = intersect(unique([find(~isnan(vecProbeAreaIdxPerPoint),1,'first'); ...
		find(diff(vecProbeAreaIdxPerPoint) ~= 0);find(~isnan(vecProbeAreaIdxPerPoint),1,'last')]),find(~isnan(vecProbeAreaIdxPerPoint)));
	vecProbeAreaCenters = vecProbeAreaEdges(1:end-1) + diff(vecProbeAreaEdges)/2;
	vecProbeAreaIdx = vecProbeAreaIdxPerPoint(round(vecProbeAreaCenters));
	cellProbeAreaLabels = tabAnnotationNames.safe_name(vecProbeAreaIdx);
	
	% Get the depth of the bottom of the probe (sign: hack by z offset)
	dblProbeDepth = dblQueryStep*round(sqrt(sum((vecLocBrainStart - matProbeAxis(:,2)).^2)))* ...
		sign(matProbeAxis(3,2)-vecLocBrainStart(3));
	
	% Get position of brain intersect relative to bregma
	vecBregmaLoc = round((vecBregma([1,2]) - dblQueryStep*vecLocBrainStart(1:2)'));
	vecBregmaLoc(3:5) = [dblProbeDepth vecProbeLoc(4:5)];
	
	%transform edges/centers to microns
	vecProbeAreaEdges = vecProbeAreaEdges*dblQueryStep;
	vecProbeAreaCenters = vecProbeAreaCenters*dblQueryStep;
	
	% Update the text
	probe_text = ['Probe insertion: ' ....
		num2str(vecBregmaLoc(1)) ' AP, ', ...
		num2str(-vecBregmaLoc(2)) ' ML, ', ...
		num2str(dblProbeDepth) ' Depth, ' ...
		num2str(vecProbeLoc(5)) char(176) ' from midline, ' ...
		num2str(vecProbeLoc(4)) char(176) ' from horizontal'];
	
	
end

