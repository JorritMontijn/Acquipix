function OT_redraw(varargin)
	%DC_redraw Sets and redraws windows
	%   DC_redraw([redrawImage=true])
	
	%get structures
	global sOT;
	global sFig;
	
	%% check if data has been loaded
	if isempty(sOT) || isempty(sFig)
		return;
	end
	%check if busy
	if ~sOT.IsInitialized,return;end
	if sFig.boolIsDrawing,return;end
	sFig.boolIsDrawing = true;
	
	%check whether to plot in new figure
	intNewFigure = get(sFig.ptrButtonNewFig,'Value');
	
	%check whether to make scatter plot
	intMakeScatterPlot = get(sFig.ptrButtonScatterYes,'Value');
	
	%% update trial-average data matrix
	sStimObject = sOT.sStimObject;
	intTrials = min([sOT.intEphysTrialN sOT.intStimTrialN]);
	
	%get selected channels
	vecUseSpkChans = sOT.vecSpkChans;
	intMaxChan = min(sOT.intMaxChan,numel(vecUseSpkChans));
	intMinChan = min(sOT.intMinChan,numel(vecUseSpkChans));
	vecSelectChans = intMinChan:intMaxChan;
	intUseCh = numel(vecUseSpkChans);
	if isfield(sOT,'matRespStim')
		matRespStim = sOT.matRespStim;
	else
		matRespStim = [];
	end
	if intTrials > sOT.intRespTrialN || numel(vecSelectChans) ~= size(matRespStim,1)
		%% calc RF estimate
		%update variables
		vecOriDegs = cell2mat({sStimObject(:).Orientation});
		[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
		
		%get data
		vecSpikeT = sOT.vecSubSpikeT; %time in ms (uint32)
		vecSpikeCh = sOT.vecSubSpikeCh; %channel id (uint16); 1-start
		vecStimOnT = sOT.vecDiodeOnT(1:intTrials); %on times of all stimuli (diode on time)
		vecStimDurT = sOT.vecStimOffT(1:intTrials) - sOT.vecStimOnT(1:intTrials); %stim duration (reliable NI timestamps difference)
		vecStimOffT = vecStimOnT + vecStimDurT; %off times of all stimuli (diode on + dur time)
		%fprintf('intUseCh=%d; selectchans=%d-%d\n',intUseCh,intMinChan,intMaxChan);
		
		%base, stim
		matRespBase = nan(intUseCh,intTrials);
		matRespStim = nan(intUseCh,intTrials);
		vecStimTypes = nan(1,intTrials);
		vecStimOriDeg = nan(1,intTrials);
		%go through objects and assign to matrices
		for intTrial=1:intTrials
			%get orientation
			intStimType = vecTrialIdx(intTrial);
			
			%get data
			if intTrial==1
				dblStartTrial = vecStimOnT(intTrial)-median(vecStimOffT-vecStimOnT)+0.1;
			else
				dblStartTrial = vecStimOffT(intTrial-1)+0.1;
			end
			dblStartStim = vecStimOnT(intTrial);
			dblStopStim = vecStimOffT(intTrial);
			vecBaseSpikes = find(vecSpikeT>uint32(dblStartTrial*1000) & vecSpikeT<uint32(dblStartStim*1000));
			vecStimSpikes = find(vecSpikeT>uint32(dblStartStim*1000) & vecSpikeT<uint32(dblStopStim*1000));
			%if ePhys data is not available yet, break
			if isempty(vecBaseSpikes) || isempty(vecStimSpikes)
				continue;
			end
			
			%base resp
			vecBaseResp = accumarray(vecSpikeCh(vecBaseSpikes),1) ./ (dblStartStim - dblStartTrial);
			vecBaseResp(end+1:intUseCh) = 0;
			%stim resp
			vecStimResp = accumarray(vecSpikeCh(vecStimSpikes),1) ./ (dblStopStim - dblStartStim);
			vecStimResp(end+1:intUseCh) = 0;
			
			%size(matData)
			%min(vecBaseBins)
			%max(vecBaseBins)
			%assign data
			matRespBase(:,intTrial) = vecBaseResp;
			matRespStim(:,intTrial) = vecStimResp;
			vecStimTypes(intTrial) = intStimType;
			vecStimOriDeg(intTrial) = vecOriDegs(intTrial);
		end
		
		%% save data to globals
		sOT.intRespTrialN = intTrials;
		sOT.vecSelectChans = vecSelectChans;
		sOT.matRespBase = matRespBase(vecSelectChans,:); %[chan x rep] matrix
		sOT.matRespStim = matRespStim(vecSelectChans,:); %[chan x rep] matrix
		sOT.vecStimTypes = vecStimTypes; %
		sOT.vecStimOriDeg = vecStimOriDeg; %
	end
	
	%% check if data is available
	if ~isfield(sOT,'matRespStim') || isempty(sOT.matRespStim)
		sFig.boolIsDrawing = false;
		return;
	end
	
	%% check figure props
	%check if data has been loaded
	if isempty(sOT) || isempty(sFig)
		return;
	else
		try
			%get current image
			intImSelected = get(sFig.ptrListSelectMetric,'Value');
		catch %#ok<CTCH>
			return;
		end
	end
	
	% Draw the image if requested
	if intNewFigure == 0
		%check if figure is still there
		try
			ptrOldFig = get(sFig.ptrWindowHandle);
		catch %#ok<CTCH>
			ptrOldFig = [];
		end
		
		%make new figure
		if isempty(ptrOldFig)
			%close figure if old one still present
			if ~isempty(ptrOldFig)
				close(sFig.ptrWindowHandle);
			end
			
			% create figure
			sFig.ptrWindowHandle = figure;
			sFig.ptrAxesHandle = axes;
		else
			%set active figure
			%figure(sFig.ptrWindowHandle);
		end
	else
		% create figure
		sFig.ptrWindowHandle = figure;
		sFig.ptrAxesHandle = axes;
	end
	
	%% get requested parameters
	%check whether to plot in new figure
	intScatterPlot = get(sFig.ptrButtonScatterYes,'Value');
	intProcessType = get(sFig.ptrListSelectDataProcessing,'Value');
	cellProcessTypes = get(sFig.ptrListSelectDataProcessing,'String');
	strProcessType = cellProcessTypes{intProcessType};
	intMetric = get(sFig.ptrListSelectMetric,'Value');
	cellMetrics = get(sFig.ptrListSelectMetric,'String');
	strMetric = cellMetrics{intMetric};
	intChannel = get(sFig.ptrListSelectChannel,'Value');
	cellChannels = get(sFig.ptrListSelectChannel,'String');
	strChannel = cellChannels{intChannel};
	
	%% prep data
	intTrials = sOT.intRespTrialN;
	
	%get data from globals
	matRespBase = sOT.matRespBase; %[1 by S] cell with [chan x rep] matrix
	matRespStim = sOT.matRespStim; %[1 by S] cell with [chan x rep] matrix
	vecStimTypes = sOT.vecStimTypes; %[1 by S] cell with [chan x rep] matrix
	vecStimOriDeg = sOT.vecStimOriDeg; %[1 by S] cell with [chan x rep] matrix
	vecUnique = unique(vecStimOriDeg);
	intNumStimTypes = numel(vecUnique);
	
	%% get channel selection vectors
	vecAllChans = sOT.vecAllChans; %AP, LFP, NI; 0-start
	vecSpkChans = sOT.vecSpkChans; %AP; 0-start
	vecIncChans = sOT.vecIncChans; %AP, minus culled; 0-start
	vecSelectChans = sOT.vecSelectChans; %AP, selected chans; 1-start
	vecActChans = vecSpkChans(ismember(vecSpkChans,vecSelectChans)); %AP, selected chans; 0-start
	intSpkChNum = numel(vecSpkChans); %number of original spiking channels
	
	%% plot OT estimate
	matRelResp = matRespStim-matRespBase;
	matRelRespZ = zscore(matRelResp,[],2);
	
	%remove outliers
	matRelResp(abs(matRelRespZ)>3) = nan;
	
	%% select matrix to use
	if intProcessType == 1 %stim
		matUseResp = matRespStim;
	elseif intProcessType == 2 %base
		matUseResp = matRespBase;
	elseif intProcessType == 3 %stim - base
		matUseResp = matRelResp;
	end
	matUseResp = matUseResp(:,1:intTrials);
	intUnculledChannels = size(matUseResp,1);
	intChannelsInSelectChans = numel(vecSelectChans);
	if intUnculledChannels ~= intChannelsInSelectChans
		fprintf('ERROR: # of ch in matUseResp=%d, but # in vecSelectChans=%d\n',intUnculledChannels,intChannelsInSelectChans);
	end
	
	%% get directionality data
	%get quadrant inclusion lists
	vecHorizontal = deg2rad([0 180]);
	vecVertical = deg2rad([90 270]);
	vecDistLeft = circ_dist(deg2rad(vecStimOriDeg),vecHorizontal(1));
	vecDistRight = circ_dist(deg2rad(vecStimOriDeg),vecHorizontal(2));
	vecDistUp = circ_dist(deg2rad(vecStimOriDeg),vecVertical(1));
	vecDistDown = circ_dist(deg2rad(vecStimOriDeg),vecVertical(2));
	indIncludeLeft = abs(vecDistLeft) < deg2rad(10);
	indIncludeRight= abs(vecDistRight) < deg2rad(10);
	indIncludeUp= abs(vecDistUp) < deg2rad(10);
	indIncludeDown= abs(vecDistDown) < deg2rad(10);
	%get data
	vecRespLeft = nanmean(matUseResp(:,indIncludeLeft),2);
	vecRespRight = nanmean(matUseResp(:,indIncludeRight),2);
	vecRespUp = nanmean(matUseResp(:,indIncludeUp),2);
	vecRespDown = nanmean(matUseResp(:,indIncludeDown),2);
	vecLRIndex = (vecRespLeft - vecRespRight) ./ (vecRespLeft + vecRespRight);
	vecUDIndex = (vecRespUp - vecRespDown) ./ (vecRespUp + vecRespDown);
	vecVHIndex = ((vecRespLeft + vecRespRight) - (vecRespUp + vecRespDown)) ./ ((vecRespLeft + vecRespRight) + (vecRespUp + vecRespDown));
	
	%% get metrics
	try
		vecDeltaPrime = getDeltaPrime(matUseResp,deg2rad(vecStimOriDeg),true);
		vecRho_bc = zeros(size(vecDeltaPrime));%getTuningRho(matUseResp,deg2rad(vecStimOriDeg));
		vecOPI = getOPI(matUseResp,deg2rad(vecStimOriDeg));
		vecOSI = getOSI(matUseResp,deg2rad(vecStimOriDeg));
	catch ME
		vecDeltaPrime = nan;
		vecRho_bc = nan;
		vecOPI = nan;
		vecOSI = nan;
		%dispErr(ME);
	end
	
	%% select metric
	if intMetric == 1
		vecTuningValue = vecDeltaPrime;
	elseif intMetric == 2
		vecTuningValue = vecRho_bc;
	elseif intMetric == 3
		vecTuningValue = vecOPI;
	elseif intMetric == 4
		vecTuningValue = vecOSI;
	elseif intMetric == 5
		vecTuningValue = vecLRIndex;
	elseif intMetric == 6
		vecTuningValue = vecUDIndex;
	elseif intMetric == 7
		vecTuningValue = vecVHIndex;
	end
	
	%% get plotting data
	%select channel
	if strcmp(strChannel,'Best')
		[dummy,intChNr] = max(vecTuningValue);
		vecUseResp = matUseResp(intChNr,:);
		strChannel = strcat(strChannel,sprintf('=%d/%d (Ch%d)',intChNr,intUnculledChannels,vecActChans(intChNr)));
	elseif strcmp(strChannel,'Mean')
		intChNr = 0;
		vecUseResp = mean(matUseResp,1);
	elseif strcmp(strChannel,'Single')
		intChNr = 1;%sOT.intMinChan;
		strChannel = strcat(strChannel,sprintf(': %d/%d (Ch%d)',intChNr,intUnculledChannels,vecActChans(intChNr)));
		vecUseResp = matUseResp(intChNr,:);
	else
		SC_updateTextInformation({sprintf('Selection "%s" not recognized',strChannel)});
		return;
	end
	%add tuning metrics to title
	if intChNr > 0
		strTitle = strcat(strChannel,sprintf('; %s''=%.2f; %s=%.2f; OPI=%.2f; OSI=%.2f; LR=%.2f; UD=%.2f; VH=%.2f',...
			getGreek('delta','lower'),vecDeltaPrime(intChNr),getGreek('rho','lower'),vecRho_bc(intChNr),...
			vecOPI(intChNr),vecOSI(intChNr),vecLRIndex(intChNr),vecUDIndex(intChNr),vecVHIndex(intChNr)));
	else
		strTitle = ' Mean';
	end
	
	%% plot
	vecPlotRespMean = nan(1,intNumStimTypes);
	vecPlotRespErr = nan(1,intNumStimTypes);
	for intStimType=1:intNumStimTypes
		vecTheseResps = vecUseResp(vecStimTypes==intStimType);
		vecPlotRespMean(intStimType) = nanmean(vecTheseResps);
		vecPlotRespErr(intStimType) = nanstd(vecTheseResps)./sqrt(sum(~isnan(vecTheseResps)));
	end
	cla(sFig.ptrAxesHandle);
	if intScatterPlot == 1
		scatter(sFig.ptrAxesHandle,vecStimOriDeg,vecUseResp,'kx');
	end
	hold(sFig.ptrAxesHandle,'on');
	errorbar(sFig.ptrAxesHandle,vecUnique,vecPlotRespMean,vecPlotRespErr,'color',lines(1));
	hold(sFig.ptrAxesHandle,'off');
	
	%clean up figure
	ylabel(sFig.ptrAxesHandle,'Spike events (Hz)');
	xlabel(sFig.ptrAxesHandle,'Stimulus Orientation (deg)');
	fixfig(sFig.ptrAxesHandle,false);
	title(sFig.ptrAxesHandle,strTitle,'FontSize',10);
	
	drawnow;
	
	
	%unset busy
	sFig.boolIsDrawing = false;
	
end