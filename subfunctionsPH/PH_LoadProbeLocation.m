function PH_LoadProbeLocation(probe_atlas_gui,matProbeVector,intProbeIdx)
	% Load histology points
	
	% Philip's GUI: not saved in native CCF order?
	% plot3(histology_points(:,3),histology_points(:,1),histology_points(:,2),'.b','MarkerSize',20);
	% line(P(:,3),P(:,1),P(:,2),'color','k','linewidth',2)
	
	
	% Get guidata
	sGUI = guidata(probe_atlas_gui);
	if isfield(sGUI,'probe_vector_ccf') && ~isempty(sGUI.probe_vector_ccf)
		probe_vector_ccf = sGUI.probe_vector_ccf;
	end
	
	%check inputs
	if ~exist('intProbeIdx','var') || isempty(intProbeIdx)
		intProbeIdx = 1;
	end
	
	%check if data is supplied; otherwise open file
	if ~exist('probe_vector_ccf','var') || isempty(probe_vector_ccf)
		[strFile,strPath] = uigetfile('*.mat','Select probe location file');
		if isempty(strFile) || strFile==0,return;end
		sLoad = load(fullpath(strPath,strFile));
		if isnumeric(sLoad) && (all(size(sLoad) == [3 2]) || all(size(sLoad) == [2 3]))
			probe_vector_ccf = sLoad;
		elseif isstruct(sLoad) && isfield(sLoad,'probe_vector_ccf')
			probe_vector_ccf = sLoad.probe_vector_ccf;
		else
			errordlg('This file is not a probe location file','Wrong filetype');
			return;
		end
	end
	
	%check format
	if isstruct(probe_vector_ccf) && isfield(probe_vector_ccf,'points')
		probe_vector_ccf = probe_vector_ccf(intProbeIdx).points;
	elseif iscell(probe_vector_ccf)
		probe_vector_ccf = probe_vector_ccf{intProbeIdx};
	end
	if ~exist('matProbeVector','var') || isempty(matProbeVector)
		matProbeVector = probe_vector_ccf;
	end
	
	%rotate if necessary
	%if size(probe_vector_ccf,1) == 3 && size(probe_vector_ccf,2) ~= 3
	%	probe_vector_ccf = probe_vector_ccf';
	%end
	
	%plot points
	delete(sGUI.handles.probe_points);
	sGUI.handles.probe_points = scatter3(probe_vector_ccf(:,1),probe_vector_ccf(:,3),probe_vector_ccf(:,2),20,[0 0 0.8],'.','Linewidth',1);
	
	%get vector from points
	[probe_vector,trajectory_brain_intersect,probe_ref_vector] = PH_Points2vec(matProbeVector,sGUI.av);
	
	% update gui
	set(sGUI.handles.probe_line,'XData',probe_vector(1,:), ...
		'YData',probe_vector(2,:),'ZData',probe_vector(3,:));
	sGUI.probe_ref_line=probe_ref_vector;
	guidata(probe_atlas_gui, sGUI);
	
	% Update the slice and probe coordinates
	PH_UpdateSlice(probe_atlas_gui);
	PH_UpdateProbeCoordinates(probe_atlas_gui);
	
end