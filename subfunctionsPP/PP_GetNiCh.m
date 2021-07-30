function sNiCh = PP_GetNiCh(sMetaVar,sMetaNI)
	%%
	intSynNiChan = str2double(sMetaNI.syncNiChan);
	
	cellFields = fieldnames(sMetaVar);
	vecNiFields = find(contains(cellFields,'niCh'));
	intSyncPulseCh = nan;
	intStimOnsetCh = nan;
	vecAssignedChannels = nan(1,numel(vecNiFields));
	vecProcCh = [];
	cellProcFunc = {};
	for intFieldIdx=1:numel(vecNiFields)
		strField=cellFields{vecNiFields(intFieldIdx)};
		intThisCh = str2double(strField(5:end));
		vecAssignedChannels(intFieldIdx)=intThisCh;
		if strcmp(sMetaVar.(strField),'sync')
			if ~isnan(intSyncPulseCh)
				error([mfilename 'E:MultiSyncAssigned'],'Multiple NI channels are set to "sync", please edit your variables');
			end
			intSyncPulseCh = intThisCh;
			if intSyncPulseCh ~= intSynNiChan
				error([mfilename 'E:SyncChInconsistent'],sprintf('You specified niCh%d as "sync", but the NI meta file specifies syncNiChan=%d',intSyncPulseCh,intSynNiChan));
			end
		elseif strcmp(sMetaVar.(strField),'onset')
			if ~isnan(intStimOnsetCh)
				error([mfilename 'E:MultiSyncAssigned'],'Multiple NI channels are set to "onset", please edit your variables');
			end
			intStimOnsetCh = intThisCh;
		else
			%check if function exists
			strFunc = sMetaVar.(strField);
			if strcmp(strFunc(1),'@'),strFunc(1)=[];end
			if exist(strFunc,'file') ~= 2
				error([mfilename 'E:FunctionNotFound'],sprintf('You specified data transformer "%s" for niCh%d, but it does not exist: please edit your variables',strFunc,intThisCh));
			end
			%add
			vecProcCh(end+1) = intThisCh;
			cellProcFunc{end+1} = strFunc;
		end
	end
	%check if channel numbers match
	[MN,MA,XA,DW] = DP_ChannelCountsNI(sMetaNI);
	intTotNiCh = sum([MN,MA,XA,DW]);
	intMaxAssigned = max(vecAssignedChannels);
	if intMaxAssigned >= intTotNiCh
		error([mfilename 'E:NiChMismatch'],sprintf('You specified niCh%d, but you recorded only %d channels. Did you forget niCh starts at 0?',intMaxAssigned,intTotNiCh));
	end
	
	%build output
	sNiCh.intSyncPulseCh = intSyncPulseCh;
	sNiCh.intStimOnsetCh = intStimOnsetCh;
	sNiCh.vecAssignedChannels = vecAssignedChannels;
	sNiCh.vecProcCh = vecProcCh;
	sNiCh.cellProcFunc = cellProcFunc;
	