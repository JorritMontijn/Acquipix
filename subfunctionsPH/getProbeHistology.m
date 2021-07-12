%get brain slice
%{
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
%}
%% plot grid
sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'brainGridData.mat'));
matBrainGrid = sLoad.brainGridData;

bp = double(matBrainGrid); 
bp(sum(bp,2)==0,:) = NaN; % when saved to uint16, NaN's become zeros. There aren't any real vertices at (0,0,0) and it shouldn't look much different if there were

% Set up the atlas axes
axes_atlas = subplot(1,2,1);
h = plot3(axes_atlas, bp(:,1), bp(:,2), bp(:,3), 'Color', [0 0 0 0.3]);
set(axes_atlas, 'ZDir', 'reverse')
hold(axes_atlas,'on');
axis vis3d equal on manual
view([-30,25]);
caxis([0 300]);
[ap_max,dv_max,ml_max] = size(tv);
xlim([-10,ap_max+10])
ylim([-10,ml_max+10])
zlim([-10,dv_max+10])
h = rotate3d(axes_atlas);
h.Enable = 'on';

%% plot probe

%% albino: -2.88 AP
dblAtlasStep=10;
probe_vector_ccf =[...
   862   -20   732;...AP depth ML (wrt atlas at (0,0,0))
   815   359   690];
%corresponds to:
%-3159 AP, 1563 ML, 3305 depth, 42 degs midline, -80 horizontal

%% 
vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
vecPoint1 = (probe_vector_ccf(1,:) - vecBregma)*10; %in microns
vecPoint2 = (probe_vector_ccf(2,:) - vecBregma)*10; %in microns

%%
hBregma = scatter3(axes_atlas,vecBregma(1),vecBregma(3),vecBregma(2),'rx');
hProbe=line(axes_atlas,probe_vector_ccf(:,1), probe_vector_ccf(:,3), probe_vector_ccf(:,2), 'Color', [0 0 1]);
