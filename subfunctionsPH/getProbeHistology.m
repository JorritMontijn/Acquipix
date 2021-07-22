%get brain slice
function sProbeCoords = getProbeHistology(sFile,sRP,sFigRP)
	%imBrainSlice=Jorrit_2020_11_05_0004_1_2_s02c1_2;
	
	%load AllenCCF
	if ~isfield(sRP,'st') || isempty(sRP.st)
		try
			sRP.tv = readNPY(fullpath(sRP.strAllenCCFPath,'template_volume_10um.npy')); % grey-scale "background signal intensity"
			sRP.av = readNPY(fullpath(sRP.strAllenCCFPath,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
			sRP.st = PH_loadStructureTree(fullpath(sRP.strAllenCCFPath,'structure_tree_safe_2017.csv')); % a table of what all the labels mean
		catch ME
			strStack = sprintf('Error in %s (Line %d)',ME.stack(1).name,ME.stack(1).line);
			errordlg(sprintf('%s\n%s',ME.message,strStack),'AllenCCF load error')
			return;
		end
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
	probe_vector_ccf = sFile.sProbeCoords.probe_ccf(sFile.sProbeCoords.intProbeIdx);
	
	
	%probe_vector_ccf =[...
	%	0   0   0;...AP depth ML (wrt atlas at (0,0,0))
	%	0   384   0];
	%vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
	%matProbeLoc = bsxfun(@plus,probe_vector_ccf,vecBregma);
	
	%% plot grid
	[hMain,axes_atlas,axes_probe_areas,probe_areas_plot] = PH_GenGUI(sRP.av,sRP.tv,sRP.st,probe_vector_ccf);
	
	%set initial position
	PH_LoadProbeLocation(hMain,probe_vector_ccf);
	
	%update angle
	PH_UpdateProbeAngle(hMain,[0 0]);
	
	% Display the first slice and update the probe position
	PH_UpdateSlice(hMain);
	PH_UpdateProbeCoordinates(hMain);
	
	% Display controls
	PH_DisplayControls;
	
	%% wait until done
	boolDone = false;
	while ~boolDone
		%get data
		try
			boolDone=strcmp(hMain.BeingDeleted,'on');
		catch
			boolDone = true;
		end
		pause(0.1);
	end
	sProbeCoords = sFile.sProbeCoords;
end