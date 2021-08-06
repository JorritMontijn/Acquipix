% default options are in parenthesis after the comment
%clear all;
%sites
strTargetPath = 'D:\Data\Raw\Histology\ProbeCoordFiles\';
strPathAllenCCF = 'F:\Data\AllenCCF';
strSubFormat = 'ABA_coords_S%dL%d.mat';

%depths
cellDepthCorrection{1}{1} = 300;%01
cellDepthCorrection{1}{2} = 25;%02, V1
cellDepthCorrection{1}{3} = -300;%03
cellDepthCorrection{1}{4} = 0;%04, NOT DONE
cellDepthCorrection{2}{1} = -650;%05
cellDepthCorrection{2}{2} = -800;%06, V1
cellDepthCorrection{2}{3} = -100;%07
cellDepthCorrection{2}{4} = -150;%08
cellDepthCorrection{2}{5} = -200;%09
cellDepthCorrection{2}{6} = -50;%10
cellDepthCorrection{3}{1} = 100;%11
cellDepthCorrection{3}{2} = -150;%12
cellDepthCorrection{3}{3} = -400;%13

cellDepths{1}{1} = 2650;
cellDepths{1}{2} = 3000;
cellDepths{1}{3} = 3000;
cellDepths{1}{4} = 3500;
cellDepths{2}{1} = 3000;
cellDepths{2}{2} = 3000;
cellDepths{2}{3} = 3000;
cellDepths{2}{4} = 3250;
cellDepths{2}{5} = 3300;
cellDepths{2}{6} = 3500;
cellDepths{3}{1} = 3250;
cellDepths{3}{2} = 3400;
cellDepths{3}{3} = 3300;

cD = cellfun(@(x,y) cellfun(@plus,x,y,'uniformoutput',false),cellDepths,cellDepthCorrection,'uniformoutput',false);

%[AP, ML, Depth-of-tip-from-pia, AP-angle, ML-angle]
vecBregmaCoords = [-3000 1500 cD{1}{1} 6 -2];
cellBregmaCoords{1}{1} = [-2700 1700 cD{1}{1} 6 -2]; %PM/LP
cellBregmaCoords{1}{2} = [-2900 2100 cD{1}{2} 7 -3]; %V1/LP
cellBregmaCoords{1}{3} = [-3000 1700 cD{1}{3} 0 0]; %PM/NOT
%cellBregmaCoords{1}{4} = [0 0 cD{1}{4} 6 -2]; %
cellBregmaCoords{2}{1} = [-2950 1350 cD{2}{1} 6 -2]; %PM/?
cellBregmaCoords{2}{2} = [-3400 1450 cD{2}{2} 8 -6]; %V1/-
cellBregmaCoords{2}{3} = [-2700 1400 cD{2}{3} 6 -2]; %AM/APN
cellBregmaCoords{2}{4} = [-3100 1750 cD{2}{4} 8 -6]; %PM/SC-NOT?
cellBregmaCoords{2}{5} = [-2545 2291 cD{2}{5} 6 -2]; %V1/LGN
cellBregmaCoords{2}{6} = [-2100 1500 cD{2}{6} 6 -2]; %AM/-(LP)
cellBregmaCoords{3}{1} = [-2750 1400 cD{3}{1} 4 -10]; %RS-AM/NOT?
cellBregmaCoords{3}{2} = [-2400 1800 cD{3}{2} 4 -8]; %AM/LP
cellBregmaCoords{3}{3} = [-2800 1300 cD{3}{3} 6 -10]; %RS/NOT?

cellMouseType{1}{1} = 'BL6';
cellMouseType{1}{2} = 'BL6';
cellMouseType{1}{3} = 'BL6';
%cellMouseType{1}{4} = 'BL6';
cellMouseType{2}{1} = 'BL6';
cellMouseType{2}{2} = 'BL6';
cellMouseType{2}{3} = 'BL6';
cellMouseType{2}{4} = 'BL6';
cellMouseType{2}{5} = 'BL6';
cellMouseType{2}{6} = 'BL6';
cellMouseType{3}{1} = 'BL6';
cellMouseType{3}{2} = 'BL6';
cellMouseType{3}{3} = 'BL6';

matRunPrePro = [...
	1 1;...S1L1_MP2_Exp2019-11-20
	1 2;...S1L2_MP2_Exp2019-11-21
	1 3;...S1L3_MP2_Exp2019-11-22
	....1 4;...S1L3_MP2_Exp2019-11-22 [R02]
	2 1;...S2L1_MP3_Exp2019-12-10
	2 2;...S2L2_MP3_Exp2019-12-11
	2 3;...S2L3_MP3_Exp2019-12-12
	2 4;...S2L4_MP3_Exp2019-12-13
	2 5;...S2L5_MP3_Exp2019-12-16
	2 6;...S2L6_MP3_Exp2019-12-17
	3 1;...S3L1_MP4_Exp2020-01-15
	3 2;...S3L2_MP4_Exp2020-01-16
	3 3];%S3L3_MP4_Exp2020-01-16 [R02]

%% load ABA
[tv,av,st]=RP_LoadABA(strPathAllenCCF);
dblMaxAP = size(tv,1);

%% run module
for intRec=1:size(matRunPrePro,1)
	vecRec= matRunPrePro(intRec,:);
	%AP ML Depth AP-deg ML-deg
	vecCoords = cellBregmaCoords{vecRec(1)}{vecRec(2)};
	%transform microns to ABA resolution
	vecCoords(1:3) = vecCoords(1:3)/10; 
	%AP direction is inverted; origin is at back
	vecCoords([1 4]) = -vecCoords([1 4]);
	%ML angle direction is inverted; negative is to the right
	vecCoords([5]) = -vecCoords([5]);
	
	%AP DV ML
	vecBregma = PH_GetBregma();
	vecTop = [vecCoords(1) 0 vecCoords(2)] + vecBregma;
	%find brain start at top coordinates and lower probe starting point
	matFindIntersect = [vecTop;vecTop+[0 384 0]];
	%function requires alternate ordering
	matReorderedForGBI = matFindIntersect(:,[1 3 2])';
	vecIntersect = PH_GetBrainIntersection(matReorderedForGBI,av);
	%add brain intersection depth to original coordinates
	vecTop = vecTop + [0 vecIntersect(3) 0];
	
	%DV AP ML
	[dblDV,dblAP,dblML]=sph2cart(deg2rad(vecCoords(4)),deg2rad(vecCoords(5)),384);
	%AP DV ML
	vecBottom = vecTop + [dblAP dblDV dblML];
	matCoords = [vecTop;vecBottom];
	
	%export
	probe_ccf = struct;
	probe_ccf.points = matCoords;
	
	strTargetFile = fullpath(strTargetPath,sprintf(strSubFormat,vecRec));
	save(strTargetFile,'probe_ccf');
end