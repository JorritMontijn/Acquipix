function sSynthesis = getPreProSynthesis(sFile,sRP)
	
	%% show msg
	ptrMsg = dialog('Position',[600 400 250 50],'Name','Source synthesis','WindowStyle','normal');
	ptrText = uicontrol('Parent',ptrMsg,...
		'Style','text',...
		'Position',[20 00 210 40],...
		'FontSize',11,...
		'String','Loading clustered data...');
	movegui(ptrMsg,'center')
	drawnow;
	
	%% get clustering data
	strFolder = sFile.sClustered.folder;
	sClustTsv = loadClusterTsvs(strFolder);
	vecClustIdx = [sClustTsv.cluster_id];
	if isfield(sClustTsv,'KSLabel')
		cellKilosortLabel = {sClustTsv.KSLabel};
		vecKilosortGood = contains(cellKilosortLabel,'good');
	else
		cellKilosortLabel = cell(size(vecClustIdx));
		vecKilosortGood = contains(cellKilosortLabel,'good');
	end
	if isfield(sClustTsv,'ContamPct')
		vecKilosortContamination = cellfun(@str2double,{sClustTsv.ContamPct});
	else
		vecKilosortContamination = nan(size(vecClustIdx));
	end
	cellUsedFields = {'cluster_id','KSLabel','ContamPct'};
	cellAllFields = fieldnames(sClustTsv);
	
	%get channel mapping
	vecChanIdx = readNPY(fullpath(sFile.sClustered.folder,'channel_map.npy'));
	matChanPos = readNPY(fullpath(sFile.sClustered.folder,'channel_positions.npy'));
	
	%% load NI sync stream times
	try,ptrText.String = 'Loading NI & sync data...';drawnow;catch,end
	%paths
	strPathNidq = sFile.sEphysNidq.folder;
	strFileNidq = sFile.sEphysNidq.name;
	fprintf(' >  Aligning clocks and creating data synthesis for %s [%s]\n',...
		strFileNidq,getTime);
	
	% Parse the corresponding metafile
	strFileMetaNI = fullpath(strPathNidq,strFileNidq);
	sMetaNI = DP_ReadMeta(strFileMetaNI);
	sMetaVar = sRP.sMetaVar;
	sNiCh = PP_GetNiCh(sMetaVar,sMetaNI);
	if isfield(sNiCh,'intSyncPulseCh') && ~isempty(sNiCh.intSyncPulseCh) && ~ isnan(sNiCh.intSyncPulseCh)
		intSyncPulseCh = sNiCh.intSyncPulseCh; %synchronization pulses
	else
		intSyncPulseCh = [];
	end
	
	% Get NI data
	matDataNI = -DP_ReadBin(-inf, inf, sMetaNI, strrep(strFileNidq,'.meta','.bin'), strPathNidq); %1=PD,2=sync pulse
	intCheckSyncPulseCh = PP_FindSyncPulseCh(matDataNI);
	if isempty(intSyncPulseCh) || intSyncPulseCh ~= intCheckSyncPulseCh
		warning('Sync pulse ch from sMetaVar: %d - Most likely sync pulse ch: %d; please check your sMetaVars!',...
			intSyncPulseCh,intCheckSyncPulseCh)
	end
	[boolVecSyncPulsesNI,dblCritValSP] = DP_GetUpDown(matDataNI(intSyncPulseCh,:));
	
	%% reported NI rates
	dblRateFromMetaDataNI = DP_SampRate(sMetaNI);
	intFirstSampleNI = str2double(sMetaNI.firstSample);
	dblRecLengthNI = str2double(sMetaNI.fileTimeSecs);
	dblT0_NI_Reported = intFirstSampleNI/dblRateFromMetaDataNI;
	
	%% reported Imec AP rates
	% get metadata & sync channel data
	strImApFile = fullpath(sFile.sEphysAp.folder,sFile.sEphysAp.name);
	[boolVecSyncPulsesImAp,sMetaImAp]=PP_GetImecSyncCh(strImApFile);
	dblRateFromMetaDataImAp = DP_SampRate(sMetaImAp);
	intFirstSampleImAp = str2double(sMetaImAp.firstSample);
	dblRecLengthImAp = str2double(sMetaImAp.fileTimeSecs);
	dblT0_ImAp_Reported = intFirstSampleImAp/dblRateFromMetaDataImAp;
	
	%% calc real rate for NI
	%get NI sync pulses
	dblSampRateNI = PP_GetPulseIntervalFromBinVec(boolVecSyncPulsesNI);
	
	%compare real and pre-calibrated rate
	dblRateErrorNI=(1-(dblSampRateNI/dblRateFromMetaDataNI));
	dblRateErrorPercentageNI  = dblRateErrorNI*100;
	dblMaxFaultImAp = dblRecLengthNI*dblRateErrorNI;
	
	%corrected
	dblT0_NI_new = intFirstSampleNI/dblSampRateNI; %the true onset
	dblCorrectionFactor_NI = dblRateFromMetaDataNI/dblSampRateNI;
	fprintf('NI stream; %.4f%% error gives max fault of %.0f ms; calibrated rate is %.6f Hz, actual pulse-based rate is %.6f Hz; correcting by %.6f\n',...
		dblRateErrorPercentageNI,dblMaxFaultImAp*1000,dblRateFromMetaDataNI,dblSampRateNI,dblCorrectionFactor_NI);
	
	%% calc real rate for Imec Ap
	%get ImAp sync pulses
	dblSampRateImAp = PP_GetPulseIntervalFromBinVec(boolVecSyncPulsesImAp);
	
	%compare real and pre-calibrated rate
	dblRateErrorImAp=(1-(dblSampRateImAp/dblRateFromMetaDataImAp));
	dblRateErrorPercentageImAp  = dblRateErrorImAp*100;
	dblMaxFaultImAp = dblRecLengthImAp*dblRateErrorImAp;
	
	%corrected: will be done later on direct kilosort sampling rates
	dblT0_ImAp_new = intFirstSampleImAp/dblSampRateImAp; %the true onset
	dblCorrectionFactor_ImAp = dblRateFromMetaDataImAp/dblSampRateImAp;
	dblT0_CorrectionKilosort = dblT0_ImAp_new - dblT0_NI_new;
	
	fprintf('ImAp stream; %.4f%% error gives max fault of %.0f ms; calibrated rate is %.6f Hz, actual pulse-based rate is %.6f Hz; correcting by %.6f\n',...
		dblRateErrorPercentageImAp,dblMaxFaultImAp*1000,dblRateFromMetaDataImAp,dblSampRateImAp,dblCorrectionFactor_ImAp);
	fprintf('NI-T0 = %.3f s; ImAp-T0 = %.3f s; correcting spike times by %.1f ms\n',dblT0_NI_new,dblT0_ImAp_new,1000*dblT0_CorrectionKilosort);

	%% get stim onset channel
	if isfield(sNiCh,'intStimOnsetCh') && ~isempty(sNiCh.intStimOnsetCh) && ~ isnan(sNiCh.intStimOnsetCh)
		intStimOnsetCh = sNiCh.intStimOnsetCh; %screen diode channel
	else
		intStimOnsetCh = [];
	end
	if ~isempty(intStimOnsetCh)
		vecDiodeSignal = matDataNI(intStimOnsetCh,:);
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

	%% get variables
	%check meta data
	strExp = sFile.sMeta.strNidqName;
	[intB,intE]=regexp(strExp,'\d{4}[-/]?(\d{2})[-/]?\d{2}');
	strRec = strrep(strrep(strExp(intB:intE),'-',''),'/','');
	cellFields = fieldnames(sMetaNI);
	intMetaField = find(contains(cellFields,'recording'));
	if numel(intMetaField) == 1
		strRecName = strjoin({sMetaNI.(cellFields{intMetaField}),cellFields{intMetaField}},'_');
	else
		strRecName = strRec;
	end
	
	%get static vars
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
		cellRec = strsplit(strRecName,'_');
		strSubject = cellRec{1};
	end
	strOutputRoot = strcat(strSubject,'_',strRec);
	strAPFileOut = strcat(strOutputRoot,'_AP.mat');
	strTargetAP = fullpath(sRP.strOutputPath,strAPFileOut);
	strFileSynthesis = fullpath(sFile.sEphysAp.folder,[strcat(strExp,'_Synthesis'),'.mat']);
	if exist(strFileSynthesis,'file')
		sOldSynth = load(strFileSynthesis);
		sOldSynthData = sOldSynth.sSynthData;
	end
	
	%% process misc channels
	vecProcCh = sNiCh.vecProcCh;
	cellProcFunc = sNiCh.cellProcFunc;
	sMiscNI = struct;
	for intChIdx=1:numel(vecProcCh)
		intProcCh = vecProcCh(intChIdx);
		strFunc = cellProcFunc{intChIdx};
		if strcmp(strFunc(1),'@'),strFunc(1)=[];end
		sMiscNI.(strFunc) = feval(strFunc,matDataNI(intProcCh,:),sMetaNI);
	end
	
	%% load stimulus info
	%load logging file
	try,ptrText.String = 'Loading stimulation data...';drawnow;catch,end
	
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
	
	
	%% load eye-tracking
	if isfield(sFile,'sPupilFiles') && ~isempty(sFile.sPupilFiles)
		%msg
		try,ptrText.String = 'Loading pupil data...';drawnow;catch,end
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
		vecWindow2 = [0.5 10]./dblSampRatePupil;
		[fb,fa] = butter(2,vecWindow2,'bandpass');
		vecFiltFullSyncLum = filtfilt(fb,fa, double(vecPupilFullSyncLum));
		
		%get pupil on/off, v1
		intPupilOnOff=2;
		if intPupilOnOff ==1
			boolPupilSync1 = vecFiltFullSyncLum>(-std(vecFiltFullSyncLum)/2);
			boolPupilSync2 = vecFiltFullSyncLum>(std(vecFiltFullSyncLum)/3);
			
			%get on/off
			vecChangePupilSync1 = diff(boolPupilSync1);
			vecChangePupilSync2 = diff(boolPupilSync2);
			vecPupilSyncOn = (find(vecChangePupilSync1 == 1 | vecChangePupilSync2 == 1)+1);
		else
			%get pupil on/off, v2: same as ephys
			
			%get video sync pulses
			[boolVecSyncPulsesVideo,dblCritValSyncVid] = DP_GetUpDown(vecFiltFullSyncLum,0.33,0.99);
			
			%realign IMEC time to NI stream
			vecChangeVideoPulses = diff(boolVecSyncPulsesVideo);
			vecPupilSyncOn = (find(vecChangeVideoPulses == 1)+1);
		end
		vecPupilSyncOnT = vecPupilFullSyncLumT(vecPupilSyncOn);
	end
	
	%% run
	intLastPupilStop = 1;
	cellStim = cell(1,intLogs);
	for intLogFile = 1:intLogs
		%% calculate stimulus times
		try,ptrText.String = sprintf('Aligning data streams for block %d/%d...',intLogFile,intLogs);drawnow;catch,end
		
		fprintf('>Log file "%s" [%s]\n',sStimFiles(vecReorderStimFiles(intLogFile)).name,getTime)
		strLogPath = sStimFiles(vecReorderStimFiles(intLogFile)).folder;
		cellStim{intLogFile} = load(fullpath(strLogPath,sStimFiles(vecReorderStimFiles(intLogFile)).name));
		
		if isfield(cellStim{intLogFile}.structEP,'strExpType')
			strStimType = cellStim{intLogFile}.structEP.strExpType;
		else %old format
			strStimType = cellStim{intLogFile}.structEP.strFile;
			cellStim{intLogFile}.structEP.strExpType = strStimType;
		end
		if exist('sOldSynthData','var')
			dblT0_NI_new = intFirstSampleNI/dblSampRateNI; %the true onset
			cellStim{intLogFile}.structEP.strSyncType = sOldSynthData.cellStim{intLogFile}.structEP.strSyncType;
			vecStimActOnNI = sOldSynthData.cellStim{intLogFile}.structEP.ActOnNI;
			vecStimActOffNI = sOldSynthData.cellStim{intLogFile}.structEP.ActOffNI;
			fprintf('Aligned onsets using old synthesis file. If this is not what you want, please remove the old synthesis file first. NI timestamps; start stim is at t=%.3fs\n',vecStimActOnNI(1));
		elseif isfield(cellStim{intLogFile}.structEP,'ActOnNI') && ~all(isnan(cellStim{intLogFile}.structEP.ActOnNI))
			dblT0_NI_new = intFirstSampleNI/dblSampRateNI; %the true onset
			cellStim{intLogFile}.structEP.strSyncType = 'Good: NI timestamps';
			vecStimActOnNI = cellStim{intLogFile}.structEP.ActOnNI;
			vecStimActOffNI = cellStim{intLogFile}.structEP.ActOffNI;
			fprintf('Aligned onsets using NI timestamps; start stim is at t=%.3fs\n',vecStimActOnNI(1));
		elseif isfield(cellStim{intLogFile}.structEP,'vecStimOnNI') && ~all(isnan(cellStim{intLogFile}.structEP.vecStimOnNI))
			dblT0_NI_new = intFirstSampleNI/dblSampRateNI;
			cellStim{intLogFile}.structEP.strSyncType = 'Good: NI timestamps';
			cellStim{intLogFile}.structEP.ActOnNI = cellStim{intLogFile}.structEP.vecStimOnNI;
			cellStim{intLogFile}.structEP.ActOffNI = cellStim{intLogFile}.structEP.vecStimOffNI;
			vecStimActOnNI = cellStim{intLogFile}.structEP.vecStimOnNI;
			vecStimActOffNI = cellStim{intLogFile}.structEP.vecStimOffNI;
			fprintf('Aligned onsets using NI timestamps; start stim is at t=%.3fs\n',vecStimActOnNI(1));
		elseif ~isempty(vecStimOnScreenPD) %backup sync
			dblT0_NI_new = 0;
			warning([mfilename ':NoTimestampsNidq'],'No NI timestamps were found in the stimulus log; attempting back-up synchronization procedure...');
			cellStim{intLogFile}.structEP.strSyncType = 'Bad: only onset pulses';
			
			%approximate timings
			vecStimOn = vecStimOnScreenPD/dblSampRateNI;
			vecStimOff = vecStimOffScreenPD/dblSampRateNI;
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
			vecOnsetCorrections = nan(1,intStims);
			for intStartStim=1:intStims
				%select onsets
				vecUseSignalOnT = vecStimOn(intStartStim:end);
				
				%get ON times
				[vecStimOnTime,vecDiffOnT] = OT_refineT(vecStimActOnSecs,vecUseSignalOnT - vecUseSignalOnT(1),inf);
				vecOnsetCorrections(intStartStim) = nansum(vecDiffOnT.^2);
			end
			[dblMin,intStartStim] = min(vecOnsetCorrections);
			dblStartT = vecStimOn(intStartStim);
			
			%get probability
			vecSoftmin = softmax(-vecOnsetCorrections);
			[vecP,vecI]=findmax(vecSoftmin,10);
			dblAlignmentCertainty = vecP(1)/sum(vecP);
			fprintf('Aligned onsets with %.3f%% certainty; start stim is at t=%.3fs\n',dblAlignmentCertainty*100,dblStartT);
			if (dblAlignmentCertainty < 0.9 || isnan(dblAlignmentCertainty)) && ~isempty(vecDiodeSignal)
				vecSubSampled = double(vecDiodeSignal(1:100:end));
				[dblStartT,dblUserStartT] = askUserForSyncTimes(vecSubSampled,linspace(0,numel(vecSubSampled)/(dblSampRateNI/100),numel(vecSubSampled)),intLogFile,vecStimActOnSecs);
			end
			%ensure same starting time
			vecStimActOnNI = vecStimActOnSecs + dblStartT;
			vecStimActOffNI = vecStimActOffSecs + dblStartT;
		else
			error([mfilename ':CannotSync'],'Timestamps and sync signals are missing: cannot synchronize data');
		end
		%remove missing stimuli
		vecRem = isnan(vecStimActOnNI) | isnan(vecStimActOffNI);
		vecStimActOnNI(vecRem) = [];
		vecStimActOffNI(vecRem) = [];
		dblLastStop = max(vecStimActOffNI);
		cellStim{intLogFile}.structEP = remStimAP(cellStim{intLogFile}.structEP,vecRem);
		
		%get ON times
		if exist('sOldSynthData','var')
			vecStimOnTime = sOldSynthData.cellStim{intLogFile}.structEP.vecStimOnTime;
		elseif exist('vecStimOnScreenPD','var') && ~isempty(vecStimOnScreenPD)
			dblMaxErr = 0.1;
			vecPresStimOnT = vecStimActOnNI*dblCorrectionFactor_NI - dblT0_NI_new;
			vecTimestampSecsRaw = vecPresStimOnT;
			vecSignalOnT = vecStimOnScreenPD/dblSampRateNI;
			[vecStimOnTime,vecDiffOnT] = OT_refineT(vecPresStimOnT,vecSignalOnT,inf);
			vecTimestampSecsRefined = vecStimOnTime;
			indReplace = abs(vecDiffOnT) > dblMaxErr;
			dblMedianErr = median(vecDiffOnT(~indReplace));
			if isnan(dblMedianErr),dblMedianErr=0;end
			vecStimOnTime(indReplace) = vecPresStimOnT(indReplace) - dblMedianErr;
			vecTimestampSecsRefinedCorrected = vecStimOnTime;
			
			% plot
			strPlotRec = sStimFiles(vecReorderStimFiles(intLogFile)).name;
			hFig = PP_AlignEphys(vecDiodeSignal,dblSampRateNI,vecTimestampSecsRaw,vecTimestampSecsRefined,vecTimestampSecsRefinedCorrected,strPlotRec);
			
			%save sync output
			strSyncMetricPath = fullpath(strLogPath,'EphysSyncMetrics');
			if ~exist(strSyncMetricPath,'dir')
				mkdir(strSyncMetricPath);
			end
			cellRecFile = strsplit(strPlotRec,'.');
			strFileOut = sprintf('Log%02d_%s',intLogFile,strcat(strjoin(cellRecFile(1:(end-1)),'.')));
			strFileEphysSync1 = fullpath(strSyncMetricPath,[strFileOut,'.tif']);
			export_fig(strFileEphysSync1);
			strFileEphysSync2 = fullpath(strSyncMetricPath,[strFileOut,'.pdf']);
			export_fig(strFileEphysSync2);
			fprintf('Average timing error is %.3fs for stimulus onsets; %d/%d violations, %d/%d will be refined, %d/%d use raw NI times\n',mean(abs(vecDiffOnT)),sum(abs(vecDiffOnT) > dblMaxErr),numel(vecDiffOnT),sum(~indReplace),numel(indReplace),sum(indReplace),numel(indReplace));
			fprintf('Summary saved to %s (%s)\n',strSyncMetricPath,strFileOut);
		else
			dblMedianErr=0;
			vecStimOnTime = vecStimActOnNI*dblCorrectionFactor_NI - dblT0_NI_new; %correct with true onset and new samp rate
		end
		
		%get OFF times: ON + dur
		if isfield(cellStim{intLogFile}.structEP,'ActOnSecs')
			if all(isnan(cellStim{intLogFile}.structEP.ActOnSecs))
				vecStimActOnSecs = cellStim{intLogFile}.structEP.ActOnNI;
				vecStimActOffSecs = cellStim{intLogFile}.structEP.ActOffNI;
				vecStimActDurSecs = vecStimActOffSecs - vecStimActOnSecs;
				vecStimOffTime = vecStimOnTime + vecStimActDurSecs(~isnan(vecStimActDurSecs));	
			else
				vecStimActOnSecs = cellStim{intLogFile}.structEP.ActOnSecs;
				vecStimActOffSecs = cellStim{intLogFile}.structEP.ActOffSecs;
				vecStimActDurSecs = vecStimActOffSecs - vecStimActOnSecs;
				vecStimOffTime = vecStimOnTime + vecStimActDurSecs(~isnan(vecStimActDurSecs));
			end
		else
			vecStimActOnSecs = cellStim{intLogFile}.structEP.vecStimOnNI;
			vecStimActOffSecs = cellStim{intLogFile}.structEP.vecStimOffNI;
			vecStimActDurSecs = vecStimActOffSecs - vecStimActOnSecs;
			vecStimOffTime = vecStimOnTime + vecStimActDurSecs(~isnan(vecStimActDurSecs));
		end
		
		% save to cell array
		cellStim{intLogFile}.structEP.vecStimOnTime = vecStimOnTime;
		cellStim{intLogFile}.structEP.vecStimOffTime = vecStimOffTime;
		cellStim{intLogFile}.structEP.ActOnNI = vecStimActOnNI;
		cellStim{intLogFile}.structEP.ActOffNI = vecStimActOffNI;
		cellStim{intLogFile}.structEP.SampRateNI = dblSampRateNI;
		cellStim{intLogFile}.structEP.SampRateNI_Reported = dblRateFromMetaDataNI;
		cellStim{intLogFile}.structEP.SampRateIM = dblSampRateImAp;
		cellStim{intLogFile}.structEP.SampRateIM_Reported = dblRateFromMetaDataImAp;
		cellStim{intLogFile}.structEP.T0 = dblT0_NI_new;
		
		%% align eye-tracking data
		%if no pupil data present, continue
		if ~exist('sPupil','var') || isempty(sPupil)
			sPupil = [];
			continue;
		end
		if exist('sOldSynthData','var')
			sPupil.vecPupilTimeNI = sOldSynthData.sPupil.vecPupilTimeNI;
			sPupil.vecPupilTimeFixed = sOldSynthData.sPupil.vecPupilTimeFixed;
			
			%add to structure
			if isfield(cellStim{intLogFile}.structEP,'vecPupilOnsetCorrections')
				cellStim{intLogFile}.structEP.vecPupilOnsetCorrections = sOldSynthData.cellStim{intLogFile}.structEP.vecPupilOnsetCorrections;
			end
		else
			%downsample sync lum
			vecPupilSyncLum = interp1(vecPupilFullSyncLumT,vecPupilFullSyncLum,sPupil.vecPupilTime);
			vecFiltSyncLum = interp1(vecPupilFullSyncLumT,vecFiltFullSyncLum,sPupil.vecPupilTime);
			
			if isempty(sPupil.sSyncData)
				%generate artificial clock times
				[dblStartStimT,dblUserStartT,dblFinalStimT,dblUserFinalT] = askUserForSyncTimes(vecFiltSyncLum,sPupil.vecPupilTime,intLogFile,[]);
				fprintf('Using %.3fs as start and %.3fs as end for block %d\n',dblStartStimT,dblFinalStimT,intLogFile);
				matSyncData = nan(4,2);
				matSyncData(1,:) = [dblStartStimT dblFinalStimT];
				intT1 = find(sPupil.vecPupilTime>dblStartStimT,1);
				intT2 = find(sPupil.vecPupilTime>dblFinalStimT,1);
				matSyncData(2,:) = [sPupil.vecPupilVidFrame(intT1) sPupil.vecPupilVidFrame(intT2)];
				matSyncData(3,:) = [vecStimActOnNI(1) vecStimActOnNI(end)];
			else
				%get NI timestamp sync data
				matSyncData = sPupil.sSyncData.matSyncData;
				matSyncData(:,any(isnan(matSyncData),1)) = [];
			end
			
			%retrieve data
			vecTimeVid = matSyncData(1,:); %video time in secs since recording start (t0~=0)
			vecFrameVid = matSyncData(2,:); %video frame # since video start (t0=0)
			vecTimeNI = matSyncData(3,:)*dblCorrectionFactor_NI; %ni time in secs; corresponds to stim times
			
			%remove empty entries
			indRem = isnan(vecTimeNI) | vecTimeNI==0;
			vecTimeVid(indRem) = [];
			vecFrameVid(indRem) = [];
			vecTimeNI(indRem) = [];
			
			%interpolate to NI-based time
			vecPupilTimeNI = interp1(vecFrameVid,vecTimeNI,sPupil.vecPupilVidFrame,'linear');
			indExtrapolate = isnan(vecPupilTimeNI);
			
			%get average linear correspondance
			x=sPupil.vecPupilVidFrame(~indExtrapolate);
			y=vecPupilTimeNI(~indExtrapolate);
			p = polyfit(x,y,1);
			vecPupilTimeNI(indExtrapolate) = sPupil.vecPupilVidFrame(indExtrapolate)*p(1) + p(2);
			sPupil.vecPupilTimeNI = vecPupilTimeNI;
			sPupil.vecPupilTimeFixed = vecPupilTimeNI - dblMedianErr - dblT0_NI_new;
			
			%% use LED
			%transform onset signals to ni time
			vecPupilSignalOnNI = interp1(vecFrameVid,vecTimeNI,vecPupilSyncOn,'linear');
			indExtrapolate2 = isnan(vecPupilSignalOnNI);
			vecPupilSignalOnNI(indExtrapolate2) = vecPupilSyncOn(indExtrapolate2)*p(1) + p(2);
			
			%rename & align
			vecReferenceT = vecStimOnTime;
			vecNoisyHighResT = vecPupilSignalOnNI - dblMedianErr - dblT0_NI_new;
			%check if pupil time overlaps NI time
			if vecReferenceT(round(numel(vecReferenceT)/3)) < vecNoisyHighResT(1) ...
					|| vecReferenceT(2*round(numel(vecReferenceT)/3)) > vecNoisyHighResT(end)
				%insufficient overlap
				vecPupilOnsetCorrections = zeros(size(vecStimOnTime));
				strTitle = 'Insufficient overlap';
			else
				%correct times with LED
				intType=1;
				if intType==1
					sUserVars = struct;
					sUserVars.vecSignalVals = vecPupilSyncLum;
					sUserVars.vecSignalTime = sPupil.vecPupilTimeFixed;
					sUserVars.intBlockNr = intLogFile;
					sUserVars.strType = sStimFiles(vecReorderStimFiles(intLogFile)).name;
					[vecAlignedTime,vecRefinedT,vecError,sSyncStruct] = SC_syncSignals(vecReferenceT,vecNoisyHighResT,sUserVars);
					vecPupilOnsetCorrections = vecAlignedTime-vecReferenceT;
				else
					dblOffsetT = -0.05;
					intTrials = numel(vecStimOnTime);
					vecPupilOnsetCorrections = nan(1,intTrials);
					for intT=1:intTrials
						[vecRefT,vecTraceInTrial] = getTraceInTrial(sPupil.vecPupilTimeFixed,vecFiltSyncLum,vecReferenceT(intT)+dblOffsetT,median(diff(sPupil.vecPupilTimeFixed)),median(diff(vecStimOnTime))+dblOffsetT);
						vecRefT = vecRefT+dblOffsetT;
						[dblOnset,dblValue,dblBaseVal,dblPeakT,dblPeakVal] = getOnset(vecTraceInTrial,vecRefT);
						vecPupilOnsetCorrections(intT) = dblOnset;%+dblPrevOnset;
					end
				end
				strTitle = 'Refined /w pulses';
				
				%add to structure
				cellStim{intLogFile}.structEP.vecPupilOnsetCorrections = vecPupilOnsetCorrections;
			end
			
			%% plot output
			%calc constants
			dblFrameDur =median(diff(sPupil.vecPupilTimeFixed));
			dblStimDur  =median(diff(vecStimOnTime));
			dblSignalSd = std(vecPupilSyncLum);
			
			%plot
			hFig=figure;
			subplot(2,3,1)
			hold on
			plot(sPupil.vecPupilTimeFixed,vecPupilSyncLum - mean(vecPupilSyncLum));
			scatter(vecStimOnTime,1.1*dblSignalSd*ones(size(vecReferenceT)),'rx');
			scatter(vecStimOnTime+vecPupilOnsetCorrections,1.0*dblSignalSd*ones(size(vecStimOnTime)),'bx');
			hold off
			xlabel('NI-time after T0 (s)');
			ylabel('Sync signal (raw)');
			hold off;
			title(sFile.sMeta.strNidqName,'interpreter','none');
			drawnow;
			%vecLimX = [-max(get(gca,'xlim'))/20 max(get(gca,'xlim'))];
			vecLimX1 = [min(get(gca,'xlim')) max(get(gca,'xlim'))];
			xlim(vecLimX1);
			
			h0=subplot(2,3,2);hold on
			[vecRefT,matTraceInTrial] = getTraceInTrial(sPupil.vecPupilTimeFixed,vecFiltSyncLum,vecStimOnTime-0.5,dblFrameDur,dblStimDur);
			plot(vecRefT-0.5,matTraceInTrial);
			h0.ColorOrder = redbluepurple(numel(vecStimOnTime));
			hold off
			xlabel('Time after onset (s)');
			ylabel('Sync signal (a.u.)')
			title('Pulse alignment','interpreter','none');
			
			
			h=subplot(2,3,3);hold on
			[vecRefT,matTraceInTrial] = getTraceInTrial(sPupil.vecPupilTimeFixed,vecFiltSyncLum,vecStimOnTime+vecPupilOnsetCorrections-0.5,dblFrameDur,dblStimDur);
			plot(vecRefT-0.5,matTraceInTrial);
			h.ColorOrder = redbluepurple(numel(vecStimOnTime));
			hold off
			xlabel('Time after onset (s)');
			ylabel('Sync signal (a.u.)')
			title(strTitle,'interpreter','none');
			
			subplot(2,3,[4 5])
			hold on
			plot(sPupil.vecPupilTimeFixed,vecFiltSyncLum./std(vecFiltSyncLum));
			scatter(vecStimOnTime,1.1*ones(size(vecReferenceT)),'rx');
			scatter(vecStimOnTime+vecPupilOnsetCorrections,1.2*ones(size(vecStimOnTime)),'bx');
			hold off
			xlabel('Time after T0 (s)');
			ylabel('Sync signal (smoothed)');
			title('Red=NI, blue=refined');
			xlim([min(vecStimOnTime)-1 max(vecStimOnTime)+dblStimDur+1]);
			
			subplot(2,3,6);hold on;
			scatter(vecStimOnTime(2:end),diff(vecStimOnTime),'rx');
			scatter(vecStimOnTime(2:end)+vecPupilOnsetCorrections(2:end),diff(vecStimOnTime+vecPupilOnsetCorrections),'bx');
			xlabel('Time after T0 (s)');
			ylabel('Inter-trial duration (s)');
			title('Red=NI, blue=refined');
			maxfig;drawnow;
			
			%% save output
			strSyncMetricPath = fullpath(strLogPath,'VideoSyncMetrics');
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
		end
	end
	
	%% load clustered data into matlab using https://github.com/cortex-lab/spikes
	%% assign cluster data
	try,ptrText.String = 'Assigning cluster data...';drawnow;catch,end
	% load some of the useful pieces of information from the kilosort and manual sorting results into a struct
	strPathAP = sFile.sEphysAp.folder;
	try
		sSpikes = loadKSdir(strPathAP);
	catch
		try
			sSpikes = loadKSdir(fullpath(strPathAP,'kilosort'));
		catch
			sSpikes = loadKSdir(fullpath(strPathAP,'kilosort3'));
		end
	end
	vecAllSpikeTimes = sSpikes.st;  %spiketimes based on old samprate
	vecAllSpikeClust = sSpikes.clu;
	vecClusters = unique(vecAllSpikeClust);
	dblKilosortSampRateReported = sSpikes.sample_rate; %old samprate (rounded in kilosort output!)
	fprintf('Sampling rate from Imec AP: %.6f - Sampling rate from kilosort: %.6f\n',dblRateFromMetaDataImAp,dblKilosortSampRateReported);
	
	
	%% load chanmap file
	if isfield(sFile.sClustered,'ops') && isfield(sFile.sClustered.ops,'chanMap')
		%get customized chan map file
		strChanMapFile = sFile.sClustered.ops.chanMap;
	else
		%otherwise get default
		strPathToConfigFile = sRP.strConfigFilePath;
		strConfigFileName = sRP.strConfigFileName;
		
		% get config file data
		%get initial ops struct
		ops = struct;
		run(fullpath(strPathToConfigFile, strConfigFileName));
		strChanMapFile = ops.chanMap;
	end
	sChanMap = load(strChanMapFile);
	dblLength = range(sChanMap.ycoords) + median(diff(sort(unique(sChanMap.ycoords))));
	%invert channel depth
	sSpikes.ycoords = dblLength - sSpikes.ycoords;
	
	%% get cluster data
	fprintf('Assigning spikes to clusters... [%s]\n',getTime);
	[spikeAmps, vecAllSpikeDepth] = templatePositionsAmplitudes(sSpikes.temps, sSpikes.winv, sSpikes.ycoords, sSpikes.spikeTemplates, sSpikes.tempScalingAmps);
	[vecClustIdx_WF,matClustWaveforms] = getWaveformPerCluster(sSpikes);
		
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
	if intClustNum ~= numel(vecClustIdx_WF)
		error([mfilename ':ClustIdxMismatch'],sprintf('Cluster numbers do not match between waveforms and spikes for %s',strFileNidq));
	end
	cellSpikes = cell(1,intClustNum);
	vecDepth = nan(1,intClustNum);
	dblSampRateCorrectionKilosort = dblKilosortSampRateReported/dblSampRateImAp; %correct spiketimes with new, recalibrated rate
	for intCluster=1:intClustNum
		intClustIdx = vecClusters(intCluster);
		cellSpikes{intCluster} = dblT0_CorrectionKilosort...
			+ vecAllSpikeTimes(vecAllSpikeClust==intClustIdx)*dblSampRateCorrectionKilosort;
		vecDepth(intCluster) = mean(vecAllSpikeDepth(vecAllSpikeClust==intClustIdx));
	end
	
	%% put all sync data in struct
	sSyncData = struct;
	sSyncData.dblRateFromMetaDataNI = dblRateFromMetaDataNI;
	sSyncData.dblSampRateNI = dblSampRateNI;
	sSyncData.dblT0_NI_Reported = dblT0_NI_Reported;
	sSyncData.dblT0_NI_new = dblT0_NI_new;
	sSyncData.dblCorrectionFactor_NI = dblCorrectionFactor_NI;
	
	sSyncData.dblRateFromMetaDataNI = dblRateFromMetaDataNI;
	sSyncData.dblSampRateImAp = dblSampRateImAp;
	sSyncData.dblT0_ImAp_Reported = dblT0_ImAp_Reported;
	sSyncData.dblT0_ImAp_new = dblT0_ImAp_new;
	sSyncData.dblT0_CorrectionKilosort = dblT0_CorrectionKilosort;
	sSyncData.dblSampRateCorrectionKilosort = dblSampRateCorrectionKilosort;
	
	%% go through clusters
	%check if zeta is present
	try
		zetatest(1:10,[1 3 5],2,2);
		boolUseZeta = true;
	catch
		boolUseZeta = false;
	end
	
	%go through cells and stim blocks
	try,ptrText.String = 'Assigning metadata to clusters...';drawnow;catch,end
	sCluster = struct;
	for intCluster=1:intClustNum
		%get cluster idx
		intClustIdx = vecClusters(intCluster);
		vecSpikeTimes = cellSpikes{intCluster};
		%sOut = getClusterQuality(vecSpikeTimes,0);
		sOut.dblNonstationarityIndex = 0;
		sOut.dblViolIdx1ms = 0;
		sOut.dblViolIdx2ms = 0;
		
		%get responsiveness
		ZetaP = nan(1,numel(cellStim));
		MeanP = nan(1,numel(cellStim));
		dPrimeLR = nan(1,numel(cellStim));
		for intStim=1:numel(cellStim)
			matStimOnOff = [cellStim{intStim}.structEP.vecStimOnTime;cellStim{intStim}.structEP.vecStimOffTime]';
			
			%get responsiveness
			dblZetaP = 1;
			dblMeanP = 1;
			if boolUseZeta
				dblUseMaxDur = nanmin(diff(matStimOnOff(:,1)));
				intResampNum = 25;
				intPlot = 0;
				intLatencyPeaks = 0;
				[dblZetaP,sZETA] = zetatest(vecSpikeTimes,matStimOnOff,dblUseMaxDur,intResampNum,intPlot,intLatencyPeaks);
				dblMeanP=sZETA.dblMeanP;
				if isempty(sZETA) || ~isfield(sZETA,'dblMeanP'),continue;end
			end
			ZetaP(intStim) = dblZetaP;
			MeanP(intStim) = dblMeanP;
			
			%check if drifting grating
			if isfield(cellStim{intStim}.structEP,'Orientation') && numel(cellStim{intStim}.structEP.Orientation) == numel(cellStim{intStim}.structEP.vecStimOnTime)
				indDirRight = abs(rad2deg(circ_dist(deg2rad(cellStim{intStim}.structEP.Orientation),0))) <= 30;
				indDirLeft = abs(rad2deg(circ_dist(deg2rad(cellStim{intStim}.structEP.Orientation),180))) <= 30;
				if sum(indDirRight) > 2 && sum(indDirLeft) > 2
					vecSpikeCounts = getSpikeCounts(vecSpikeTimes,cellStim{intStim}.structEP.vecStimOnTime,cellStim{intStim}.structEP.vecStimOffTime);
					vecRate = vecSpikeCounts ./ (cellStim{intStim}.structEP.vecStimOffTime - cellStim{intStim}.structEP.vecStimOnTime);
					
					dPrimeLR(intStim) = getdprime2(vecRate(indDirRight),vecRate(indDirLeft));
				end
			end
		end
		
		%get vars for backward compatibility
		try
			dblContamP = vecKilosortContamination(vecClustIdx==intClustIdx);
			intKsGood = vecKilosortGood(vecClustIdx==intClustIdx);
			strKsLabel = cellKilosortLabel{vecClustIdx==intClustIdx};
		catch
			dblContamP = nan;
			intKsGood = nan;
			strKsLabel = '';
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
		sCluster(intCluster).Waveform = matClustWaveforms(intCluster,:);
		sCluster(intCluster).NonStationarity = sOut.dblNonstationarityIndex;
		sCluster(intCluster).Violations1ms = sOut.dblViolIdx1ms;
		sCluster(intCluster).Violations2ms = sOut.dblViolIdx2ms;
		sCluster(intCluster).Contamination = dblContamP;
		sCluster(intCluster).KilosortGood = intKsGood;
		sCluster(intCluster).KilosortLabel = strKsLabel;
		sCluster(intCluster).ZetaP = ZetaP;
		sCluster(intCluster).MeanP = MeanP;
		sCluster(intCluster).dPrimeLR = dPrimeLR;
		
		%add aditional cluster data
		intSourceClust = find(vecClustIdx==intClustIdx);
		if ~isempty(intSourceClust)
			for intField=1:numel(cellAllFields)
				strField = cellAllFields{intField};
				if ~ismember(strField,cellUsedFields)
					sCluster(intCluster).(strField) = sClustTsv(intSourceClust).(strField);
				end
			end
		end
		%msg
		fprintf('Cell %d/%d, Z-p=%.3f,M-p=%.3f, Non-stat=%.3f, Viol=%.3f, Contam=%.0f [%s]\n',...
			intCluster,intClustNum,nanmin(ZetaP),nanmin(MeanP),sOut.dblNonstationarityIndex,sOut.dblViolIdx1ms,vecKilosortContamination(intCluster),getTime);
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
	try,ptrText.String = 'Creating synthesis & saving to file...';drawnow;catch,end
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
	sJson.trials = strjoin(cellfun(@(x) num2str(numel(x.structEP.vecStimOnTime)),cellStim,'uniformoutput',false),';');
	sJson.nclust = intClustNum;
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
	if exist('sPupil','var') && ~isempty(sPupil)
		sSynthData.sPupil = sPupil;
	end
	
	%clusters & spikes
	sSynthData.sCluster = sCluster;
	
	%sync data
	sSynthData.sSyncData = sSyncData;
	
	%meta data
	sSynthData.sMetaNI = sMetaNI;
	sSynthData.sMiscNI = sMiscNI;
	if isfield(sFile,'sMetaAP')
		sSynthData.sMetaAP = sFile.sMetaAP;
	end
	if isfield(sFile,'sMetaLF')
		sSynthData.sMetaLF = sFile.sMetaLF;
	end
	
	%sAP.strFileLFP = strFileLFP;
	
	
	%source files
	sSources = sFile;
	sSources.sMetaVar = sRP.sMetaVar;
	sSources.vecChanIdx = vecChanIdx;
	sSources.matChanPos = matChanPos;
	sSynthData.sSources = sSources;
	
	% json metadata
	%file locations
	sJson.file_ap = strFileAp;
	sJson.file_lfp = strFileLFP;
	sJson.file_ni = sMetaNI.fileName;
	%add to struct
	sSynthData.sJson = sJson;
	sSynthData.ProcessingDate = getDate;
	
	%% save synthesis
	%save AP
	fprintf('Saving synthesis to %s [%s]\n',strFileSynthesis,getTime);
	save(strFileSynthesis,'sSynthData');
	
	%% create output structure
	sSynthesis = dir(strFileSynthesis);
	
	%% delete msg
	delete(ptrMsg);
end