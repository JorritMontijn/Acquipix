% default options are in parenthesis after the comment
clear all;
%sites
strDataDrivePath = '\\vs02.herseninstituut.knaw.nl\csf\Montijn\';
cellRec{1}{1} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-11-20\20191120_MP2_RunDriftingGratingsR01_g0');
cellRec{1}{2} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-11-21\20191121_MP2_RunDriftingGratingsR01_g0');
cellRec{1}{3} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-11-22\20191122_MP2_RunDriftingGratingsR01_g0');
cellRec{1}{4} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-11-22\20191122_MP2_R02_RunDriftingGratingsR01_g0');
cellRec{2}{1} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-12-10\20191210_MP3_RunDriftingGratingsR01_g0');%(might have missed onset first stim with eye tracker)
cellRec{2}{2} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-12-11\20191211_MP3_RunDriftingGratingsR01_g0');
cellRec{2}{3} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-12-12\20191212_MP3_RunNaturalMovieR01_g0');
cellRec{2}{4} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-12-13\20191213_MP3_RunDriftingGratingsR01_g0');
cellRec{2}{5} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-12-16\20191216_MP3_RunNaturalMovieR01_g0');
cellRec{2}{6} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2019-12-17\20191217_MP3_RunDriftingGratingsR01_g0');
cellRec{3}{1} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2020-01-15\20200115_MP4_RunDriftingGratingsR01_g0');%eye-tracking bad at end
cellRec{3}{2} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR01_g0');
cellRec{3}{3} = fullfile(strDataDrivePath,'\DataNeuropixels\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR02_g0');


cellDepthCorrection{1}{1} = 100;%01
cellDepthCorrection{1}{2} = 10;%02, V1
cellDepthCorrection{1}{3} = 10;%03
cellDepthCorrection{1}{4} = 0;%04, NOT DONE
cellDepthCorrection{2}{1} = -600;%05
cellDepthCorrection{2}{2} = -350;%06, V1
cellDepthCorrection{2}{3} = -200;%07
cellDepthCorrection{2}{4} = -50;%08
cellDepthCorrection{2}{5} = -250;%09
cellDepthCorrection{2}{6} = -50;%10
cellDepthCorrection{3}{1} = 200;%11
cellDepthCorrection{3}{2} = 10;%12
cellDepthCorrection{3}{3} = 10;%13

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

%cellDepths = cellfun(@plus,cellDepths,cellDepthCorrection);

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
matRunPrePro = [1 2];
%set target path
strDataTarget = fullfile(strDataDrivePath,'DataNeuropixels');
strSecondPathAP = 'D:\NeuropixelData\';

%boolean switch
boolOnlyJson = false;
boolUseEyeTracking = true;
boolUseVisSync = true;

%% run
runPostProcessPixModule