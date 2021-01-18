%% Slice Histology Alignment, Registration, and Probe Track analysis (SHARP-Track)
strPathAllenCCF = 'C:\Users\user4\Documents\AllenCCF\';
tv = readNPY(strcat(strPathAllenCCF,'template_volume_10um.npy')); % grey-scale "background signal intensity"
av = readNPY(strcat(strPathAllenCCF,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
st = loadStructureTree(strcat(strPathAllenCCF,'structure_tree_safe_2017.csv')); % a table of what all the labels mean

allen_ccf_npx(tv,av,st); 

%% albino: -2.88 AP

%% angle 5 degrees
%{
NOT + PM lies between (Bregma)
ML=1.4 - 1.6
AP=-2.9 - -3.15

Center: ML=1.5, AP=-3.05
%}
return
%% save figure
strSavePath = 'D:\_Data\TrajectoriesProbes\';
strView = 'Coronal';
strAreas = 'PM-NOT';
strPosition = 'Rec1-3';
export_fig(strcat(strSavePath,strView,'_',strAreas,'_',strPosition,'.tif'));
export_fig(strcat(strSavePath,strView,'_',strAreas,'_',strPosition,'.pdf'));

%%
%{
NOT is at the very anterior end of visually responsive subcortex
So assuming we're >500 microns from midline:
1) if cortex is not visual, and subcortex is not visual: we're too anterior (move 200 microns posteriorly)
2) if cortex is visual, but subcortex is not: we're too lateral (move 200 microns medially)
3) if cortex is not visual, but subcortex is: we're too posterior (move 200 microns anteriorly)
4) if both are visual, you may be correct => move anteriorly; if next (more anterior) location is subcortically non-visual you measured NOT! If it's still visual, this may instead be NOT.

1) in general, if subcortical responses are not visual, and the probe is rather medial, then we're too anterior
	=> moreover, the cortical region is retrosplenial, and we're going
	through HPF/subiculum
2) NOT should be around 2500 microns (2700 at most lateral tip), and lies 500 - 1600 microns from midline
3) NOT is mostly around -2.8 AP bregma (500 - 1500 microns)
%}