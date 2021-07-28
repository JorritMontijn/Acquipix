function [hMain,hAxAtlas,hAxAreas,hAxAreasPlot,hAxZeta,hAxClusters,hAxMua] = PH_GenGUI(av,tv,st,sFile)
	%[hMain,hAxAtlas,hAxAreas,hAxAreasPlot,hAxZeta,hAxClusters,hAxMua] = PH_GenGUI(av,tv,st,sFile)
	%
	% Many parts of this GUI are copied from, modified after, and/or
	% inspired by work by Andy Peters
	% (https://github.com/petersaj/AP_histology and
	% https://github.com/cortex-lab/allenCCF)
	%
	%Probe Histology Coordinate Adjuster GUI
	%Version 1.0 [2021-07-26]
	%	Created by Jorrit Montijn
	
	%% get probe locdata
	%probe_vector_ccf =[...
	%   862   -20   732;...AP depth ML (wrt atlas at (0,0,0))
	%   815   359   690];
	
	%check formats
	sProbeCoords = sFile.sProbeCoords;
	if isfield(sProbeCoords,'probe_ccf')
		%AP_histology output
		matProbeVector = sProbeCoords.probe_ccf(sProbeCoords.intProbeIdx);
	elseif isfield(sProbeCoords,'cellPoints')
		%cell array of points per probe
		matProbeVector = sProbeCoords.cellPoints{sProbeCoords.intProbeIdx};
	else
		%file not recognized
		error([mfilename ':UnknownFormat'],'Probe location file format is not recognized');
	end
	matProbePoints = matProbeVector;
	%overwrite probe location if adjusted position is present
	if isfield(sProbeCoords,'sProbeAdjusted') && isfield(sProbeCoords.sProbeAdjusted,'probe_vector')
		%this gui's output
		matProbeVector = sProbeCoords.sProbeAdjusted.probe_vector([1 3 2],:)';
	end
	
	%probe_vector_ccf =[...
	%	0   0   0;...AP depth ML (wrt atlas at (0,0,0))
	%	0   384   0];
	%vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
	%matProbeLoc = bsxfun(@plus,probe_vector_ccf,vecBregma);
	
	
	%% Set up the gui
	%bregma location
	vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
	%vecBregma = [540,570,0];% bregma in accf; [AP,DV,ML]
	%main figure
	hMain = figure('Toolbar','none','Menubar','none','color','w', ...
		'Name','Coordinate adjuster','Units','normalized','Position',[0.05,0.05,0.9,0.9],...
		'CloseRequestFcn',@PH_DeleteFcn);
	
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'brainGridData.mat'));
	matBrainGrid = sLoad.brainGridData;
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'allen_ccf_colormap_2017.mat'));
	cmap=sLoad.cmap;
	
	bp = double(matBrainGrid);
	bp(sum(bp,2)==0,:) = NaN; % when saved to uint16, NaN's become zeros. There aren't any real vertices at (0,0,0) and it shouldn't look much different if there were
	
	% Set up the atlas axes
	hAxAtlas = subplot(2,3,1);
	h = plot3(hAxAtlas, bp(:,1), bp(:,2), bp(:,3), 'Color', [0 0 0 0.3]);
	set(hAxAtlas, 'ZDir', 'reverse')
	hold(hAxAtlas,'on');
	axis(hAxAtlas,'vis3d','equal','manual','off');
	
	%view([-30,25]);
	caxis([0 300]);
	[ap_max,dv_max,ml_max] = size(tv);
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
	set(hAxAreas,'XTick','','YLim',[0,3840],'YTick','','YColor','k','YDir','reverse');
	colormap(hAxAreas,cmap);
	caxis([1,size(cmap,1)])
	yyaxis(hAxAreas,'right');
	set(hAxAreas,'XAxisLocation','top','XTick','','YLim',[0,3840],'YColor','k','YDir','reverse');
	
	% Set up the probe area axes
	hAxAreas2 = subplot(2,4,8);
	hAxAreas2.ActivePositionProperty = 'position';
	set(hAxAreas2,'FontSize',11);
	yyaxis(hAxAreas2,'left');
	hAxAreasPlot2 = image(0);
	set(hAxAreas2,'XTick','','YLim',[0,3840],'YTick','','YColor','k','YDir','reverse');
	colormap(hAxAreas2,cmap);
	caxis([1,size(cmap,1)])
	yyaxis(hAxAreas2,'right');
	set(hAxAreas2,'XAxisLocation','top','XTick','','YLim',[0,3840],'YColor','k','YDir','reverse');
	
	%% ZETA
	hAxZeta = subplot(2,3,2);
	set(hAxZeta,'XAxisLocation','top','YLim',[0,3840],'YColor','k','YDir','reverse');
	ylabel(hAxZeta,'Depth (\mum)');
	
	%% xcorr & clusters
	hAxClusters = subplot(2,4,6);
	ylabel(hAxClusters,'Depth (\mum)');
	set(hAxClusters,'XLim',[0,3840],'YLim',[0,3840],'YColor','k','YDir','reverse');
	
	hAxMua = subplot(2,4,7);
	hAxMuaPlot=imagesc(hAxMua,magic(3));
	%ylabel(hAxMua,'Depth (\mum)');
	xlabel(hAxMua,'Depth (\mum)');
	axis(hAxMua,'equal');
	set(hAxMua,'YTickLabel','','XLim',[0,3840],'YLim',[0,3840],'YColor','k','YDir','reverse');
	
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
	
	%% assign values to structure
	% Set the current axes to the atlas (dirty, but some gca requirements)
	axes(hAxAtlas);
	
	%build gui data
	sGUI=struct;
	sGUI.sProbeCoords = sProbeCoords;
	sGUI.probe_vector_ccf = matProbePoints;
	sGUI.tv = tv;
	sGUI.av = av;
	sGUI.st = st;
	sGUI.cmap = colormap(hAxAreas); % Atlas colormap
	sGUI.bregma = vecBregma; % Bregma for external referencing
	sGUI.probe_length = 384; % Length of probe
	sGUI.structure_plot_idx = []; % Plotted structures
	sGUI.probe_angle = [0;90]; % Probe angles in ML/DV
	sGUI.step_size = 1;
	
	%Store handles
	sGUI.handles.cortex_outline = bp;
	sGUI.handles.structure_patch = []; % Plotted structures
	sGUI.handles.axes_atlas = hAxAtlas; % Axes with 3D atlas
	sGUI.handles.axes_probe_areas = hAxAreas; % Axes with probe areas
	sGUI.handles.axes_probe_areas2 = hAxAreas2; % Axes with probe areas
	sGUI.handles.slice_plot = surface('EdgeColor','none'); % Slice on 3D atlas
	sGUI.handles.slice_volume = 'av'; % The volume shown in the slice
	sGUI.probe_ref_line = []; % Probe reference line on 3D atlas
	sGUI.handles.probe_points = scatter3(-100,-100,-100,100,'g.','linewidth',1); % placeholder
	sGUI.handles.probe_line = line([-100 -200],[-100 -200],[-100 -200],'Color','b'); % placeholder
	sGUI.handles.probe_intersect = scatter3(-100,-100,-100,100,'rx','linewidth',2);
	sGUI.handles.probe_areas_plot = hAxAreasPlot; % Color-coded probe regions
	sGUI.handles.probe_areas_plot2 = hAxAreasPlot2; % Color-coded probe regions
	sGUI.handles.probe_intersect = scatter3(-100,-100,-100,100,'rx','linewidth',2);
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
	alpha(sGUI.handles.slice_plot,0.65)
	
	% Set functions for key presses
	hManager = uigetmodemanager(hMain);
	[hManager.WindowListenerHandles.Enabled] = deal(false);
	set(hMain,'KeyPressFcn',@PH_KeyPress);
	%set(hMain,'KeyReleaseFcn',@PH_KeyRelease);
	
	% Upload gui_data
	guidata(hMain, sGUI);
	
	%% run initial functions
	%plot ephys
	PH_PlotProbeEphys(hAxZeta,hAxMua,hAxClusters,sFile);
	
	%set initial position
	PH_LoadProbeLocation(hMain,matProbeVector);
	
	%update angle
	PH_UpdateProbeAngle(hMain,[0 0]);
	
	% Display the first slice and update the probe position
	PH_UpdateSlice(hMain);
	PH_UpdateProbeCoordinates(hMain);
	
	% Display controls
	PH_DisplayControls;
	