function mmap = JoinMemMap(strFile,strFormat,boolPersistent)
	%JoinMemMap Joins existing memory mapping object
	%	mmap = JoinMemMap(strFile,strFormat,boolPersistent)
	%
	%Inputs (all optional):
	% - strFile: target container to join
	% - strFormat: class of data type in memory map (i.e., 'uint8',etc). For data transfer, set to
	%				'struct' if reading data structure; note that this will create a fake mmap object,
	%				where mmap.Data is a non-pointer hard copy of the structure. Editing this will
	%				not not change the mapped memory. Default is 'double'.
	% - boolPersistent: (default: false) applicable only when reading struct. If set to
	%				true, will not delete target file after reading.
	%
	%Outputs:
	% - mmap: memory map object
	%
	%Version history:
	%1.0 - 2022 March 21
	%	Created by Jorrit Montijn
	
	%% get defaults
	if ~exist('boolPersistent','var') || isempty(boolPersistent), boolPersistent=false;end
	if ~exist('strFormat','var') || isempty(strFormat), strFormat='double';end
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
			error([mfilename ':FileMissing'],sprintf('Specified path does not exist: %s',strPath));
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
		error([mfilename ':FileMissing'],sprintf('Specified container file does not exist: %s',strFile));
	else
		%start memory map
		if strcmp(strFormat,'struct')
			mmap = memmapfile(strFilename,'Format','uint8','Writable',true);
		else
			mmap = memmapfile(strFilename,'Format',strFormat,'Writable',true);
		end
	end
	
	%check if struct; if so, load data
	if strcmp(strFormat,'struct')
		strDataFile = char(mmap.Data(:)');
		sLoad = load(strcat(strPath,strDataFile));
		delete(strcat(strPath,strDataFile));
		clear mmap;
		mmap = struct;
		mmap.Data = sLoad;
		mmap.Name = strFile;
		if ~boolPersistent
			delete(strFilename);
		end
	end
end