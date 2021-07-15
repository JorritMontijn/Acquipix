%get brain slice

%imBrainSlice=Jorrit_2020_11_05_0004_1_2_s02c1_2;

%get allen brain atlas
if ~exist('tv','var')
strPathAllenCCF = 'D:\Data\AllenCCF\';
tv = readNPY(strcat(strPathAllenCCF,'template_volume_10um.npy')); % grey-scale "background signal intensity"
av = readNPY(strcat(strPathAllenCCF,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
st = loadStructureTree(strcat(strPathAllenCCF,'structure_tree_safe_2017.csv')); % a table of what all the labels mean

%allen_ccf_npx(tv,av,st); 
end
%{
%coronal
imagesc(squeeze(tv(600,:,:)));[AP,DV,ML]

%sagittal
imagesc(squeeze(tv(:,:,600))'); %AP=LR

%transverse
imagesc(squeeze(tv(:,600,:)))
%}
%% set probe loc
%probe_vector_ccf =[...
%   862   -20   732;...AP depth ML (wrt atlas at (0,0,0))
%   815   359   690];
probe_vector_ccf =[...
   0   0   0;...AP depth ML (wrt atlas at (0,0,0))
   0   384   0];
vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
matProbeLoc = bsxfun(@plus,probe_vector_ccf,vecBregma);

%% plot grid
[hMain,axes_atlas,axes_probe_areas,probe_areas_plot] = PH_GenGUI(av,tv,st,matProbeLoc);

%set initial position
PH_LoadProbeLocation(hMain,matProbeLoc);

% Display the first slice and update the probe position
PH_UpdateSlice(hMain);
PH_UpdateProbeCoordinates(hMain);

% Display controls
PH_DisplayControls;

%get data
sGUI = guidata(hMain);
