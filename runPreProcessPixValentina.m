%% recordings
clear all;close all;
%sites

%sites
cellRec{1}{1} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-10\20201110_Teddy1_54690_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-11\20201111_teddy1_54690_set1_RunNaturalMovieR01_g0';
cellRec{1}{3} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-12\20201112_teddy1_54690_set1_Rundriftinggrating_g0';

%which do we want to process?
matRunPre = [...
	1 3;...
	];

%											0=none, 1=KS, 2=eye,3=post,4=area+depth
%% define paths
strPathKilosort2 = 'C:\Users\user4\Documents\GitHub\Kilosort';
strNpyMatlab = 'C:\Users\user4\Documents\GitHub\npy-matlab';
strTempDirSSD = 'E:\_TempData';

%% run actual script
runPreProModuleNpx