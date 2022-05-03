function sAtlas = RP_PrepABA(tv,av,st)
	
	%% get variables
	%define misc variables
	vecBregma = [540,0,570];% bregma in accf; [AP,DV,ML]
	vecVoxelSize = [10 10 10];% bregma in accf; [AP,DV,ML]
	
	%brain grid
	%sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'brainGridData.mat'));
	sLoad = load('brainGridData.mat');
	matBrainGrid = sLoad.brainGridData;
	%remove zeros
	matBrainGrid = double(matBrainGrid);
	matBrainGrid(sum(matBrainGrid,2)==0,:) = NaN;
	
	%color map
	%sLoad = load(fullfile(fileparts(mfilename('fullpath')), 'allen_ccf_colormap_2017.mat'));
	sLoad = load('allen_ccf_colormap_2017.mat');
	cmap=sLoad.cmap;
	
	%% compile outputs
	sAtlas = struct;
	sAtlas.av = av;
	sAtlas.tv = tv;
	sAtlas.st = st;
	sAtlas.Bregma = vecBregma;
	sAtlas.VoxelSize = vecVoxelSize;
	sAtlas.BrainGrid = matBrainGrid; %transform to coordinates in microns?
	sAtlas.ColorMap = cmap;
end