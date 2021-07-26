function [vecRealLoc] = getRealLoc(vecRefLoc,matAnnotationVolume)
	%getRealLoc Get position of brain intersect relative to bregma
	%vecRealLoc = getRealLoc(vecRefLoc,matAnnotationVolume)
	%
	%   vecRefLoc: [AP, ML, depth, AP-angle, ML-angle]
	
	%% check inputs
	if nargin < 2
		strPathAllenCCF = 'D:\Downloads\AllenCCF\';
		%matTemplateVolume = readNPY(strcat(strPathAllenCCF,'template_volume_10um.npy')); % grey-scale "background signal intensity"
		matAnnotationVolume = readNPY(strcat(strPathAllenCCF,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
		%tabAnnotationNames = loadStructureTree(strcat(strPathAllenCCF,'structure_tree_safe_2017.csv')); % a table of what all the labels mean
	end
	
	%% define variables
	%define step size
	dblProbeStep = 10; %probe in steps of 10 microns
	
	vecBregma = [5400,...%AP
		5700,...%ML
		0];%z
	
	%set top location
	vecRefTop = [vecRefLoc(1:2) - vecBregma(1:2) 0];
	%swap coordinates because we rotate the axes
	[z,y,x] = sph2cart(deg2rad(vecRefLoc(5)),deg2rad(vecRefLoc(4)),10000);
	vecRefBottom = vecRefTop + [x y z];
	
	matProbeAxis = abs([vecRefTop' vecRefBottom'])/dblProbeStep;
	
	%% get atlas coords
	dblPointsN = sqrt(sum(diff(matProbeAxis,[],2).^2));
	[vecAtlasX,vecAtlasY,vecAtlasZ] = deal( ...
		linspace(matProbeAxis(1,1),matProbeAxis(1,2),dblPointsN), ...
		linspace(matProbeAxis(2,1),matProbeAxis(2,2),dblPointsN), ...
		linspace(matProbeAxis(3,1),matProbeAxis(3,2),dblPointsN));
	
	% Get brain labels across the probe and trajectory, and intersection with brain
	dblAtlasStep = 5;
	vecAreaIdx = interp3(single(matAnnotationVolume(1:dblAtlasStep:end,1:dblAtlasStep:end,1:dblAtlasStep:end)), ...
		round(vecAtlasZ/dblAtlasStep),round(vecAtlasX/dblAtlasStep),round(vecAtlasY/dblAtlasStep));
	intBrainStartIdx = find(vecAreaIdx > 1,1);
	vecLocBrainStart = ...
		[vecAtlasX(intBrainStartIdx),vecAtlasY(intBrainStartIdx),vecAtlasZ(intBrainStartIdx)]';
	
	% Get position of brain intersect relative to bregma
	vecRealLoc = [round(vecBregma - 10*vecLocBrainStart') vecRefLoc(4:5)];
end

