function mmap = JoinMemMap(strFile)
	%InitMemMap Creates memory mapping object and fills banks with initial data
	%	mmap = InitMemMap(strFile)
	%
	%Inputs (optional):
	% - strFile: target container to join
	%Outputs:
	% - mmap: memory map object
	
	
	%% get defaults
	if ~exist('strFile','var'),strFile='';end
	sRP = RP_populateStructure();
	strDefPath = sRP.strTempPath;
	strDefName = 'datacontainer';
	strDefExt = '.mmap';
	[strPath,strName,strExt] = fileparts(strFile);
	
	%define path
	if numel(strPath) > 1 && strcmp(strPath(2),':')
		%absolute path
		if ~exist(strPath,'dir')
			error('path no exist');
		end
	else 
		strPath = fullpath(strDefPath,strPath);
	end
	
	%define file
	if isempty(strName),strName = strDefName;end
	if isempty(strExt),strExt = strDefExt;end
	strFilename = strcat(strPath,strName,strExt);
	
	%load file
	if ~exist(strFilename,'file')
		error([mfilename ':FileMissing'],'Specified container file strFile does not exist');
	else
		%start memory map
		mmap = memmapfile(strFilename,'Format','double','Writable',true);
	end
end