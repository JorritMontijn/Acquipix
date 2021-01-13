% default options are in parenthesis after the comment
clear all;

%sites
cellRec{1}{1} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-10\20201110_Teddy1_54690_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-11\20201111_teddy1_54690_set1_RunNaturalMovieR01_g0';
cellRec{1}{3} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-12\20201112_teddy1_54690_set1_Rundriftinggrating_g0';

%which do we want to process?
matRunPrePro = [...
	1 1;...
	1 2];

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