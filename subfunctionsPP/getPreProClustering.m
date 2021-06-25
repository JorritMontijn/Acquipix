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
	
	%% extract sync channel
	strStep = 'Extracting sync channel...';
	intStep = 2;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	if SY>0
		vecTypeCh = cumsum([AP,LF,SY]);
		intSyncCh = vecTypeCh(3);
		[strPath,strFile,strExt]=fileparts(ops.fbinary);
		vecSyncAp = -DP_ReadBin(-inf, inf, sMeta, [strFile,strExt],strPath,[],intSyncCh); %1=PD,2=sync pulse
	else
		vecSyncAp = [];
	end
	
	%% this block runs all the steps of the algorithm
	% find the binary file
	strStep = 'Preprocessing...';
	intStep = 3;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	rez                = preprocessDataSub(ops);
	
	strStep = 'Datashift2...';
	intStep = 4;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	rez                = datashift2(rez, 1);
	
	strStep = 'Extract spikes...';
	intStep = 5;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	[rez, st3, tF]     = extract_spikes(rez);
	
	strStep = 'Template learning...';
	intStep = 6;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	rez                = template_learning(rez, tF, st3);
	
	strStep = 'Track and sort...';
	intStep = 7;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	[rez, st3, tF]     = trackAndSort(rez);
	
	strStep = 'Final clustering...';
	intStep = 8;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	rez                = final_clustering(rez, tF, st3);
	
	strStep = 'Find merges...';
	intStep = 9;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	rez                = find_merges(rez, 1);
	
	strStep = 'Exporting to phy...';
	intStep = 10;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	strDataDir = fullpath(strDataDir, 'kilosort3');
	mkdir(strDataDir)
	rezToPhy2(rez, strDataDir);
	
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
	
	strStep = 'Saving rez2.mat...';
	intStep = 11;
	waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	% save final results as rez2
	fprintf('Saving final results in rez2  \n')
	fname = fullpath(strDataDir, 'rez2.mat');
	save(fname, 'rez', 'ops','-v7.3');
	
	%get clustered file
	sClustered = dir(fullpath(strDataDir,sRP.strEphysFindClustered));
	sClustered.vecSyncAp = vecSyncAp;
	
	%delete wait bar
	delete(ptrWaitbarHandle);
		