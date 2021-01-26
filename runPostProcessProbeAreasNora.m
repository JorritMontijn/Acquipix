% default options are in parenthesis after the comment
clear all;

%sites
cellRec{1}{1} = 'Z:\NIN202104_Long_range_connections\NIN202103_Neuropixels\Rawdata\SpikeGLX\20201208_NPX6_RunOptoNoraR01_g0';
cellRec{2}{1} = '';

%where is the preprocessed data saved?
strPath = 'C:\DataAP';
strSubFormat = '*S%dL%d_AP.mat';
strPathAllenCCF = 'C:\Users\jamann\Documents\AllenCCF_Data\';

%which do we want to process?
matRunPrePro = [...
	1 1;...
    ];

%which edits should we make?
cellDepthCorrection{1}{1} = 0;%01

cellDepths{1}{1} = 3300;

cD = cellfun(@(x,y) cellfun(@plus,x,y,'uniformoutput',false),cellDepths,cellDepthCorrection,'uniformoutput',false);

%[AP, ML, Depth-of-tip-from-pia, AP-angle, ML-angle]
cellBregmaCoords{1}{1} = [-1845 2871 cD{1}{1} 10 -30];

%% run module
runPostProcessProbeAreasModule;