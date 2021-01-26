% default options are in parenthesis after the comment
clear all;
%sites
strPath = 'D:\Data\Processed\Neuropixels\';
strPath2 = 'P:\Montijn\DataPreProcessed\';
strSubFormat = '*S%dL%d_AP.mat';

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
cellMouseType{1}{4} = 'BL6';
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
	1 1;...1
	1 2;...2
	1 3;...3
	1 4;...4
	2 1;...5
	2 2;...6
	2 3;...7
	2 4;...8
	2 5;...9
	2 6;...10
	3 1;...11
	3 2;...12
	3 3];%13

%% run module
runPostProcessProbeAreasModule;