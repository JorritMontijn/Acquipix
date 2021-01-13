%% to run phy for clustering after finishing runPreProcessPix:
%
% For more info on phy-contrib's template-gui, see: 
%	https://github.com/kwikteam/phy-contrib/blob/master/docs/template-gui.md
%

%sites
cellRec{1}{1} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-10\20201110_Teddy1_54690_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-11\20201111_teddy1_54690_set1_RunNaturalMovieR01_g0';
cellRec{1}{3} = 'P:\GluA3_VR\TRNinvivo\Teddy1\Exp2020-11-12\20201112_teddy1_54690_set1_Rundriftinggrating_g0';

%which do we want to process?
vecRunPre = [1 2];

%set temp path
strTempDirDefault = 'E:\_TempData'; % path to temporary binary file (same size as data, should be on fast SSD)

%% run
runProcessPixClusteringModule;

