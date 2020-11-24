function OT_redraw(varargin)
	%DC_redraw Sets and redraws windows
	%   DC_redraw([redrawImage=true])
	
	%get structures
	global sOT;
	global sFig;
	
	%check whether to plot in new figure
	intNewFigure = get(sFig.ptrButtonNewFig,'Value');
	
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
	vecSelectChans = sOT.vecSelectChans;
	matRespBase = sOT.matRespBase; %[1 by S] cell with [chan x rep] matrix
	matRespStim = sOT.matRespStim; %[1 by S] cell with [chan x rep] matrix
	vecStimTypes = sOT.vecStimTypes; %[1 by S] cell with [chan x rep] matrix
	vecStimOriDeg = sOT.vecStimOriDeg; %[1 by S] cell with [chan x rep] matrix
	vecUnique = unique(vecStimOriDeg);
	intNumStimTypes = numel(vecUnique);
	
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
		dispErr(ME);
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
		strChannel = strcat(strChannel,sprintf('=%d/%d (Ch%d)',intChNr,intUnculledChannels,sOT.vecSpkChans(vecSelectChans(intChNr))));
	elseif strcmp(strChannel,'Mean')
		intChNr = 0;
		vecUseResp = mean(matUseResp,1);
	elseif strcmp(strChannel,'Single')
		intChNr = sOT.intMinChan;
		strChannel = strcat(strChannel,sprintf(': %d/%d (Ch%d)',intChNr,intUnculledChannels,sOT.vecSpkChans(vecSelectChans(intChNr))));
		vecUseResp = matUseResp(intChNr,:);
	else
		OT_updateTextInformation({sprintf('Selection "%s" not recognized',strChannel)});
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
	errorbar(sFig.ptrAxesHandle,vecUnique,vecPlotRespMean,vecPlotRespErr);
	hold(sFig.ptrAxesHandle,'off');
	
	%clean up figure
	ylabel(sFig.ptrAxesHandle,'MUA (a.u.)');
	xlabel(sFig.ptrAxesHandle,'Stimulus Orientation (deg)');
	fixfig(sFig.ptrAxesHandle,false);
	title(sFig.ptrAxesHandle,strTitle,'FontSize',10);
	
	drawnow;
end