%get brain slice
imBrainSlice=Jorrit_2020_11_05_0004_1_2_s02c1_2;

%get allen brain atlas
strPathAllenCCF = 'D:\Data\AllenCCF\';
tv = readNPY(strcat(strPathAllenCCF,'template_volume_10um.npy')); % grey-scale "background signal intensity"
av = readNPY(strcat(strPathAllenCCF,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
st = loadStructureTree(strcat(strPathAllenCCF,'structure_tree_safe_2017.csv')); % a table of what all the labels mean

allen_ccf_npx(tv,av,st); 

%coronal
imagesc(squeeze(tv(600,:,:)));

%sagittal
imagesc(squeeze(tv(:,:,600))'); %AP=LR

%transverse
imagesc(squeeze(tv(:,600,:)))