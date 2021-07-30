function sClustered = getPreProClustering(sFile,sRP)
	
		
	%% get paths & files
	strTempDirSSD = sRP.strTempPath;
	strPathToConfigFile = sRP.strConfigFilePath;
	strConfigFileName = sRP.strConfigFileName;
	strDataDir = sFile.sEphysAp.folder;
	strDataFile = sFile.sEphysAp.name;
	strNiqdName = sFile.sMeta.strNidqName;
	
	%% build wait bar
	%wait bar
	ptrWaitbarHandle = waitbar(0, 'Clustering');
	ptrWaitbarHandle.Name = ['Clustering "' strNiqdName '"'];
	ptrWaitbarHandle.Children(end).Title.Interpreter = 'none';
	intStepNum = 11;
	strStep = 'Loading config...';
	intStep = 0;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	
	%% get config file data
	%get initial ops struct
	ops = struct;
	run(fullpath(strPathToConfigFile, strConfigFileName));
	
	%get chan map file
	[strChanMapPath,strChanMapFile,strChanMapExt]=fileparts(ops.chanMap);
	
	%check config params & make sure defaults for kilosort2&3 aren't used the wrong way round
	dblV = RP_AssertKilosort();
	if dblV==3 && all(ops.Th==[10 4])
		ops.Th = [9 9];
	elseif dblV==2 && all(ops.Th==[9 9])
		ops.Th = [10 4]; 
	end
	
	%% check which temp folder to use & clear data
	sTempFiles = dir(fullpath(strTempDirSSD,'*.dat'));
	for intTempFile=1:numel(sTempFiles)
		boolDir = sTempFiles(intTempFile).isdir;
		strFile = sTempFiles(intTempFile).name;
		if ~boolDir
			delete(fullpath(strTempDirSSD,strFile));
			fprintf('Deleted "%s" from temporary path "%s" [%s]\n',strFile,strTempDirSSD,getTime);
		end
	end
	cellDataBinary = strsplit(strDataFile,'.');
	strDataBinary = strjoin(cellDataBinary(1:(end-1)),'.');
	fs          = [dir(fullpath(strDataDir, [strDataBinary '.bin'])) dir(fullpath(strDataDir, [strDataBinary '.dat']))];
	objFile      = java.io.File(strTempDirSSD);
	dblFreeBytes   = objFile.getFreeSpace;
	dblFileSize = fs(1).bytes;
	fprintf('Processing "%s" (%.1fGB)\n',fs(1).name,dblFileSize/(1024.^3));
	if dblFreeBytes > (dblFileSize*1.05)
		strTempDir = strTempDirSSD;
		fprintf('Using temp dir "%s" (%.1fGB free)\n',strTempDir,dblFreeBytes/(1024.^3));
	else
		strTempDir(1) = 'D';
		fprintf('Not enough space on SSD (%.1fGB free). Using temp dir "%s"\n',dblFreeBytes/(1024.^3),strTempDir);
	end
	
	%% load SpikeGLX data and fill in some values
	strStep = 'Loading metadata...';
	intStep = 1;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	%define data
	ops.fbinary = fullpath(strDataDir, fs(1).name);
	
	%load GLX data
	%1. AP = 16-bit action potential channels
	%2. LF = 16-bit local field potential channels (some probes)
	%3. SY = The single 16-bit sync input channel (sync is bit #6)
	sMeta = DP_ReadMeta(ops.fbinary);
	ops.fs = DP_SampRate(sMeta); %sampling rate
	[AP,LF,SY] = DP_ChannelCountsIM(sMeta); %IM channels
	ops.trange = [0 Inf]; % time range to sort
	ops.NchanTOT    = AP + LF + SY; % total number of channels; is this correct?
	ops.fproc       = fullpath(strTempDir, 'temp_wh.dat'); % proc file on a fast SSD
	if isempty(strChanMapPath)
		strChanMapPath = strPathToConfigFile;
	end
	ops.chanMap = fullpath(strChanMapPath, [strChanMapFile strChanMapExt]);
	
	% is there a channel map file in this folder?
	fsCm = dir(fullfile(strDataDir, 'chan*.mat'));
	if ~isempty(fsCm)
		ops.chanMap = fullfile(strDataDir, fsCm(1).name);
	end
	
	%make output dir
	strDataOutputDir = fullpath(strDataDir, 'kilosort3');
	mkdir(strDataOutputDir);
	
	%% check NI channel information
	%retrieve sync channel from meta file and metavar structure
	sMetaNI = sFile.sMeta;
	sMetaVar = sRP.sMetaVar;
	sNiCh = PP_GetNiCh(sMetaVar,sMetaNI);
	
	%% extract IM sync channel
	strStep = 'Extracting sync channel...';
	intStep = 2;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	if SY>0
		vecTypeCh = cumsum([AP,LF,SY]);
		intSyncCh = vecTypeCh(3);
		[strPath,strFile,strExt]=fileparts(ops.fbinary);
		
		vecSyncAp = -DP_ReadBin(-inf, inf, sMeta, [strFile,strExt],strPath,[],intSyncCh); %sync pulse
		syncSY = DP_GetUpDown(vecSyncAp);
		
		%save file
		strSyncSY = fullpath(strDataOutputDir, 'syncSY.mat');
		save(strSyncSY, 'syncSY','sMeta','-v7.3');
	else
		syncSY = [];
	end
	
	%% run clustering
	sWaitbar = struct;
	sWaitbar.intStartStep = 3;
	sWaitbar.intStepNum = intStepNum;
	sWaitbar.ptrWaitbarHandle = ptrWaitbarHandle;
	%check if we want to save temp_wh to the data folder
	ops.intPermaSaveOfTempWh = sRP.intPermaSaveOfTempWh;
	if dblV==3
		rez = PP_ClusterKilosort3(ops,strDataOutputDir,sWaitbar);
	elseif dblV==2
		rez = PP_ClusterKilosort2(ops,strDataOutputDir,sWaitbar);
	end
	
	%% if you want to save the results to a Matlab file...
	% discard features in final rez file (too slow to save)
	rez.cProj = [];
	rez.cProjPC = [];
	
	% final time sorting of spikes, for apps that use st3 directly
	[~, isort]   = sortrows(rez.st3);
	rez.st3      = rez.st3(isort, :);
	
	% Ensure all GPU arrays are transferred to CPU side before saving to .mat
	rez_fields = fieldnames(rez);
	for i = 1:numel(rez_fields)
		field_name = rez_fields{i};
		if(isa(rez.(field_name), 'gpuArray'))
			rez.(field_name) = gather(rez.(field_name));
		end
	end
	%add sync channel
	rez.syncSY = syncSY;
	strStep = 'Saving rez2.mat...';
	intStep = 11;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	% save final results as rez2
	fprintf('Saving final results in rez2  \n')
	fname = fullpath(strDataOutputDir, 'rez2.mat');
	save(fname, 'rez', 'ops','-v7.3');
	
	%get clustered file
	sClustered = dir(fullpath(strDataDir,sRP.strEphysFindClustered));
	if isempty(sClustered)
		sClustered = dir(fullpath(strDataDir,'kilosort3',sRP.strEphysFindClustered));
	end
	sClustered.ops = ops;
	sClustered.sNiCh = sNiCh;
	%delete wait bar
	delete(ptrWaitbarHandle);
		