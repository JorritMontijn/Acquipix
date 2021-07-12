function sSynthesis = getPreProSynthesis(sFile,sRP)
	
	%% show msg
	ptrMsg = dialog('Position',[600 400 250 50],'Name','Library Compilation');
	ptrText = uicontrol('Parent',ptrMsg,...
		'Style','text',...
		'Position',[20 00 210 40],...
		'FontSize',11,...
		'String','Loading clustered data...');
	movegui(ptrMsg,'center')
	drawnow;
	
	%% get probe data
	dblInvertLeads = true;%sFile.sProbeCoords.dblInvertLeads; %is ch1 deepest?
	dblCh1DepthFromPia = 3500;%sFile.sProbeCoords.dblCh1DepthFromPia;
	
	%% get clustering data
	%load labels
	[dummy, dummy,cellDataLabels]=tsvread(fullpath(sFile.sClustered.folder,'cluster_KSlabel.tsv'));
	vecClustIdx_KSG = cellfun(@str2double,cellDataLabels(2:end,1));
	vecKilosortGood = contains(cellDataLabels(2:end,2),'good');
	%load contam
	[dummy, dummy,cellDataContam]=tsvread(fullpath(sFile.sClustered.folder,'cluster_ContamPct.tsv'));
	vecClustIdx_KSC = cellfun(@str2double,cellDataContam(2:end,1));
	vecKilosortContamination = cellfun(@str2double,cellDataContam(2:end,2));
	%get channel mapping
	vecChanIdx = readNPY(fullpath(sFile.sClustered.folder,'channel_map.npy'));
	matChanPos = readNPY(fullpath(sFile.sClustered.folder,'channel_positions.npy'));
	%load sync file if present
	sFileSyncSY = dir(fullpath(sFile.sClustered.folder,'syncSY.mat'));
	if ~isempty(sFileSyncSY)
		sSyncAp = load(fullpath(sFile.sClustered.folder,'syncSY.mat'));
		syncSY = sSyncAp.syncSY;
		sMetaAp = sSyncAp.sMeta;
		%check SHA1 keys
		if ~strcmp(sMetaAp.fileCreateTime,sFile.sMeta.fileCreateTime)
			error([mfilename ':FileOriginMismatch'],'Origins of meta file and sync data do not match!');
		end
	else
		syncSY = [];
	end
	
	%% load eye-tracking
	if isfield(sFile,'sPupilFiles') && ~isempty(sFile.sPupilFiles)
		%msg
		ptrText.String = 'Loading pupil data...';drawnow;
		if numel(sFile.sPupilFiles) == 1
			sLoad = load(fullpath(sFile.sPupilFiles.folder,sFile.sPupilFiles.name));
			sPupil=sLoad.sPupil;
		elseif numel(sEyeFiles) > 1
			error([mfilename ':AmbiguousInput'],'Multiple video files found, please narrow search parameters');
		end
		
		% prepare pupil synchronization
		vecPupilFullSyncLum = sPupil.vecPupilFullSyncLum;
		vecPupilFullSyncLumT = sPupil.vecPupilFullSyncLumT;
		dblSampRatePupil = 1/median(diff(vecPupilFullSyncLumT));
		
		%filter to 0.1-30Hz
		vecWindow2 = [0.5 30]./dblSampRatePupil;
		[fb,fa] = butter(2,vecWindow2,'bandpass');
		vecFiltFullSyncLum = filtfilt(fb,fa, double(vecPupilFullSyncLum));
		boolPupilSync1 = vecFiltFullSyncLum>(-std(vecFiltFullSyncLum)/2);
		boolPupilSync2 = vecFiltFullSyncLum>(std(vecFiltFullSyncLum)/3);
		
		%get on/off
		vecChangePupilSync1 = diff(boolPupilSync1);
		vecChangePupilSync2 = diff(boolPupilSync2);
		vecPupilSyncOn = (find(vecChangePupilSync1 == 1 | vecChangePupilSync2 == 1)+1);
		vecPupilSyncOnT = vecPupilFullSyncLumT(vecPupilSyncOn);
	end
	
	%% load NI sync stream times
	ptrText.String = 'Loading NI & sync data...';drawnow;
	
	strPathNidq = sFile.sEphysNidq.folder;
	strFileNidq = sFile.sEphysNidq.name;
	%fprintf('Processing recording at %s%s%s [%s]\n',strPathNidq,filesep,strFileNidq,getTime);
	% Parse the corresponding metafile
	sMetaNI = sFile.sMeta;
	dblSampRateReportedNI = DP_SampRate(sMetaNI);
	intFirstSample = str2double(sMetaNI.firstSample);
	dblT0_NI = intFirstSample/dblSampRateReportedNI;
	
	% get recording configuration variables
	sMetaVar = sRP.sMetaVar;
	if isfield(sMetaVar,'syncCh') && ~isempty(sMetaVar.syncCh)
		intSyncCh = sMetaVar.syncCh; %screen diode channel
		if ischar(intSyncCh)
			intSyncCh = str2double(intSyncCh);
		end
	else
		intSyncCh = [];
	end
	%syncSourceIdx={0=None,1=External,2=NI,3+=IM}
	%syncNiChanType={0=digital,1=analog}
	%sMetaNI.syncNiChan=channel # within type
	%MN = multiplexed neural signed 16-bit channels
	%MA = multiplexed aux analog signed 16-bit channels
	%XA = non-muxed aux analog signed 16-bit channels
	%XD = non-muxed aux digital unsigned 16-bit words
	[MN,MA,XA,DW] = DP_ChannelCountsNI(sMetaNI);
	if str2double(sMetaNI.syncSourceIdx)>0
		vecChNr = cumsum([MN,MA,XA,DW]);
		if str2double(sMetaNI.syncNiChanType)==0
			intPulseCh = vecChNr(4);
		elseif str2double(sMetaNI.syncNiChanType)==1
			intPulseCh = vecChNr(3);
		else
			error('not possible');
		end
	else
		intPulseCh = [];
	end
	if intPulseCh == intSyncCh
		error([mfilename ':ChannelClash'],'Pulse and sync channels are identical');
	end
	
	% Get NI data
	%fprintf('   Loading raw data ... [%s]\n',getTime);
	matDataNI = -DP_ReadBin(-inf, inf, sMetaNI, strrep(strFileNidq,'.meta','.bin'), strPathNidq); %1=PD,2=sync pulse
	%fprintf('   Calculating sync pulses ... [%s]\n',getTime);
	if ~isempty(intSyncCh)
		vecDiodeSignal = matDataNI(intSyncCh,:);
		[boolVecScreenPhotoDiode,dblCritValPD] = DP_GetUpDown(vecDiodeSignal);
		
		%check screen on/off
		%fprintf('   Transforming screen diode flip times ... [%s]\n',getTime);
		vecChangeScreenPD = diff(boolVecScreenPhotoDiode);
		vecStimOnScreenPD = (find(vecChangeScreenPD == 1)+1);
		vecStimOffScreenPD = (find(vecChangeScreenPD == -1)+1);
		clear vecChangeScreenPD boolVecScreenPhotoDiode;
	else
		vecStimOnScreenPD = [];
	end
	%get imec sync pulses
	if ~isempty(syncSY)
		boolVecSyncPulsesImec = syncSY;
		vecChangeSyncPulsesImec = diff(boolVecSyncPulsesImec);
		vecSyncPulseOnImec = (find(vecChangeSyncPulsesImec == 1)+1);
		vecDiffPulsesImec = sort(diff(vecSyncPulseOnImec));
		intNumPulsePeriodsImec = numel(vecDiffPulsesImec);
		intOneTenthImec = ceil(intNumPulsePeriodsImec/10);
		intNineTenthImec = floor((intNumPulsePeriodsImec/10)*9);
		dblSampRateImec = mean(vecDiffPulsesImec(intOneTenthImec:intNineTenthImec));
		%compare real and pre-calibrated rate
		dblCalibratedRateImec = str2double(sMetaAp.imSampRate);
		dblImecRateError=(1-(dblSampRateImec/dblCalibratedRateImec));
		dblImecRateErrorPercentage  = dblImecRateError*100;
		%max deviation
		dblMaxFault = str2double(sMetaAp.fileTimeSecs)*dblImecRateError;
		if dblImecRateErrorPercentage < -1e-2 || dblImecRateErrorPercentage > 1e-2 || abs(dblMaxFault) > 1e-2
			warning([mfilename 'E:SampRateFault'],'IMEC stream is badly calibrated; %.4f%% error gives max fault of %.0f ms; calibrated rate is %.6f Hz, pulse-based rate is %.6f Hz!',...
				dblImecRateErrorPercentage,dblMaxFault*1000,dblCalibratedRateImec,dblSampRateImec);
		end
	elseif exist('sMetaAp','var') && isfield(sMetaAp,'imSampRate')
		dblSampRateImec = str2double(sMetaAp.imSampRate);
	else
		dblSampRateImec = 30000;
	end
	
	%get nidq sync pulses & correct by sync pulses
	if ~isempty(intPulseCh)
		%get ni sync pulses
		[boolVecSyncPulsesNidq,dblCritValSP] = DP_GetUpDown(matDataNI(intPulseCh,:));
		clear matDataNI;
		
		%realign IMEC time to NI stream
		vecChangeSyncPulses = diff(boolVecSyncPulsesNidq);
		vecSyncPulseOn = (find(vecChangeSyncPulses == 1)+1);
		clear vecChangeSyncPulses boolVecSyncPulses;
		
		%take middle 80% in case some pulses are missed or counted double
		vecDiffPulses = sort(diff(vecSyncPulseOn));
		intNumPulsePeriods = numel(vecDiffPulses);
		intOneTenth = ceil(intNumPulsePeriods/10);
		intNineTenth = floor((intNumPulsePeriods/10)*9);
		dblImecRateInNItime = mean(vecDiffPulses(intOneTenth:intNineTenth))/dblSampRateReportedNI;
		dblMultiplyIMECby = dblImecRateInNItime/str2double(sMetaNI.syncSourcePeriod);
		dblSampRateFaultPercentage = (1-(dblMultiplyIMECby))*100;
		if dblSampRateFaultPercentage < -1e-4 || dblSampRateFaultPercentage > 1e-4
			warning([mfilename 'E:SampRateFault'],sprintf('Sampling rate fault is high: %e%%. I will correct this, but your calibration is probably off!',dblSampRateFaultPercentage));
		end
	else
		warning([mfilename 'E:NoSyncPulseCh'],sprintf('No sync pulse channel found'));
	end
	
	%% load stimulus info
	%load logging file
	ptrText.String = 'Loading stimulation data...';drawnow;
	%fprintf('Synchronizing multi-stream data...\n');
	dblLastStop = 0;
	sStimFiles = sFile.sStimFiles;
	intLogs = numel(sStimFiles);
	
	% determine temporal order
	cellFiles = {sStimFiles(:).name};
	vecTimes = nan(1,intLogs);
	for intLogFile = 1:intLogs
		cellSplit = strsplit(cellFiles{intLogFile}(1:(end-4)),'_');
		cellSplit(isnan(cellfun(@str2double,cellSplit))) = [];
		cellDateTime = {cellSplit{1},cat(2,cellSplit{end-2:end})};
		sLoad = load(fullpath(sStimFiles(intLogFile).folder,sStimFiles(intLogFile).name));
		%check if timestamp is available
		if isfield(sLoad.structEP,'strStartDate') && isfield(sLoad.structEP,'strStartTime')
			cellDateTime = {sLoad.structEP.strStartDate,sLoad.structEP.strStartTime};
		elseif ~isempty(cellDateTime)
			%check if name contains time
		else
			%otherwise use time of file creation
			cellDateTime = strsplit(datestr(sStimFiles(intLogFile).date,30),'T');
		end
		%transform date+time to number
		vecTimes(intLogFile) = str2double(cat(2,cellDateTime{1},cellDateTime{2}));
	end
	[dummy,vecReorderStimFiles] = sort(vecTimes,'ascend');
	
	%% run
	intLastPupilStop = 1;
	cellStim = cell(1,intLogs);
	for intLogFile = 1:intLogs
		%% calculate stimulus times
		ptrText.String = sprintf('Aligning data streams for block %d/%d...',intLogFile,intLogs);drawnow;
		fprintf('>Log file "%s" [%s]\n',sStimFiles(vecReorderStimFiles(intLogFile)).name,getTime)
		cellStim{intLogFile} = load(fullpath(sStimFiles(vecReorderStimFiles(intLogFile)).folder,sStimFiles(vecReorderStimFiles(intLogFile)).name));
		if isfield(cellStim{intLogFile}.structEP,'strExpType')
			strStimType = cellStim{intLogFile}.structEP.strExpType;
		else %old format
			strStimType = cellStim{intLogFile}.structEP.strFile;
			cellStim{intLogFile}.structEP.strExpType = strStimType;
		end
		if isfield(cellStim{intLogFile}.structEP,'ActOnNI') && ~all(isnan(cellStim{intLogFile}.structEP.ActOnNI))
			cellStim{intLogFile}.structEP.strSyncType = 'Good: NI timestamps';
			vecStimActOnNI = cellStim{intLogFile}.structEP.ActOnNI;
			vecStimActOffNI = cellStim{intLogFile}.structEP.ActOffNI;
			fprintf('Aligned onsets using NI timestamps; start stim is at t=%.3fs\n',vecStimActOnNI(1));
		elseif isfield(cellStim{intLogFile}.structEP,'vecStimOnNI') && ~all(isnan(cellStim{intLogFile}.structEP.vecStimOnNI))
			cellStim{intLogFile}.structEP.strSyncType = 'Good: NI timestamps';
			cellStim{intLogFile}.structEP.ActOnNI = cellStim{intLogFile}.structEP.vecStimOnNI;
			cellStim{intLogFile}.structEP.ActOffNI = cellStim{intLogFile}.structEP.vecStimOffNI;
			vecStimActOnNI = cellStim{intLogFile}.structEP.vecStimOnNI;
			vecStimActOffNI = cellStim{intLogFile}.structEP.vecStimOffNI;
			fprintf('Aligned onsets using NI timestamps; start stim is at t=%.3fs\n',vecStimActOnNI(1));
		elseif ~isempty(vecStimOnScreenPD) %backup sync
			warning([mfilename ':NoTimestampsNiqd'],'No NI timestamps were found in the stimulus log; attempting back-up synchronization procedure...');
			cellStim{intLogFile}.structEP.strSyncType = 'Bad: only onset pulses';
			
			%approximate timings
			vecStimOn = vecStimOnScreenPD/dblSampRateReportedNI;
			vecStimOff = vecStimOffScreenPD/dblSampRateReportedNI;
			%remove prior entries
			vecStimOn(vecStimOn < dblLastStop) = [];
			vecStimOff(vecStimOff < dblLastStop) = [];
			%ensure identical size
			if vecStimOff(1) < vecStimOn(1),vecStimOff(1) = [];end
			if numel(vecStimOn) > numel(vecStimOff),vecStimOn(end) = [];end
			%calc dur
			vecStimDur = vecStimOff - vecStimOn;
			
			%remove all durations shorter than single frame
			vecRemStims = vecStimDur <= cellStim{intLogFile}.structEP.dblStimFrameDur;
			vecStimDur(vecRemStims) = [];
			vecStimOn(vecRemStims) = [];
			vecStimOff(vecRemStims) = [];
			
			%get real but inaccurate timings
			vecStimActOnSecs = cellStim{intLogFile}.structEP.ActOnSecs - cellStim{intLogFile}.structEP.ActOnSecs(1);
			vecStimActOffSecs = cellStim{intLogFile}.structEP.ActOffSecs - cellStim{intLogFile}.structEP.ActOnSecs(1);
			
			%go through onsets to check which one aligns with timings
			intStims = numel(vecStimOn);
			vecError = nan(1,intStims);
			for intStartStim=1:intStims
				%select onsets
				vecUseSignalOnT = vecStimOn(intStartStim:end);
				
				%get ON times
				[vecStimOnTime,vecDiffOnT] = OT_refineT(vecStimActOnSecs,vecUseSignalOnT - vecUseSignalOnT(1),inf);
				vecError(intStartStim) = nansum(vecDiffOnT.^2);
			end
			[dblMin,intStartStim] = min(vecError);
			dblStartT = vecStimOn(intStartStim);
			
			%get probability
			vecSoftmin = softmax(-vecError);
			[vecP,vecI]=findmax(vecSoftmin,10);
			dblAlignmentCertainty = vecP(1)/sum(vecP);
			fprintf('Aligned onsets with %.3f%% certainty; start stim is at t=%.3fs\n',dblAlignmentCertainty*100,dblStartT);
			%if (dblAlignmentCertainty < 0.9 || isnan(dblAlignmentCertainty)) && 0
			%	error([mfilename 'E:CheckAlignment'],'Alignment certainty is under 90%%, please check manually');
			%end
			vecSubSampled = double(vecDiodeSignal(1:100:end));
			[dblStartT,dblUserStartT] = askUserForSyncTimes(vecSubSampled,linspace(0,numel(vecSubSampled)/(dblSampRateReportedNI/100),numel(vecSubSampled)),intLogFile);
			
			%ensure same starting time
			vecStimActOnNI = vecStimActOnSecs + dblStartT;
			vecStimActOffNI = vecStimActOffSecs + dblStartT;
		else
			error([mfilename ':CannotSync'],'Timestamps and sync signals are missing: cannot synchronize data');
		end
		%remove missing stimuli
		vecRem = isnan(vecStimActOnNI) | isnan(vecStimActOffNI);
		dblLastStop = max(vecStimActOffNI);
		cellStim{intLogFile}.structEP = remStimAP(cellStim{intLogFile}.structEP,vecRem);
		
		%get ON times
		if exist('vecStimOnScreenPD','var') && ~isempty(vecStimOnScreenPD)
			dblMaxErr = 0.1;
			vecPresStimOnT = vecStimActOnNI(~vecRem) - intFirstSample/dblSampRateReportedNI;
			vecSignalOnT = vecStimOnScreenPD/dblSampRateReportedNI;
			[vecStimOnTime,vecDiffOnT] = OT_refineT(vecPresStimOnT,vecSignalOnT,inf);
			indReplace = abs(vecDiffOnT) > dblMaxErr;
			dblMedianErr = median(vecDiffOnT(~indReplace));
			if isnan(dblMedianErr),dblMedianErr=0;end
			vecStimOnTime(indReplace) = vecStimActOnNI(indReplace) - dblMedianErr - intFirstSample/dblSampRateReportedNI;
			fprintf('Average timing error is %.3fs for stimulus onsets; %d violations, %d corrected\n',mean(abs(vecDiffOnT)),sum(abs(vecDiffOnT) > dblMaxErr),sum(indReplace));
		else
			vecStimOnTime = vecStimActOnNI;
		end
		
		%get OFF times: ON + dur
		vecStimActOnSecs = cellStim{intLogFile}.structEP.ActOnSecs;
		vecStimActOffSecs = cellStim{intLogFile}.structEP.ActOffSecs;
		vecStimActDurSecs = vecStimActOffSecs - vecStimActOnSecs;
		vecStimOffTime = vecStimOnTime + vecStimActDurSecs;
		
		% save to cell array
		cellStim{intLogFile}.structEP.vecStimOnTime = vecStimOnTime;
		cellStim{intLogFile}.structEP.vecStimOffTime = vecStimOffTime;
		cellStim{intLogFile}.structEP.ActOnNI = vecStimActOnNI;
		cellStim{intLogFile}.structEP.ActOffNI = vecStimActOffNI;
		cellStim{intLogFile}.structEP.SampRateNI = dblSampRateReportedNI;
		
		%% align eye-tracking data
		%if no pupil data present, continue
		if ~exist('sPupil','var') || isempty(sPupil)
			sPupil = [];
			continue;
		end
		
		%get NI timestamp sync data
		matSyncData = sPupil.sSyncData.matSyncData;
		matSyncData(:,any(isnan(matSyncData),1)) = [];
		vecTimeVid = matSyncData(1,:); %video time in secs since recording start (t0~=0)
		vecFrameVid = matSyncData(2,:); %video frame # since video start (t0=0)
		vecTimeNI = matSyncData(3,:); %ni time in secs; corresponds to stim times
		vecFrameNI = matSyncData(4,:); %ni sample #
		dblVidT0 = vecTimeVid(1);
		
		%interpolate to NI-based time
		vecPupilTimeNI = interp1(vecFrameVid,vecTimeNI,sPupil.vecPupilVidFrame,'linear','extrap');
		sPupil.vecPupilTimeNI = vecPupilTimeNI;
		
		%% use LED
		%get pupil on/offsets
		if ~exist('intLastPupilStop','var') || isempty(intLastPupilStop)
			intLastPupilStop = 1;
		end
		
		%transform onset signals to ni time
		vecPupilSignalOnNI = interp1(vecFrameVid,vecTimeNI,vecPupilSyncOn,'linear','extrap');
		vecPupilSignalOnTime = vecPupilSignalOnNI - intFirstSample/dblSampRateReportedNI;
		
		%downsample sync lum
		vecPupilSyncLum = interp1(vecPupilFullSyncLumT,vecPupilFullSyncLum,sPupil.vecPupilTime);
		vecFiltSyncLum = interp1(vecPupilFullSyncLumT,vecFiltFullSyncLum,sPupil.vecPupilTime);
		
		%rename & align
		vecReferenceT = vecStimActOnNI;
		vecNoisyHighResT = vecPupilSignalOnNI;
		%check if pupil time overlaps NI time
		if vecReferenceT(round(numel(vecReferenceT)/3)) < vecNoisyHighResT(1) ...
				|| vecReferenceT(2*round(numel(vecReferenceT)/3)) > vecNoisyHighResT(end) 
			%insufficient overlap
			vecPupilStimOnTime = vecStimActOnNI;
			vecDiffPupilOnT = zeros(size(vecPupilStimOnTime));
			vecError = zeros(size(vecNoisyHighResT));
			vecTotErr = vecError;
			vecIntervalError = vecError;
			intStartStim=1;
			strTitle = 'Insufficient overlap';
		else
			%overlap seems fine
			[dblStartT,intFlagOut,vecTotErr] = SyncEvents(vecReferenceT,vecNoisyHighResT);
			dblInterStimT = median(diff(vecReferenceT));
			dblLowerCutOff = dblStartT-dblInterStimT;
			vecReferenceT0 = vecReferenceT - vecReferenceT(1) + dblStartT;
			[vecRefinedT,vecIntervalError] = SC_refineDiffT(vecReferenceT0,vecNoisyHighResT(vecNoisyHighResT>dblLowerCutOff));
			vecLag = vecRefinedT-vecReferenceT;
			intP10 = ceil(numel(vecLag)*(1/10));
			intP90 = floor(numel(vecLag)*(9/10));
			dblDelayInPupilSignal = mean(vecLag(intP10:intP90));
			
			
			vecPupilStimOnTime = vecStimActOnNI + dblDelayInPupilSignal;
			vecDiffPupilOnT = vecLag;
			vecError = vecTotErr;
			intStartStim=find(dblStartT==vecNoisyHighResT);
			strTitle = 'Refined /w pulses';
		end
		
		%% plot output
		hFig=figure;
		subplot(2,3,1)
		hold on
		plot(vecPupilTimeNI,vecPupilSyncLum - mean(vecPupilSyncLum));
		hold off
		xlabel('NI-based time (s)');
		ylabel('Screen signal (raw)');
		hold off;
		drawnow;fixfig(gca,[],1);
		%vecLimX = [-max(get(gca,'xlim'))/20 max(get(gca,'xlim'))];
		vecLimX1 = [min(get(gca,'xlim')) max(get(gca,'xlim'))];
		xlim(vecLimX1);
		
		subplot(2,3,2)
		hold on
		boolPupilSync = vecFiltSyncLum>(-std(vecFiltSyncLum)/2);
		plot(vecPupilTimeNI-dblT0_NI,vecFiltSyncLum./std(vecFiltSyncLum));
		plot(vecPupilTimeNI-dblT0_NI,boolPupilSync);
		hold off
		xlabel('NI-time after T0 (s)');
		ylabel('Screen signal (smoothed)');
		title(strTitle);
		drawnow;fixfig(gca,[],1);
		vecLimX = [min([get(gca,'xlim') 0]) max(get(gca,'xlim'))];
		xlim(vecLimX);
		
		subplot(2,3,3)
		hold on
		plot(vecPupilTimeNI-dblT0_NI,vecFiltSyncLum./std(vecFiltSyncLum));
		scatter(vecNoisyHighResT-dblT0_NI,1.05*ones(size(vecNoisyHighResT)),'kx');
		scatter(vecReferenceT-dblT0_NI,1.1*ones(size(vecReferenceT)),'rx');
		scatter(vecPupilStimOnTime-dblT0_NI,1.15*ones(size(vecPupilStimOnTime)),'bx');
		hold off
		xlabel('Time after T0 (s)');
		ylabel('Screen signal (smoothed)');
		title('Black=Pulses, red=NI, blue=synthesis');
		drawnow;fixfig(gca);
		xlim(vecLimX);
		
		subplot(2,3,4)
		hold on
		plot(vecError)
		scatter(intStartStim,vecTotErr(intStartStim),'bx')
		hold off
		set(gca,'yscale','log')
		title(sprintf('%s:%s; log %d',sFile.sMeta.strNidqName,sPupil.strVidFile,intLogFile),'interpreter','none');
		xlim(vecLimX);
		ylabel('Total alignment error (SSE)');
		xlabel('Synchronization event #');
		drawnow;fixfig(gca);grid off
		
		
		subplot(2,3,5)
		plot(vecDiffPupilOnT)
		ylabel('NI start - pulse start lag (s)');
		xlabel('Trial #');
		drawnow;fixfig(gca);
		
		subplot(2,3,6)
		hold on
		plot(vecIntervalError,'r')
		hold off
		title(sprintf('Error for sync event %d',intStartStim));
		ylabel('Inter-trial error (s)');
		xlabel('Inter-trial #');
		drawnow;fixfig(gca);
		maxfig;drawnow;
		
		%save output
		strSyncMetricPath = fullpath(sRP.strOutputPath,'VideoSyncMetrics');
		if ~exist(strSyncMetricPath,'dir')
			mkdir(strSyncMetricPath);
		end
		cellVidFile = strsplit(sPupil.strVidFile,'.');
		strFileOut = strcat(sFile.sMeta.strNidqName,'_',cellVidFile{1},'_Log',sprintf('%02d',intLogFile),'_SyncMetrics');
		strFileSyncMetrics1 = fullpath(strSyncMetricPath,[strFileOut,'.tif']);
		export_fig(strFileSyncMetrics1);
		strFileSyncMetrics2 = fullpath(strSyncMetricPath,[strFileOut,'.pdf']);
		export_fig(strFileSyncMetrics2);
		%pause(0.1);
		%close(hFig);
		
		%% off & save
		%get OFF times
		vecStimDur = vecStimOffTime - vecStimOnTime;
		if contains(strStimType,'NaturalMovie')
			%set offsets to movie midpoint
			vecPupilStimOffTime = vecPupilStimOnTime + vecStimDur/2;
		else
			%set offsets to onsets + duration
			vecPupilStimOffTime = vecPupilStimOnTime + vecStimDur;
		end
		intLastPupilStop = find(vecPupilSyncOnT>vecPupilStimOffTime(end),1);
		
		%assign stim on/off times
		cellStim{intLogFile}.structEP.vecPupilStimOnTime = vecPupilStimOnTime;
		cellStim{intLogFile}.structEP.vecPupilStimOffTime = vecPupilStimOffTime;
	end
	
	%% load clustered data into matlab using https://github.com/cortex-lab/spikes
	%% assign cluster data
	ptrText.String = 'Assigning cluster data...';drawnow;
	% load some of the useful pieces of information from the kilosort and manual sorting results into a struct
	strPathAP = sFile.sEphysAp.folder;
	try
		sSpikes = loadKSdir(strPathAP);
	catch
		sSpikes = loadKSdir(fullpath(strPathAP,'kilosort3'));
	end
	vecAllSpikeTimes = sSpikes.st;
	vecAllSpikeClust = sSpikes.clu;
	vecClusters = unique(vecAllSpikeClust);
	
	%get channel depth from pia
	vecChannelDepth = sSpikes.ycoords;
	vecChannelDepth = vecChannelDepth - max(vecChannelDepth);
	if dblInvertLeads,vecChannelDepth = vecChannelDepth(end:-1:1);end
	vecChannelDepth = vecChannelDepth + dblCh1DepthFromPia;
	
	%get cluster data
	fprintf('Assigning spikes to clusters... [%s]\n',getTime);
	[spikeAmps, vecAllSpikeDepth] = templatePositionsAmplitudes(sSpikes.temps, sSpikes.winv, sSpikes.ycoords, sSpikes.spikeTemplates, sSpikes.tempScalingAmps);
	vecAllSpikeDepth = dblCh1DepthFromPia - vecAllSpikeDepth;
	
	%remove nans
	for intStim=1:numel(cellStim)
		matStimOnOff = [cellStim{intStim}.structEP.vecStimOnTime;cellStim{intStim}.structEP.vecStimOffTime]';
		%remove nans
		vecRem = any(isnan(matStimOnOff),2);
		matStimOnOff(vecRem,:) = [];
		cellStim{intStim}.structEP = remStimAP(cellStim{intStim}.structEP,vecRem);
	end
	
	%% prepare spiking cell array
	intClustNum = numel(vecClusters);
	cellSpikes = cell(1,intClustNum);
	vecDepth = nan(1,intClustNum);
	for intCluster=1:intClustNum
		intClustIdx = vecClusters(intCluster);
		cellSpikes{intCluster} = vecAllSpikeTimes(vecAllSpikeClust==intClustIdx)*dblMultiplyIMECby;
		vecDepth(intCluster) = mean(vecAllSpikeDepth(vecAllSpikeClust==intClustIdx));
	end
	
	%% go through clusters
	%get static vars
	sMetaVar = sRP.sMetaVar;
	strExp = sFile.sMeta.strNidqName;
	[intB,intE]=regexp(strExp,'\d{4}[-/]?(\d{2})[-/]?\d{2}');
	strRec = strrep(strrep(strExp(intB:intE),'-',''),'/','');
	if isfield(sMetaVar,'mousetype')
		strSubjectType = sMetaVar.mousetype;
	elseif isfield(sMetaVar,'subjecttype')
		strSubjectType = sMetaVar.subjecttype;
	end
	if isfield(sMetaVar,'mouse')
		strSubject = sMetaVar.mouse;
	elseif isfield(sMetaVar,'subject')
		strSubject = sMetaVar.subject;
	else
		strSubject = strExp(1:(intB-1));
	end
	
	%check if zeta is present
	try
		getZeta(1:10,[1 3 5],2,2);
		boolUseZeta = true;
	catch
		boolUseZeta = false;
	end
	
	%go through cells and stim blocks
	ptrText.String = 'Assigning metadata to clusters...';drawnow;
	sCluster = struct;
	parfor intCluster=1:intClustNum
		%get cluster idx
		intClustIdx = vecClusters(intCluster);
		vecSpikeTimes = cellSpikes{intCluster};
		sOut = getClusterQuality(vecSpikeTimes,0);
		
		%get responsiveness
		ZetaP = nan(1,numel(cellStim));
		MeanP = nan(1,numel(cellStim));
		for intStim=1:numel(cellStim)
			matStimOnOff = [cellStim{intStim}.structEP.vecStimOnTime;cellStim{intStim}.structEP.vecStimOffTime]';
			
			%get responsiveness
			dblZetaP = 1;
			dblMeanP = 1;
			if boolUseZeta
				dblUseMaxDur = nanmin(diff(matStimOnOff(:,1)));
				intResampNum = 50;
				intPlot = 0;
				intLatencyPeaks = 0;
				[dblZetaP,vecLatencies,sZETA] = getZeta(vecSpikeTimes,matStimOnOff,dblUseMaxDur,intResampNum,intPlot,intLatencyPeaks);
				dblMeanP=sZETA.dblMeanP;
				if isempty(sZETA) || ~isfield(sZETA,'dblMeanP'),continue;end
			end
			ZetaP(intStim) = dblZetaP;
			MeanP(intStim) = dblMeanP;
		end
		
		%assign to object
		sCluster(intCluster).Exp = strExp;
		sCluster(intCluster).Rec = strRec;
		sCluster(intCluster).Area = [];
		sCluster(intCluster).SubjectType = strSubjectType;
		sCluster(intCluster).Subject = strSubject;
		sCluster(intCluster).Date = getDate();
		sCluster(intCluster).Depth = vecDepth(intCluster);
		sCluster(intCluster).Cluster = intCluster;
		sCluster(intCluster).IdxClust = intClustIdx;
		sCluster(intCluster).SpikeTimes = vecSpikeTimes;
		sCluster(intCluster).NonStationarity = sOut.dblNonstationarityIndex;
		sCluster(intCluster).Violations1ms = sOut.dblViolIdx1ms;
		sCluster(intCluster).Violations2ms = sOut.dblViolIdx2ms;
		sCluster(intCluster).Contamination = vecKilosortContamination(intCluster);
		sCluster(intCluster).KilosortGood = vecKilosortGood(intCluster);
		sCluster(intCluster).ZetaP = ZetaP;
		sCluster(intCluster).MeanP = MeanP;
		
		%msg
		fprintf('Cell %d/%d, Z-p=%.3f,M-p=%.3f, Non-stat=%.3f, Viol=%.3f, Contam=%.3f [%s]\n',...
			intCluster,intClustNum,nanmin(ZetaP),nanmin(MeanP),sOut.dblNonstationarityIndex,sOut.dblViolIdx2ms,vecKilosortContamination(intCluster),getTime);
	end
	
	%% load LFP data
	%{
		strFileLFP = strcat(strRecording,'_t0.imec0.lf.bin');
		fprintf('Filtering LFP data at %s [%s]\n',strFileLFP,getTime);
		sMetaLFP = DP_ReadMeta(strFileLFP, strPathNidq);
		matLFP = DP_ReadBin(0, inf, sMetaLFP, strFileLFP, strPathNidq, 'single');

		dblSampRateLFP = DP_SampRate(sMetaLFP);
		vecTimestampsLFP = (1:size(matLFP,2))/dblSampRateLFP;

		%filter each channel
		for intCh=1:size(matLFP,1)
			%get data
			vecFiltered = double(matLFP(intCh,:));

			%filter 50Hz
			vecWindow = [49.95 50.05]./(dblSampRateLFP./2);
			[fb,fa] = butter(2,vecWindow,'stop');
			vecFiltered = filtfilt(fb,fa,vecFiltered);

			%filter to 0.01-300Hz
			vecWindow2 = [0.01 300]./(dblSampRateLFP./2);
			[fb,fa] = butter(2,vecWindow2,'bandpass');
			vecFiltered = filtfilt(fb,fa,vecFiltered);
			matLFP(intCh,:) = cast(vecFiltered,'like',matLFP);

			%calc power
			%[vecFreq,vecPower] = getPowerSpectrum(vecFiltered,dblSampRateLFP,2);
			%loglog(vecFreq(5:end-4),conv(vecPower,normpdf(-4:4,0,2),'valid'));
		end
	%}
	
	%% generate json file for library
	%define data
	ptrText.String = 'Creating synthesis & saving to file...';drawnow;
	if ~exist('strFileLFP','var'),strFileLFP='';end
	
	%required fields
	sJson = sMetaVar;
	sJson.date = strRec;
	sJson.subject = strSubject;
	sJson.id = strcat(strExp,strSubjectType,getDate());
	
	%additional fields
	if ~exist('vecKilosortGood','var'),vecKilosortGood=[];end
	sJson.experiment = strExp;
	sJson.recording = strRec; %default, will be overwritten if rec name is present
	sJson.recidx = strcat(sJson.id,strrep(getTime(),':',''));
	sJson.subjecttype = strSubjectType;
	sJson.nstims = num2str(numel(cellStim));
	sJson.stims = strjoin(cellfun(@(x) x.structEP.strExpType,cellStim,'uniformoutput',false),';');
	sJson.trials = strjoin(cellfun(@(x) num2str(numel(x.structEP.ActOnSecs)),cellStim,'uniformoutput',false),';');
	sJson.nclust = numel(vecKilosortGood);
	sJson.ngood = sum(vecKilosortGood);
	
	%check meta data
	cellFields = fieldnames(sMetaNI);
	intMetaField = find(contains(cellFields,'recording'));
	if numel(intMetaField) == 1
		sJson.recording = strjoin({sMetaNI.(cellFields{intMetaField}),cellFields{intMetaField}},'_');
	end
	
	%% combine all data and save to post-processing data file
	%build Acquipix post-processing structure
	fprintf('Combining data... [%s]\n',getTime);
	sSynthData = struct;
	strFileAp = fullpath(sRP.strOutputPath,[strcat(strExp,'_AP'),'.mat']);
	strFileSynthesis = fullpath(sFile.sEphysAp.folder,[strcat(strExp,'_Synthesis'),'.mat']);
	
	%save LFP separately because of large size
	%sAP_LFP = struct;
	%strFileOutLFP = strcat(strFileOut,'_LFP');
	%strFileLFP = strcat(strPathDataTarget,strFileOutLFP,'.mat');
	
	%LFP
	%sAP_LFP.vecTimestampsLFP = vecTimestampsLFP;
	%sAP_LFP.matLFP = matLFP;
	%sAP_LFP.sMetaLFP = sMetaLFP;
	
	%stimulation & eye-tracking timings
	sSynthData.cellStim = cellStim;
	sSynthData.sPupil = sPupil;
	
	%probe data
	sSynthData.sProbeCoords = sFile.sProbeCoords; %to do
	sSynthData.sProbeCoords.vecChanIdx = vecChanIdx;
	sSynthData.sProbeCoords.matChanPos = matChanPos;
	
	%clusters & spikes
	sSynthData.sCluster = sCluster;
	
	%NI meta file
	sSynthData.sMetaNI = sMetaNI;
	%sAP.strFileLFP = strFileLFP;
	
	%source files
	sSources = sFile;
	sSources.sMetaVar = sRP.sMetaVar;
	sSynthData.sSources = sSources;
	
	% json metadata
	%file locations
	sJson.file_ap = strFileAp;
	sJson.file_lfp = strFileLFP;
	sJson.file_ni = sMetaNI.fileName;
	%add to struct
	sSynthData.sJson = sJson;
	
	%% save synthesis
	%save AP
	fprintf('Saving synthesis to %s [%s]\n',strFileSynthesis,getTime);
	save(strFileSynthesis,'sSynthData');
	
	%% create output structure
	sSynthesis = dir(strFileSynthesis);
	
	%% delete msg
	delete(ptrMsg);
	return;
	
	%% save json
	%save LFP
	%fprintf('Saving LFP data to %s [%s]\n',strFileLFP,getTime);
	%save(strFileLFP,'sAP_LFP','-v7.3');
	%fprintf('Done\n');!
	
	%save json file
	strJsonData = jsonencode(sJson);
	strJsonFileOut = strcat(strExp,'_',strSubject,'_session.json');
	strJsonTarget = fullpath(sRP.strOutputPath,strJsonFileOut);
	fprintf('Saving json metadata to %s [%s]\n',strJsonTarget,getTime);
	ptrFile = fopen(strJsonTarget,'w');
	fprintf(ptrFile,strJsonData);
	fclose(ptrFile);
	%savejson('', sJsonTemp, strJsonTarget);
end