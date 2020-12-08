function NM_redraw(varargin)
	%DC_redraw Sets and redraws windows
	%   DC_redraw([redrawImage=true])
	%get structures
	global sNM;
	global sFig;
	
	
	%check if data has been loaded
	if isempty(sNM) || isempty(sFig)
		return;
	end
	
	%check whether to plot in new figure
	intNewFigure = get(sFig.ptrButtonNewFig,'Value');
	
	%check whether to make scatter plot
	intMakeScatterPlot = get(sFig.ptrButtonScatterYes,'Value');
	
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
			sFig.ptrAxesHandle = subplot(2,4,[1 2 3 5 6 7]);
			sFig.ptrAxesHandle2 = subplot(2,5,[5 10]);
			axis(sFig.ptrAxesHandle2,'off');
		else
			%set active figure
			%figure(sFig.ptrWindowHandle);
		end
	else
		% create figure
		sFig.ptrWindowHandle = figure;
		sFig.ptrAxesHandle = subplot(2,4,[1 2 3 5 6 7]);
		sFig.ptrAxesHandle2 = subplot(2,5,[5 10]);
		axis(sFig.ptrAxesHandle2,'off');
	end
	
	%% get data & requested parameters
	intDataProc = get(sFig.ptrListSelectDataProcessing,'Value');
	cellDataProcs = get(sFig.ptrListSelectDataProcessing,'String');
	strDataProc = cellDataProcs{intDataProc}; %type of selection; 100-ms
	intMetric = get(sFig.ptrListSelectMetric,'Value');
	cellMetrics = get(sFig.ptrListSelectMetric,'String');
	strMetric = cellMetrics{intMetric}; %ANOVA, delta-prime
	intChannel = get(sFig.ptrListSelectChannel,'Value');
	cellChannels = get(sFig.ptrListSelectChannel,'String');
	strChannel = cellChannels{intChannel}; %type of selection; best, mean, etc
	%intTrials = sNM.intRespTrialN;
	matRespNM = sNM.matRespNM; %[bin x rep x chan] matrix
	vecBinCenters = sNM.vecBinCenters;
	[intBins,intReps,intChMax] = size(matRespNM);
	matBinCenters = repmat(vecBinCenters,[1 intReps]);
	
	%% get channel selection vectors
	vecAllChans = sNM.vecAllChans; %AP, LFP, NI; 0-start
	vecSpkChans = sNM.vecSpkChans; %AP; 0-start
	vecIncChans = sNM.vecIncChans; %AP, minus culled; 0-start
	vecSelectChans = sNM.vecSelectChans; %AP, selected chans; 1-start
	vecActChans = vecSpkChans(ismember(vecSpkChans,vecSelectChans-1)); %AP, selected chans; 0-start
	intSpkChNum = numel(vecSpkChans); %number of original spiking channels
	intUseChN = numel(vecSelectChans);
			
	%% calculate best
	if contains(strMetric,'ANOVA')
		%this is what we'll do anyway
	elseif contains(strMetric,getGreek('delta'))
		%ignore; to do
	else
		%should not be possible
	end
	
	vecP=ones(1,intSpkChNum);
	for intCh=vecSelectChans
		vecP(intCh) = anova1(matRespNM(:,:,intCh)',[],'off');
	end
	vecZ = norminv(1-vecP/2);
	vecZ(isnan(vecZ)) = 0;
	
	intMagic = 10;
	[vecBestZ,vecBestIdx]=findmax(vecZ,intMagic);
	intUnculledChannels = numel(vecActChans);
	dblMaxZ = vecBestZ(1);
	intBest = vecBestIdx(1);
	
	%% draw image
	%select channel
	if strcmp(strChannel,'Magic+')
		%to do
	elseif strcmp(strChannel,'Mean')
		matPlot = mean(matRespNM(:,:,vecSelectChans),3);
		strChannel = strcat(strChannel,sprintf(' on Ch%d-%d (%d/%d used)',vecSelectChans(1)-1,vecSelectChans(end)-1,numel(vecSelectChans),intChMax));
	elseif strcmp(strChannel,'Best')
		matPlot = matRespNM(:,:,intBest);
		strChannel = strcat(strChannel,sprintf('=Ch%d (%d/%d used)',intBest-1,intUseChN,intChMax));

	elseif strcmp(strChannel,'Single')
		intChannelNumber = vecSelectChans(1);
		matPlot = matRespNM(:,:,intChannelNumber);
		strChannel = strcat(strChannel,sprintf('=Ch%d (%d/%d used)',intChannelNumber-1,intUseChN,intChMax));
	else
		SC_updateTextInformation({sprintf('Channel "%s" not recognized',strChannel)});
		return;
	end
	%calc plot vecs
	vecM = mean(matPlot,2);
	vecE = std(matPlot,[],2)./sqrt(intReps);
	
	%check matlab version
	strVersion=version();
	boolGood = str2double(strVersion(1)) > 8;
	if boolGood
		cla(sFig.ptrAxesHandle);
		scatter(sFig.ptrAxesHandle,matBinCenters(:),matPlot(:),'kx');
		hold(sFig.ptrAxesHandle,'on');
		errorbar(sFig.ptrAxesHandle,vecBinCenters,vecM,vecE);
		hold(sFig.ptrAxesHandle,'off');
		if intMakeScatterPlot == 1
			scatter(sFig.ptrAxesHandle2,vecZ,vecSpkChans,'kx');
		end
	else
		axes(sFig.ptrAxesHandle);
		scatter(matBinCenters,matPlot);
		hold on
		errorbar(vecBinCenters,vecM,vecE);
		hold off
		if intMakeScatterPlot == 1
			axes(sFig.ptrAxesHandle2);
			scatter(vecZ,vecSpkChans,'kx');
		end
	end
	
	%clean up figure
	ylabel(sFig.ptrAxesHandle,'Spike events (Hz)');
	xlabel(sFig.ptrAxesHandle,'Time after start (s)');
	%fixfig(sFig.ptrAxesHandle,false);
	title(sFig.ptrAxesHandle,[strDataProc '; ' strChannel],'FontSize',10);
	
	if intMakeScatterPlot == 1
		fixfig(sFig.ptrAxesHandle2,false);
		title(sFig.ptrAxesHandle2,'Z-score');
		axis(sFig.ptrAxesHandle2,'on');
		grid(sFig.ptrAxesHandle2,'off');
	end
	drawnow;
end