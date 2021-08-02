function [cellPoints,strFile,strPath] = PH_OpenCoordsFile(strDefaultPath,strName)
	
	%% pre-allocate output
	cellPoints = [];
	if ~exist('strName','var') || isempty(strName)
		strPrompt = 'Select probe coordinate file';
	else
		strPrompt = ['Select probe coordinate file for ' strName];
	end
	
	%% select file
	try
		strOldPath = cd(strDefaultPath);
	catch
		strOldPath = cd();
	end
	[strFile,strPath]=uigetfile('probe_ccf.mat',strPrompt);
	cd(strOldPath);
	if isempty(strFile) || (numel(strFile)==1 && strFile==0)
		return;
	end
	
	%% load
	sLoad = load(fullpath(strPath,strFile));
	if isfield(sLoad,'probe_ccf') && isstruct(sLoad.probe_ccf) && isfield(sLoad.probe_ccf,'points')
		%AP_histology
		cellPoints = {sLoad.probe_ccf.points};
	elseif isfield(sLoad,'pointList') && isstruct(sLoad.pointList) && isfield(sLoad.pointList,'pointList')
		%sharp track
		cellPoints = sLoad.pointList.pointList(:,1); %cell arrays
		
		%invert x/y
		cellPoints = cellfun(@(x) (x(:,[3 2 1])),cellPoints,'UniformOutput',false);
		
	else
		try
			error([mfilename ':FileTypeNotRecognized'],'File is of unknown format');
		catch ME
			strStack = sprintf('Error in %s (Line %d)',ME.stack(1).name,ME.stack(1).line);
			errordlg(sprintf('%s\n%s',ME.message,strStack),'Probe coord error')
			return;
		end
	end
	
	%% assume the probe is coming from above
	%sort y
	for intProbe=1:numel(cellPoints)
		matPoints = cellPoints{intProbe};
		[a,vecReorder]=sort(matPoints(:,2),'ascend');
		cellPoints{intProbe} = matPoints(vecReorder,:);
	end