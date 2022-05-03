function sAtlas = RP_PrepSDA(tv,av,st)
	
	%% get variables
	%st table variables:
	% #    IDX:   Zero-based index
	% #    -R-:   Red color component (0..255)
	% #    -G-:   Green color component (0..255)
	% #    -B-:   Blue color component (0..255)
	% #    -A-:   Label transparency (0.00 .. 1.00)
	% #    VIS:   Label visibility (0 or 1)
	% #    IDX:   Label mesh visibility (0 or 1)
	% #  LABEL:   Label description
	
	%rename variables
	st.id = st.Var1;
	st.parent_structure_id = st.id;
	st.name  = st.Var8;
	
	%transform names to acronyms
	cellRemove = {', unspecified',' of ',' the ',' and ','(pre)'};
	acronym = st.name;
	%remove words
	for i=1:numel(cellRemove)
		acronym = strrep(acronym,cellRemove{i},' ');
	end
	%find start of words
	startIndex = regexpi(acronym,'(\w+|,{1}|\d+)');
	for i=1:numel(startIndex)
		acronym{i} = upper(acronym{i}(startIndex{i}));
	end
	st.acronym = acronym;
	
	%define misc variables
	%[ML,AP,DV] with dimensions 512 x 1024 x 512). The midline seems to be around ML=244
	
	%define misc variables
	%bregma in [AP,DV,ML]; c = 653, h = 440, s = 246
	vecBregma = [246,653,440];% bregma in SDA; [ML,AP,DV]
	vecVoxelSize = [39 39 39];
	
	%rat brain grid
	sLoad = load('brainGridData.mat');
	matBrainGrid = sLoad.brainGridData;
	
	%color map
	cmap=[st.Var2 st.Var3 st.Var4]./255;
	
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