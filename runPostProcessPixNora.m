% default options are in parenthesis after the comment
clear all;

%sites
cellRec{1}{1} = 'Z:\NIN202104_Long_range_connections\NIN202103_Neuropixels\Rawdata\SpikeGLX\20201208_NPX6_RunOptoNoraR01_g0';


%which do we want to process?
matRunPrePro = [...
	1 1;...
    ];

cellDepthCorrection{1}{1} = 0;%01

cellDepths{1}{1} = 3500;

%cellDepths = cellfun(@plus,cellDepths,cellDepthCorrection);
cellMouseType{1}{1} = 'RBP4';

%set target path
strDataTarget = 'Z:\NIN202104_Long_range_connections\NIN202103_Neuropixels\Preprocessed\SpikeGLX\';
strSecondPathAP = 'C:\DataAP\';

%boolean switch
boolOnlyJson = false;
boolUseEyeTracking = false;
boolUseVisSync = false;

%% run
runPostProcessPixModule