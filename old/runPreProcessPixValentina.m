%% recordings
clear all;close all;
%sites

%sites
cellRec{1}{1} = 'C:\DATA_npx\fGluR3\Rec75766_2022-05-24R01_g0';
% cellRec{1}{2} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-24\20201124_Mango_RunReceptiveFieldMappingR01_g0';
% cellRec{1}{3} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-25\20201125_Mango_RunDriftingGratingsR01_g0';
% cellRec{1}{4} = 'D:\NeuropixelData\TRNinvivo\Mango\Exp2020-11-26\20201126_Mango_RunReceptiveFieldMappingR01_g0';
%which do we want to process?
matRunPre = [1 1]
   

%											0=none, 1=KS, 2=eye,3=post,4=area+depth
%% define paths
strPathKilosort2 = 'C:\Users\riguccini\Documents\GitHub\Kilosort-2.5';
strNpyMatlab = 'C:\Users\riguccini\Documents\GitHub\npy-matlab';
strTempDirSSD = 'C:\Temp';

%% run actual script
runPreProModuleNpx