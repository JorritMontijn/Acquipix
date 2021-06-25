% default options are in parenthesis after the comment
clear all;

%sites
cellRec{1}{1} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-23\20201123_Mango_RunReceptiveFieldMappingR01_g0';
cellRec{1}{2} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-24\20201124_Mango_RunReceptiveFieldMappingR01_g0';
cellRec{1}{3} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-25\20201125_Mango_RunDriftingGratingsR01_g0';
cellRec{1}{4} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-26\20201126_Mango_RunReceptiveFieldMappingR01_g0'
%which do we want to process?
matRunPrePro = [...
	1 2;...
    ]

cellDepthCorrection{1}{1} = 0;%01
cellDepthCorrection{1}{2} = 0;%01
cellDepthCorrection{1}{3} = 0;%01
cellDepthCorrection{1}{4} = 0;%01

cellDepths{1}{1} = 3300;
cellDepths{1}{2} = 3300;
cellDepths{1}{3} = 3300;
cellDepths{1}{4} = 3300;

%cellDepths = cellfun(@plus,cellDepths,cellDepthCorrection);
cellMouseType{1}{1} = 'Gria3';
cellMouseType{1}{2} = 'Gria3';
cellMouseType{1}{3} = 'Gria3';
cellMouseType{1}{4} = 'Gria3';

%set target path
strDataTarget = 'P:\GluA3_VR\TRNinvivo\processed';
strSecondPathAP = 'D:\NeuropixelData\';


%boolean switch
boolOnlyJson = true;
boolUseEyeTracking = true;
boolUseVisSync = true;

%set json data
%required fields
sJson = struct;
sJson.version = '1.0';
sJson.dataset = 'Neuropixels data';
sJson.investigator = 'Valentina Riguccini';
sJson.project = 'TRN';
sJson.setup = 'Neuropixels';
sJson.stimulus = 'VisStimAcquipix';
sJson.condition = 'none';

%% run
runPostProcessPixModule