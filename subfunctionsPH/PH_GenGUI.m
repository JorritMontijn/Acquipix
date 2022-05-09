function [hMain,hAxAtlas,hAxAreas,hAxAreasPlot,hAxZeta,hAxClusters,hAxMua] = PH_GenGUI(sAtlas,sProbeCoords,sClusters)
	%[hMain,hAxAtlas,hAxAreas,hAxAreasPlot,hAxZeta,hAxClusters,hAxMua] = PH_GenGUI(sAtlas,sProbeCoords,sClusters)
	%
	% Many parts of this GUI are copied from, modified after, and/or
	% inspired by work by Andy Peters
	% (https://github.com/petersaj/AP_histology and
	% https://github.com/cortex-lab/allenCCF)
	%
	%Probe Histology Coordinate Adjuster GUI
	%Version 1.0 [2021-07-26]
	%	Created by Jorrit Montijn
	
	%% get atlas variables
	vecBregma = sAtlas.Bregma;% bregma in paxinos coordinates (x=ML,y=AP,z=DV)
	vecVoxelSize= sAtlas.VoxelSize;% voxel size
	matBrainMesh = sAtlas.BrainMesh;
	matColorMap=sAtlas.ColorMap;
	av = sAtlas.av; %paxinos coordinates: av(x,y,z) where (x=ML,y=AP,z=DV)
	st = sAtlas.st;
	tv = sAtlas.tv;
	
	%% get probe locdata
	%probe_vector_ccf =[...
	%   862   -20   732;...AP depth ML (wrt atlas at (0,0,0))
	%   815   359   690];
	sProbeCoords = PH_ExtractProbeCoords(sProbeCoords);
	dblProbeLengthMicrons = sProbeCoords.ProbeLengthMicrons;
	dblProbeLength = sProbeCoords.ProbeLength;
	sClusters.dblProbeLength = sProbeCoords.ProbeLengthMicrons;
	
	%% Set up the gui
	%main figure
	hMain = figure('Toolbar','none','Menubar','none','color','w', ...
		'Name','Coordinate adjuster','Units','normalized','Position',[0.05,0.05,0.9,0.9],...
		'CloseRequestFcn',@PH_DeleteFcn);
	
	% Set up the atlas axes
	hAxAtlas = subplot(2,3,1);
	%vecGridColor = [0 0 0 0.3];
	vecGridColor = [0.7 0.7 0.7];
	h = plot3(hAxAtlas, matBrainMesh(:,1), matBrainMesh(:,2), matBrainMesh(:,3), 'Color', vecGridColor);
	%set(hAxAtlas, 'ZDir', 'reverse')
	hold(hAxAtlas,'on');
	axis(hAxAtlas,'vis3d','equal','manual','off','ij');
	
	view([220,30]);
	caxis([0 300]);
	[ml_max,ap_max,dv_max] = size(tv);
	xlim([-1,ap_max+1])
	ylim([-1,ml_max+1])
	zlim([-1,dv_max+1])
	h = rotate3d(hAxAtlas);
	h.Enable = 'on';
	h.ActionPostCallback = @PH_UpdateSlice;
	
	
	% Set up the probe area axes
	hAxAreas = subplot(2,3,3);
	hAxAreas.ActivePositionProperty = 'position';
	set(hAxAreas,'FontSize',11);
	yyaxis(hAxAreas,'left');
	hAxAreasPlot = image(0);
	set(hAxAreas,'XTick','','YLim',[0,dblProbeLengthMicrons],'YTick','','YColor','k','YDir','reverse');
	colormap(hAxAreas,matColorMap);
	caxis([1,size(matColorMap,1)])
	yyaxis(hAxAreas,'right');
	set(hAxAreas,'XAxisLocation','top','XTick','','YLim',[0,dblProbeLengthMicrons],'YColor','k','YDir','reverse');
	
	% Set up the probe area axes
	hAxAreas2 = subplot(2,4,8);
	hAxAreas2.ActivePositionProperty = 'position';
	set(hAxAreas2,'FontSize',11);
	yyaxis(hAxAreas2,'left');
	hAxAreasPlot2 = image(0);
	set(hAxAreas2,'XTick','','YLim',[0,dblProbeLengthMicrons],'YTick','','YColor','k','YDir','reverse');
	colormap(hAxAreas2,matColorMap);
	caxis([1,size(matColorMap,1)])
	yyaxis(hAxAreas2,'right');
	set(hAxAreas2,'XAxisLocation','top','XTick','','YLim',[0,dblProbeLengthMicrons],'YColor','k','YDir','reverse');
	
	%% ZETA
	hAxZeta = subplot(2,3,2);
	set(hAxZeta,'XAxisLocation','top','YLim',[0,dblProbeLengthMicrons],'YColor','k','YDir','reverse');
	ylabel(hAxZeta,'Depth (\mum)');
	
	%% xcorr & clusters
	hAxClusters = subplot(2,4,6);
	ylabel(hAxClusters,'Depth (\mum)');
	set(hAxClusters,'XLim',[0,dblProbeLengthMicrons],'YLim',[0,dblProbeLengthMicrons],'YColor','k','YDir','reverse');
	
	hAxMua = subplot(2,4,7);
	hAxMuaPlot=imagesc(hAxMua,magic(3));
	%ylabel(hAxMua,'Depth (\mum)');
	xlabel(hAxMua,'Depth (\mum)');
	axis(hAxMua,'equal');
	set(hAxMua,'YTickLabel','','XLim',[0,dblProbeLengthMicrons],'YLim',[0,dblProbeLengthMicrons],'YColor','k','YDir','reverse');
	
	%% Position the axes
	%set(axes_atlas,'Position',[-0.15,-0.1,1,1.2]);
	%set(axes_probe_areas,'Position',[0.7,0.45,0.03,0.5]);
	set(hAxAtlas,'Position',[-0.15,-0.1,0.8,1.2]);
	set(hAxZeta,'Position',[0.6,0.5,0.3,0.4]);
	set(hAxAreas,'Position',[0.93,0.5,0.02,0.4]);
	set(hAxClusters,'Position',[0.6,0.065,0.1,0.4]);
	set(hAxMua,'Position',[0.668,0.065,0.3,0.4]);
	set(hAxAreas2,'Position',[0.93,0.065,0.02,0.4]);
	
	% Set up the text to display coordinates
	probe_coordinates_text = uicontrol('Style','text','String','', ...
		'Units','normalized','Position',[0,0.95,1,0.05], ...
		'BackgroundColor','w','HorizontalAlignment','left','FontSize',12);
	
	%% make help button
	ptrButtonLoad = uicontrol(hMain,'Style','pushbutton','FontSize',11,...
		'String',sprintf('Help'),...
		'Units','normalized',...
		'Position',[0.95 0.95 0.03 0.03],...
		'Callback',@PH_DisplayControls);
	
	%% assign values to structure
	% Set the current axes to the atlas (dirty, but some gca requirements)
	axes(hAxAtlas);
	
	%build gui data
	sGUI=struct;
	sGUI.sProbeCoords = sProbeCoords;
	sGUI.sAtlas = sAtlas;
	sGUI.cmap = colormap(hAxAreas); % Atlas colormap
	sGUI.bregma = vecBregma; % Bregma in atlas voxels for external referencing
	sGUI.probe_length = dblProbeLength; % Length of probe in atlas voxels
	sGUI.structure_plot_idx = []; % Plotted structures
	sGUI.step_size = 1;
	
	%Store handles
	sGUI.handles.cortex_outline = matBrainMesh;
	sGUI.handles.structure_patch = []; % Plotted structures
	sGUI.handles.axes_atlas = hAxAtlas; % Axes with 3D atlas
	sGUI.handles.axes_probe_areas = hAxAreas; % Axes with probe areas
	sGUI.handles.axes_probe_areas2 = hAxAreas2; % Axes with probe areas
	sGUI.handles.slice_plot = surface('EdgeColor','none'); % Slice on 3D atlas
	sGUI.handles.slice_volume = 'av'; % The volume shown in the slice
	
	sGUI.handles.bregma = scatter3(sGUI.handles.axes_atlas,vecBregma(1),vecBregma(2),vecBregma(3),100,'g.','linewidth',1); %bregma
	sGUI.handles.probe_points = scatter3(sGUI.handles.axes_atlas,-100,-100,-100,100,'g.','linewidth',1); % will contain histology points
	sGUI.handles.probe_vector_cart = line([-100 -200],[-100 -200],[-100 -200],'Color','b'); % will contain atlas voxel-based location
	sGUI.handles.probe_tip = scatter3(sGUI.handles.axes_atlas,-100,-100,-100,100,'b.','linewidth',1); % will contain probe tip location
	sGUI.handles.probe_intersect = scatter3(sGUI.handles.axes_atlas,-100,-100,-100,100,'rx','linewidth',1); %will contain brain intersection
	sGUI.handles.probe_areas_plot = hAxAreasPlot; % Color-coded probe regions
	sGUI.handles.probe_areas_plot2 = hAxAreasPlot2; % Color-coded probe regions
	sGUI.handles.probe_xcorr = hAxMua;
	sGUI.handles.probe_xcorr_bounds = gobjects;
	sGUI.handles.probe_clust = hAxClusters;
	sGUI.handles.probe_clust_bounds = gobjects;
	sGUI.handles.probe_zeta = hAxZeta;
	sGUI.handles.probe_zeta_bounds = gobjects;
	
	sGUI.probe_coordinates_text = probe_coordinates_text; % Probe coordinates text
	sGUI.lastPress = tic;
	sGUI.boolReadyForExit = false;
	sGUI.output = [];
	
	%set slice alpha
	%alpha(sGUI.handles.slice_plot,0.65)
	
	% Set functions for key presses
	hManager = uigetmodemanager(hMain);
	[hManager.WindowListenerHandles.Enabled] = deal(false);
	set(hMain,'KeyPressFcn',@PH_KeyPress);
	%set(hMain,'KeyReleaseFcn',@PH_KeyRelease);
	
	% Upload gui_data
	guidata(hMain, sGUI);
	
	%% run initial functions
	%plot ephys
	PH_PlotProbeEphys(hAxZeta,hAxMua,hAxClusters,sClusters);
	
	%set initial position
	PH_LoadProbeLocation(hMain,sProbeCoords,sAtlas);
	
	%update angle
	%PH_UpdateProbeAngle(hMain,[0 0]);
	
	% Display the first slice and update the probe position
	%PH_UpdateSlice(hMain);
	%PH_UpdateProbeCoordinates(hMain);
	
	% Display controls
	PH_DisplayControls;
	