% default options are in parenthesis after the comment
clear all;

%sites
cellRec{1}{1} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-23\20201123_Mango_RunReceptiveFieldMappingR01_g0';
cellRec{1}{2} = '';
cellRec{1}{3} = '';

%which do we want to process?
matRunPrePro = [...
	1 1;...
	];

cellDepthCorrection{1}{1} = 0;%01
cellDepthCorrection{1}{2} = 0;%01

cellDepths{1}{1} = 3300;
cellDepths{1}{2} = 3300;

%cellDepths = cellfun(@plus,cellDepths,cellDepthCorrection);
cellMouseType{1}{1} = 'Gria3';

%set target path
strDataTarget = 'P:\GluA3_VR\TRNinvivo\processed';
strSecondPathAP = 'D:\NeuropixelData\';

%boolean switch
boolOnlyJson = false;

%% run
runPostProcessPixModule