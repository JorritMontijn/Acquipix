% default options are in parenthesis after the comment
clear all;

%sites
cellRec{1}{1} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-10\20201110_Teddy1_54690_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-11\20201111_teddy1_54690_set1_RunNaturalMovieR01_g0';
cellRec{1}{3} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-12\20201112_teddy1_54690_set1_Rundriftinggrating_g0';

%where is the preprocessed data saved?
strPath = 'D:\NeuropixelData\TRNinvivo\processed';
strSubFormat = '*S%dL%d_AP.mat';
strPathAllenCCF = 'C:\Users\user4\Documents\AllenCCF\';

%which do we want to process?
matRunPrePro = [...
	1 1;...
	1 2];

%which edits should we make?
cellDepthCorrection{1}{1} = 0;%01
cellDepthCorrection{1}{2} = 0;%01

cellDepths{1}{1} = 3300;
cellDepths{1}{2} = 3300;

cD = cellfun(@(x,y) cellfun(@plus,x,y,'uniformoutput',false),cellDepths,cellDepthCorrection,'uniformoutput',false);

%[AP, ML, Depth-of-tip-from-pia, AP-angle, ML-angle]
cellBregmaCoords{1}{1} = [-2700 1700 cD{1}{1} 6 -2];
cellBregmaCoords{1}{2} = [-2900 2100 cD{1}{2} 7 -3];

%% run module
runPostProcessProbeAreasModule;