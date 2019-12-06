%% Slice Histology Alignment, Registration, and Probe Track analysis (SHARP-Track)
strPathAllenCCF = 'D:\Downloads\AllenCCF\';
tv = readNPY(strcat(strPathAllenCCF,'template_volume_10um.npy')); % grey-scale "background signal intensity"
av = readNPY(strcat(strPathAllenCCF,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
st = loadStructureTree(strcat(strPathAllenCCF,'structure_tree_safe_2017.csv')); % a table of what all the labels mean

allen_ccf_npx(tv,av,st); 

%% angle 5 degrees
%{
NOT + PM lies between (Bregma)
ML=1.4 - 1.6
AP=-2.9 - -3.15

Center: ML=1.5, AP=-3.05
%}

%% save figure
strSavePath = 'D:\_Data\TrajectoriesProbes\';
strView = 'Sagittal';
strAreas = 'PM-NOT';
strPosition = 'MLxx_APxx';
export_fig(strcat(strSavePath,strView,'_',strAreas,'_',strPosition,'.tif'));
export_fig(strcat(strSavePath,strView,'_',strAreas,'_',strPosition,'.tif'));