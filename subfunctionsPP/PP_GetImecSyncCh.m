function [boolVecSyncPulses,sMeta]=PP_GetImecSyncCh(strFullFile)
	%PP_GetImecSyncCh Loads synchronization pulse data from Imec data stream
	%   [boolVecSyncPulses,sMeta]=PP_GetImecSyncCh(strFile)
	
	%load meta file
	[strPath,strFile,strExt]=fileparts(strFullFile);
	sMeta = DP_ReadMeta(strFullFile);
	
	%load sync file if present
	sFileSyncSY = dir(fullpath([strPath filesep '**'],'syncSY.mat'));
	if isempty(sFileSyncSY)
		[AP,LF,SY] = DP_ChannelCountsIM(sMeta); %IM channels
		
		% extract IM sync channel
		if SY>0
			vecTypeCh = cumsum([AP,LF,SY]);
			intSyncCh = vecTypeCh(3);
			strExt = strrep(strExt,'meta','bin');
			vecSyncAp = -DP_ReadBin(-inf, inf, sMeta, [strFile,strExt],strPath,[],intSyncCh); %sync pulse
			syncSY = DP_GetUpDown(vecSyncAp);
			
			%save file
			strSyncSY = fullpath(strPath,'syncSY.mat');
			
			try
				save(strSyncSY, 'syncSY','sMeta','-v7.3');
			catch sME
				dispErr(sME);
			end
			sFileSyncSY = dir(strSyncSY);
		end
	end
	if ~isempty(sFileSyncSY)
		sSyncAp = load(fullpath(sFileSyncSY.folder,sFileSyncSY.name));
		boolVecSyncPulses = sSyncAp.syncSY;
		sMeta = sSyncAp.sMeta;
		
		%check SHA1 keys; _original is appended when catgt resyncs the data
		if isfield(sMeta,'fileCreateTime_original')
			strCreateTimeAp = sMeta.fileCreateTime_original;
		else
			strCreateTimeAp = sMeta.fileCreateTime;
		end
		if isfield(sMeta,'fileCreateTime_original')
			strCreateTime = sMeta.fileCreateTime_original;
		else
			strCreateTime = sMeta.fileCreateTime;
		end
		if ~strcmp(strCreateTimeAp,strCreateTime)
			error([mfilename ':FileOriginMismatch'],'Origins of meta file and sync data do not match!');
		end
	else
		boolVecSyncPulses = [];
	end
end

