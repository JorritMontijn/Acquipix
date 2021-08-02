function sNiCh = PP_GetNiCh(sMetaVar,sMetaNI)
	%% retrieve info
	cellFields = fieldnames(sMetaVar);
	vecNiFields = find(contains(cellFields,'niCh'));
	intSyncPulseChMv = nan;
	intStimOnsetChMv = nan;
	vecAssignedChannels = nan(1,numel(vecNiFields));
	vecProcCh = [];
	cellProcFunc = {};
	for intFieldIdx=1:numel(vecNiFields)
		strField=cellFields{vecNiFields(intFieldIdx)};
		intThisCh = str2double(strField(5:end));
		vecAssignedChannels(intFieldIdx)=intThisCh;
		if strcmp(sMetaVar.(strField),'sync')
			if ~isnan(intSyncPulseChMv)
				error([mfilename 'E:MultiSyncAssigned'],'Multiple NI channels are set to "sync", please edit your variables');
			end
			intSyncPulseChMv = intThisCh + 1; %start at 1
		elseif strcmp(sMetaVar.(strField),'onset')
			if ~isnan(intStimOnsetChMv)
				error([mfilename 'E:MultiSyncAssigned'],'Multiple NI channels are set to "onset", please edit your variables');
			end
			intStimOnsetChMv = intThisCh + 1; %start at 1
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
	intSynNiChan = str2double(sMetaNI.syncNiChan);
	intTotNiCh = sum([MN,MA,XA,DW]);
	intMaxAssigned = max(vecAssignedChannels);
	if intMaxAssigned >= intTotNiCh
		error([mfilename 'E:NiChMismatch'],sprintf('You specified niCh%d, but you recorded only %d channels. Did you forget niCh starts at 0?',intMaxAssigned,intTotNiCh));
	end
	if str2double(sMetaNI.syncSourceIdx)>0
		vecChNr = cumsum([MN,MA,XA,DW]);
		if str2double(sMetaNI.syncNiChanType)==0
			intPulseChNi = vecChNr(4) + intSynNiChan;
		elseif str2double(sMetaNI.syncNiChanType)==1
			intPulseChNi = vecChNr(3) + intSynNiChan;
		else
			error('not possible');
		end
	else
		intPulseChNi = [];
	end
	if intPulseChNi ~= intSyncPulseChMv
		error([mfilename 'E:SyncChInconsistent'],sprintf('You specified niCh%d as "sync", but the NI meta file specifies the sync pulse ch=%d',intSyncPulseChMv,intPulseChNi));
	end
	if intSyncPulseChMv == intStimOnsetChMv
		error([mfilename 'E:ChannelClash'],'Pulse and sync channels are identical');
	end
	
	%build output
	sNiCh.intSyncPulseCh = intSyncPulseChMv;
	sNiCh.intStimOnsetCh = intStimOnsetChMv;
	sNiCh.vecAssignedChannels = vecAssignedChannels;
	sNiCh.vecProcCh = vecProcCh;
	sNiCh.cellProcFunc = cellProcFunc;
	