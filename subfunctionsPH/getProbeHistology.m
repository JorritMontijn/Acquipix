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
probe_vector_ccf =[...
   862   -20   732;...AP depth ML (wrt atlas at (0,0,0))
   815   359   690];
%corresponds to:
%-3159 AP, 1563 ML, 3305 depth, 42 degs midline, -80 horizontal
vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]

%% plot grid
sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'brainGridData.mat'));
matBrainGrid = sLoad.brainGridData;
sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'allen_ccf_colormap_2017.mat'));
cmap=sLoad.cmap;

bp = double(matBrainGrid); 
bp(sum(bp,2)==0,:) = NaN; % when saved to uint16, NaN's become zeros. There aren't any real vertices at (0,0,0) and it shouldn't look much different if there were

% Set up the atlas axes
hMain=figure;
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
h.ActionPostCallback = @update_slice;

% Set up the probe area axes
axes_probe_areas = subplot(1,2,2);
axes_probe_areas.ActivePositionProperty = 'position';
set(axes_probe_areas,'FontSize',11);
yyaxis(axes_probe_areas,'left');
probe_areas_plot = image(0);
set(axes_probe_areas,'XTick','','YLim',[0,3840],'YColor','k','YDir','reverse');
ylabel(axes_probe_areas,'Depth (\mum)');
colormap(axes_probe_areas,cmap);
caxis([1,size(cmap,1)])
yyaxis(axes_probe_areas,'right');
set(axes_probe_areas,'XTick','','YLim',[0,3840],'YColor','k','YDir','reverse');
title(axes_probe_areas,'Probe areas');

% Position the axes
set(axes_atlas,'Position',[-0.15,-0.1,1,1.2]);
set(axes_probe_areas,'Position',[0.7,0.1,0.03,0.8]);

% Set the current axes to the atlas (dirty, but some gca requirements)
axes(axes_atlas);

%build gui data
sGUI=struct;
sGUI.probe_vector_ccf = probe_vector_ccf;
sGUI.tv = tv;
sGUI.av = av;
sGUI.st = st;
sGUI.cmap = cmap; % Atlas colormap
sGUI.bregma = vecBregma; % Bregma for external referencing
sGUI.probe_length = 384; % Length of probe
sGUI.structure_plot_idx = []; % Plotted structures
sGUI.probe_angle = [0;90]; % Probe angles in ML/DV

%Store handles
sGUI.handles.cortex_outline = bp;
sGUI.handles.structure_patch = []; % Plotted structures
sGUI.handles.axes_atlas = axes_atlas; % Axes with 3D atlas
sGUI.handles.axes_probe_areas = axes_probe_areas; % Axes with probe areas
sGUI.handles.slice_plot = surface('EdgeColor','none'); % Slice on 3D atlas
sGUI.handles.slice_volume = 'av'; % The volume shown in the slice
%sGUI.handles.probe_ref_line = probe_ref_line; % Probe reference line on 3D atlas
%sGUI.handles.probe_line = probe_line; % Probe reference line on 3D atlas
%sGUI.handles.probe_areas_plot = probe_areas_plot; % Color-coded probe regions
%sGUI.probe_coordinates_text = probe_coordinates_text; % Probe coordinates text

%assign
guidata(hMain,sGUI);

%% plot probe

%% albino: -2.88 AP
dblAtlasStep=10;

%% 
vecPoint1 = (probe_vector_ccf(1,:) - vecBregma)*10; %in microns
vecPoint2 = (probe_vector_ccf(2,:) - vecBregma)*10; %in microns

%%
hBregma = scatter3(axes_atlas,vecBregma(1),vecBregma(3),vecBregma(2),'rx');
hProbe=line(axes_atlas,probe_vector_ccf(:,1), probe_vector_ccf(:,3), probe_vector_ccf(:,2), 'Color', [0 0 1]);

%%
%set top location
dblProbeStep=1;
	vecRefTop = probe_vector_ccf(1,:) - vecBregma(1:3);
	%swap coordinates because we rotate the axes
	vecRefBottom = probe_vector_ccf(2,:) - vecBregma(1:3);
	vecRefAx = vecRefTop-vecRefBottom;
	matProbeAxis = abs([vecRefTop' vecRefBottom'])/dblProbeStep;
	
	[azimuth,elevation,r] = cart2sph(vecRefAx(1),vecRefAx(2),vecRefAx(3));%AP, ML,depth (DV)
	%elevation=AP angle (z/y), azimuth=ML angle
	%x=AP, 
	%y=DV (depth)
	%z=ML
	dblAngleAP = rad2deg(elevation);
	dblAngleML = rad2deg(azimuth)+90;
	dblProbeL = r;
	
	%% get atlas coords
	dblPointsN = round(dblProbeL);
	[vecAtlasX,vecAtlasY,vecAtlasZ] = deal( ...
		linspace(probe_vector_ccf(1,1),probe_vector_ccf(2,1),dblPointsN), ...
		linspace(probe_vector_ccf(1,2),probe_vector_ccf(2,2),dblPointsN), ...
		linspace(probe_vector_ccf(1,3),probe_vector_ccf(2,3),dblPointsN));
	
	% Get brain labels across the probe and trajectory, and intersection with brain
	dblAtlasStep = 1;
	vecAreaIdx = interp3(single(av(1:dblAtlasStep:end,1:dblAtlasStep:end,1:dblAtlasStep:end)), ...
		round(vecAtlasX/dblAtlasStep),round(vecAtlasY/dblAtlasStep),round(vecAtlasZ/dblAtlasStep));
	intBrainStartIdx = find(vecAreaIdx > 1,1);
	vecLocBrainStart = ...
		[vecAtlasX(intBrainStartIdx),vecAtlasY(intBrainStartIdx),vecAtlasZ(intBrainStartIdx)];
	
	% Get position of brain intersect relative to bregma
	vecRealLoc = [round(vecLocBrainStart - vecBregma) dblAngleML dblAngleAP];
	
	%% brain intersection
	hBrainEntry = scatter3(axes_atlas,vecLocBrainStart(1),vecLocBrainStart(2),vecLocBrainStart(3),'gx');

	