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
		strExt = strrep(strExt,'meta','bin');
		
		% extract IM sync channel
		if SY>0 && isfile(fullpath(strPath,[strFile,strExt]))
			vecTypeCh = cumsum([AP,LF,SY]);
			intSyncCh = vecTypeCh(3);
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
		else
			%create dummy
			fprintf('Sync data not found: will generate dummy signals based on metadata\n');
			warning([mfilename ':SyncDataMissing'],'Sync data not found: will generate dummy signals based on metadata');
			dblSampRate = str2double(sMeta.imSampRate);
			dblRecDur = str2double(sMeta.fileTimeSecs);
			intRecSamps = dblRecDur*dblSampRate;% - str2double(sMeta.firstSample);
			boolVecSyncPulses = false(1,intRecSamps);
			dblPulseDur = str2double(sMeta.syncSourcePeriod);
			vecInjectPulses = round(1:((intRecSamps/dblRecDur)*dblPulseDur):intRecSamps);
			boolVecSyncPulses(vecInjectPulses) = true;
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
	end
end

