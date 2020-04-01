function vecProbeLoc = findProbeLoc(vecBregmaCoordsIn,matAnnotationVolume)
	%UNTITLED3 Summary of this function goes here
	%   Detailed explanation goes here
	
	%% define globals
	global vecBregmaCoords;
	global matAV;
	
	%% check inputs
	if nargin < 2
		strPathAllenCCF = 'D:\Downloads\AllenCCF\';
		%matTemplateVolume = readNPY(strcat(strPathAllenCCF,'template_volume_10um.npy')); % grey-scale "background signal intensity"
		matAnnotationVolume = readNPY(strcat(strPathAllenCCF,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
		%tabAnnotationNames = loadStructureTree(strcat(strPathAllenCCF,'structure_tree_safe_2017.csv')); % a table of what all the labels mean
	end
	
	%% define bregma coords
	vecDefaultBregmaCoords = [...
		-3250,...	%AP (x)
		1400,...	%ML (y)
		3840,...	%Depth from pia (z)
		10,...	%Angle AP
		-2];		%Angle ML
	vecBregmaCoords = vecBregmaCoordsIn;
	vecBregmaCoords((end+1):5) = vecDefaultBregmaCoords((numel(vecBregmaCoordsIn)+1):end);
	
	%% find atlas location corresponding to requested bregma coordinates
	matAV = matAnnotationVolume;
	vecCoordsXY = fminsearch(@fSearchWrapper,vecBregmaCoords(1:2));
	vecProbeLoc = vecBregmaCoords;
	vecProbeLoc(1:2) = vecCoordsXY;
end
