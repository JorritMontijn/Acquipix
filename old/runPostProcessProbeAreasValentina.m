% default options are in parenthesis after the comment
clear all;

%sites
cellRec{1}{1} = '';
cellRec{1}{2} = '';
cellRec{1}{3} = '';

%where is the preprocessed data saved?
strPath = 'D:\NeuropixelData\TRNinvivo\processed\Mango\Exp2020-11-23\';
strSubFormat = '*S%dL%d_AP.mat';
strPathAllenCCF = 'C:\Users\user4\Documents\AllenCCF\';

%which do we want to process?
matRunPrePro = [...
	1 1;...
	];

%which edits should we make?
cellDepthCorrection{1}{1} = -250;%01
cellDepthCorrection{1}{2} = 0;%01

cellDepths{1}{1} = 3600;
cellDepths{1}{2} = 3300;

cD = cellfun(@(x,y) cellfun(@plus,x,y,'uniformoutput',false),cellDepths,cellDepthCorrection,'uniformoutput',false);

%[AP, ML, Depth-of-tip-from-pia, AP-angle, ML-angle]
cellBregmaCoords{1}{1} = [-1110 -2554 cD{1}{1} 7 10];
cellBregmaCoords{1}{2} = [-2900 2100 cD{1}{2} 7 -3];

%% run module
runPostProcessProbeAreasModule;