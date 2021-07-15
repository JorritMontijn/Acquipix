function [hMain,axes_atlas,axes_probe_areas,probe_areas_plot] = PH_GenGUI(av,tv,st,probe_vector_ccf)
	
	%bregma location
	vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
	
	% Set up the gui
	hMain = figure('Toolbar','none','Menubar','none','color','w', ...
		'Name','Atlas-probe viewer','Units','normalized','Position',[0.2,0.2,0.7,0.7]);
	
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'brainGridData.mat'));
	matBrainGrid = sLoad.brainGridData;
	sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'allen_ccf_colormap_2017.mat'));
	cmap=sLoad.cmap;
	
	bp = double(matBrainGrid);
	bp(sum(bp,2)==0,:) = NaN; % when saved to uint16, NaN's become zeros. There aren't any real vertices at (0,0,0) and it shouldn't look much different if there were
	
	% Set up the atlas axes
	axes_atlas = subplot(1,2,1);
	h = plot3(axes_atlas, bp(:,1), bp(:,2), bp(:,3), 'Color', [0 0 0 0.3]);
	set(axes_atlas, 'ZDir', 'reverse')
	hold(axes_atlas,'on');
	axis vis3d equal off manual
	view([-30,25]);
	caxis([0 300]);
	[ap_max,dv_max,ml_max] = size(tv);
	xlim([-10,ap_max+10])
	ylim([-10,ml_max+10])
	zlim([-10,dv_max+10])
	h = rotate3d(axes_atlas);
	h.Enable = 'on';
	h.ActionPostCallback = @PH_UpdateSlice;
	
	
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
	
	% Set up the text to display coordinates
	probe_coordinates_text = uicontrol('Style','text','String','', ...
		'Units','normalized','Position',[0,0.95,1,0.05], ...
		'BackgroundColor','w','HorizontalAlignment','left','FontSize',12);
	
	%% assign values to structure
	
	% Set the current axes to the atlas (dirty, but some gca requirements)
	axes(axes_atlas);
	
	%build gui data
	sGUI=struct;
	sGUI.probe_vector_ccf = probe_vector_ccf;
	sGUI.tv = tv;
	sGUI.av = av;
	sGUI.st = st;
	sGUI.cmap = colormap(axes_probe_areas); % Atlas colormap
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
	sGUI.probe_ref_line = []; % Probe reference line on 3D atlas
	sGUI.handles.probe_line = line([-100 -200],[-100 -200],[-100 -200],'Color','b'); % placeholder
	sGUI.handles.probe_intersect = scatter3(-100,-100,-100,100,'rx','linewidth',2);
	sGUI.handles.probe_areas_plot = probe_areas_plot; % Color-coded probe regions
	sGUI.probe_coordinates_text = probe_coordinates_text; % Probe coordinates text
	
	% Set functions for key presses
	hManager = uigetmodemanager(hMain);
	[hManager.WindowListenerHandles.Enabled] = deal(false);
	set(hMain,'KeyPressFcn',@PH_KeyPress);
	%set(hMain,'KeyReleaseFcn',@PH_KeyRelease);
	
	% Upload gui_data
	guidata(hMain, sGUI);