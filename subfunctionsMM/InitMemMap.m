function [mmap,strFilename,initData] = InitMemMap(strFile,initData)
	%InitMemMap Creates memory mapping object and fills banks with initial data
	%	[mmap,strFilename,initData] = InitMemMap(strFile,initData)
	%
	%Inputs (all optional):
	% - strFile: target file to read/create/overwrite
	% - initData: if no data are supplied and strFile exists, it will read the contents of strFile;
	%		if data are supplied, it will overwrite strFile; if no data are supplied and strFile
	%		does not exist, it will create a minimal file with the contents double(0).
	%		Note: if you supply a struct, this will create a memory map with a file location to a
	%		.mat file that contains the struct. The struct itself is therefore not editable as mmap.
	%
	%Outputs:
	% - mmap: memory map object
	% - strFilename: file location of container
	% - initData: initial data
	%
	%Version history:
	%1.0 - 2022 March 21
	%	Created by Jorrit Montijn
	
	
	%% get defaults
	if ~exist('strFile','var'),strFile='';end
	strFile = char(strFile);
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
			%save struct data
			structData = initData;
			%create pointer to .mat file
			varFormat = 'uint8'; %ASCII
			%use 48-57, 65-90, 97-122
			vecAcceptedValues = cat(2,48:57,65:90,97:122);
			strRand = char(vecAcceptedValues(randi(numel(vecAcceptedValues),[1 10])));
			strDataFile = strcat('datacontainer_',strRand,'.mat');
			while exist(fullpath(strPath,strDataFile),'file')
				strRand = char(vecAcceptedValues(randi(numel(vecAcceptedValues),[1 10])));
				strDataFile = strcat('datacontainer_',strRand,'.mat');
			end
			initData = uint8(strDataFile);
			
			%write struct
			save(fullpath(strPath,strDataFile),'-struct','structData');
			
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