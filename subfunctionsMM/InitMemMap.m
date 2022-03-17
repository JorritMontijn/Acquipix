function [mmap,strFilename,initData] = InitMemMap(strFile,initData)
	%InitMemMap Creates memory mapping object and fills banks with initial data
	%	[mmap,strFilename,initData] = InitMemMap(strFile,initData)
	%
	%Inputs (all optional):
	% - strFile: target file to read/create/overwrite
	% - initData: if no data are supplied and strFile exists, it will read the contents of strFile;
	%		if data are supplied, it will overwrite strFile; if no data are supplied and strFile
	%		does not exist, it will create a minimal file with the contents double(0)
	%Outputs:
	% - mmap: memory map object
	% - strFilename: file location of container
	% - initData: initial data
	
	
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
	
	%load or generate file
	if (~exist('initData','var') || isempty(initData)) && exist(strFilename,'file')
		%load data
		ptrFile = fopen(strFilename,'r');
		initData = fread(ptrFile);
		fclose(ptrFile);
	else
		%create/overwrite file
		if ~exist('initData','var')
			initData = double(1);
		end
		if isstruct(initData)
			[varFormat,initData] = FormatStructure(initData);
		else
			varFormat = class(initData);
		end
		ptrFile = fopen(strFilename,'w');
		fwrite(ptrFile,initData,varFormat);
		fclose(ptrFile);
	end
	
	%start memory map
	mmap = memmapfile(strFilename,'Format',varFormat, ...
      'Writable',true);
end
function [cellFormat,binData] = FormatStructure(struct)
	
end