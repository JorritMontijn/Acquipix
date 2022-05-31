function ptrListSelectAtlas_Callback(varargin)
	%get globals
	global sRP;
	global sFigRP;
	
	%load atlas
	intSelectAtlas = sFigRP.ptrListSelectAtlas.Value;
	
	%load atlas
	strAtlasName = sRP.sAtlasParams(intSelectAtlas).name;
	strPathVar = sRP.sAtlasParams(intSelectAtlas).pathvar;
	fLoader = sRP.sAtlasParams(intSelectAtlas).loader;
	
	%get path
	strAtlasPath = PF_getIniVar(strPathVar);
	
	%load & prep atlas
	sAtlas = feval(fLoader,strAtlasPath);
	if isempty(sAtlas),return;end
	if isfield(sRP.sAtlasParams(intSelectAtlas),'downsample') && ~isempty(sRP.sAtlasParams(intSelectAtlas).downsample)
		sAtlas.Downsample = round(sRP.sAtlasParams(intSelectAtlas).downsample);
	else
		sAtlas.Downsample = 1;
	end
	
	%add atlas to sRP
	sRP.sAtlas = sAtlas;
	
	%add paths
	strFullpath = which('ProbeFinder');
	strPath = fileparts(strFullpath);
	sDir=dir([strPath filesep '**' filesep]);
	%remove git folders
	sDir(contains({sDir.folder},[filesep '.git'])) = [];
	cellFolders = unique({sDir.folder});
	for intFolder=1:numel(cellFolders)
		addpath(cellFolders{intFolder});
	end
	
end