function [matTexture,vecSceneFrames] = loadStimulusTexture(sStimObject,strTexDir,sStimParams)
	%loadStimulusTexture Loads stimulus texture
	%	[vecSceneFrames,matTexture] = loadStimulusTexture(sStimObject)
	
	%% check if master file is present
	strOldPath = cd(strTexDir);
	strTexDB = 'TextureDatabase.mat';
	cellFiles = dir(strTexDB);
	if isempty(cellFiles)
		%no master file!
		warning([mfilename ':NoTexDB'],'No texture database found! Creating de novo...');
		
		%create
		cellTexDB = {};
	else
		%load
		sLoad = load(cellFiles(1).name);
		cellTexDB = sLoad.cellTexDB;
		clear sLoad;
	end
	
	%% check if stimulus is already present
	intMaxFile = size(cellTexDB,1);
	[strFile,intFile] = getStimTexDB(cellTexDB,sStimObject);
	if isempty(strFile)
		%stimulus not found; create now
		fprintf('Texture not found in database; creating now...\n');
		[vecSceneFrames,matTexture] = buildStimulusTexture(sStimObject,sStimParams);
		
		%add to database
		cellTexDB{intMaxFile+1,1} = getStimTexNewName(sStimObject,cellTexDB);
		cellTexDB{intMaxFile+1,2} = sStimObject;
		
		%save stimulus
		strFile = cellTexDB{intMaxFile+1,1};
		if ~strcmpi(strFile((end-3):end),'.mat')
			strFile = strcat(strFile,'.mat');
		end
		save(strFile,'vecSceneFrames','matTexture','sStimObject','-v7.3');
		
		%save database
		save(strTexDB,'cellTexDB');
		fprintf('Added new entry %d [%s] to texture database %s in %s\n',intMaxFile+1,cellTexDB{intMaxFile+1,1},strTexDB,strTexDir);
	else
		%stimulus found; load
		if ~strcmpi(strFile((end-3):end),'.mat')
			strFile = strcat(strFile,'.mat');
		end
		try
			sLoad = load(strFile);
			matTexture=sLoad.matTexture;
			if isfield(sLoad,'vecSceneFrames')
				vecSceneFrames=sLoad.vecSceneFrames;
			else
				vecSceneFrames = 1:size(matTexture,ndims(matTexture));
			end
		catch ME
			cellTexDB(intFile,:) = [];
			save(strTexDB,'cellTexDB');
			warning([mfilename ':RemovedEntry'],'Removed entry %d [%s] from texture database %s in %s\n',intFile,strFile,strTexDB,strTexDir);
			rethrow(ME);
		end
	end
	cd(strOldPath);
end