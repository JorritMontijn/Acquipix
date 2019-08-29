function RM_redraw(varargin)
	%DC_redraw Sets and redraws windows
	%   DC_redraw([redrawImage=true])
	
	%get structures
	global sRM;
	global sFig;
	
	%check whether to plot in new figure
	intNewFigure = get(sFig.ptrButtonNewFig,'Value');
	
	%check if data has been loaded
	if isempty(sRM) || isempty(sFig)
		return;
	else
		try
			%get current image
			intImSelected = get(sFig.ptrListSelectImage,'Value');
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
	intImFilter = get(sFig.ptrListSelectImage,'Value');
	cellImFilters = get(sFig.ptrListSelectImage,'String');
	strImFilter = cellImFilters{intImFilter};
	intChannel = get(sFig.ptrListSelectChannel,'Value');
	cellChannels = get(sFig.ptrListSelectChannel,'String');
	strChannel = cellChannels{intChannel};
	
	%% prep data
	intTrials = min([sRM.intEphysTrial sRM.intStimTrial]);
	%define smoothing filter
	matFilter = normpdf(-2:2,0,0.5)' * normpdf(-2:2,0,0.5);
	matFilter = matFilter ./ sum(matFilter(:));
	
	%get data
	cellStimON = sRM.cellStimON;
	cellBaseON = sRM.cellBaseON;
	cellStimOFF = sRM.cellStimOFF;
	cellBaseOFF = sRM.cellBaseOFF;
	
	%fill empty entries with zeros
	[intNumCh,intNonEmptyIdx] = max(flat(cellfun(@size,cellStimON,cellfill(1,size(cellStimON)))));
	cellStimON(cellfun(@isempty,cellStimON)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	cellBaseON(cellfun(@isempty,cellBaseON)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	cellStimOFF(cellfun(@isempty,cellStimOFF)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	cellBaseOFF(cellfun(@isempty,cellBaseOFF)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	
	%get mean/sd responses
	vecSize = size(cellStimON);
	matMeanStimON = cell2mat(cellfun(@reshape,cellfun(@mean,cellStimON,cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matMeanStimOFF = cell2mat(cellfun(@reshape,cellfun(@mean,cellStimOFF,cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matMeanBaseON = cell2mat(cellfun(@reshape,cellfun(@mean,cellBaseON,cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matMeanBaseOFF = cell2mat(cellfun(@reshape,cellfun(@mean,cellBaseOFF,cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matSdStimON = cell2mat(cellfun(@reshape,cellfun(@std,cellStimON,cellfill([],vecSize),cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matSdStimOFF = cell2mat(cellfun(@reshape,cellfun(@std,cellStimOFF,cellfill([],vecSize),cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matSdBaseON = cell2mat(cellfun(@reshape,cellfun(@std,cellBaseON,cellfill([],vecSize),cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matSdBaseOFF = cell2mat(cellfun(@reshape,cellfun(@std,cellBaseOFF,cellfill([],vecSize),cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	
	%pre-allocate aggregates
	matAllRelSum = nan(size(matMeanStimON));
	matAllNormRel = nan(size(matMeanStimON));
	matAllNormSum = nan(size(matMeanStimON));
	matAllSmoothRelSum = nan(size(matMeanStimON));
	matAllSmoothNormRel = nan(size(matMeanStimON));
	matAllSmoothNormSum = nan(size(matMeanStimON));
	%close all
	for intCh=1:intNumCh
		%get means + stds
		matStimOnMean = matMeanStimON(:,:,intCh) - mean(matMeanStimON,3);
		matStimOnSd = matSdStimON(:,:,intCh);
		matStimOffMean = matMeanStimOFF(:,:,intCh) - mean(matMeanStimOFF,3);
		matStimOffSd = matSdStimOFF(:,:,intCh);
		matBaseOnMean = matMeanBaseON(:,:,intCh) - mean(matMeanBaseON,3);
		matBaseOnSd = matSdBaseON(:,:,intCh);
		matBaseOffMean = matMeanBaseOFF(:,:,intCh) - mean(matMeanBaseOFF,3);
		matBaseOffSd = matSdBaseOFF(:,:,intCh);
		
		%get plot matrices
		matRelOn = matStimOnMean - matBaseOnMean;
		matRelOff = matStimOffMean - matBaseOffMean;
		matRelSum = matRelOn + matRelOff;
		matNormRel = matRelOn./matStimOnSd + matRelOff./matStimOffSd;
		matNormSum = matStimOnMean./matStimOnSd + matStimOffMean./matStimOffSd;
		
		%get filters
		matAllSmoothRelSum(:,:,intCh) = conv2(matRelSum-mean(matRelSum(:)),matFilter,'same');
		matAllSmoothNormRel(:,:,intCh) = conv2(matNormRel-mean(matNormRel(:)),matFilter,'same');
		matAllSmoothNormSum(:,:,intCh) = conv2(matNormSum-mean(matNormSum(:)),matFilter,'same');
		matAllRelSum(:,:,intCh) = matRelSum;
		matAllNormRel(:,:,intCh) = matNormRel;
		matAllNormSum(:,:,intCh) = matNormSum;
	end
	
	%% magic
	matStimOnAll = bsxfun(@minus,matMeanStimON,mean(matMeanStimON,3));
	matBaseOnAll =  bsxfun(@minus,matMeanBaseON , mean(matMeanBaseON,3));
	matStimOffAll =  bsxfun(@minus,matMeanStimOFF , mean(matMeanStimOFF,3));
	matBaseOffAll =  bsxfun(@minus,matMeanBaseOFF , mean(matMeanBaseOFF,3));
	matRelOn = matStimOnAll - matBaseOnAll;
	matRelOff = matStimOffAll - matBaseOffAll;
	matRelSum = matRelOn + matRelOff;
	matAbs = mean(abs(bsxfun(@minus,matRelSum,mean(mean(matRelSum,1),2))),3);
	matMagicPlus = conv2(matAbs-mean(matAbs(:)),matFilter,'same');
	
	%% select filter
	if intImFilter == 1
		matUseMap = matAllSmoothRelSum;
	elseif intImFilter == 2
		matUseMap = matAllSmoothNormRel;
	elseif intImFilter == 3
		matUseMap = matAllSmoothNormSum;
	elseif intImFilter == 4
		matUseMap = matAllRelSum;
	elseif intImFilter == 5
		matUseMap = matAllNormRel;
	elseif intImFilter == 6
		matUseMap = matAllNormSum;
	end
	
	%% draw image
	%select channel
	if strcmp(strChannel,'Magic+')
		matPlot = matMagicPlus;
	elseif strcmp(strChannel,'Mean')
		matPlot = mean(matUseMap,3);
	elseif strcmp(strChannel,'Best')
		matFiltSquare = [1 1; 1 1];
		matFiltSquare = matFiltSquare./sum(matFiltSquare(:));
		vecRangeZ = nan(1,intNumCh);
		for intChIdx=1:intNumCh
			matSmoothed = conv2(matUseMap(:,:,intChIdx)-mean(flat(matUseMap(:,:,intChIdx))),matFiltSquare,'same');
			dblMu = mean(matSmoothed(:));
			dblSd = std(matSmoothed(:));
			vecRangeZ(intChIdx) = max(abs((matSmoothed(:)-dblMu)./dblSd));
		end
		[dummy,intBest] = max(vecRangeZ);
		matPlot = matUseMap(:,:,intBest);
		strChannel = strcat(strChannel,sprintf('=%d',intBest));
	elseif strcmp(strChannel(1:2),'Ch')
		intChannelNumber = str2double(getFlankedBy(strChannel,'Ch-',''));
		matPlot = matUseMap(:,:,intChannelNumber);
	else
		RM_updateTextInformation({sprintf('Channel "%s" not recognized',strChannel)});
		return;
	end
	strVersion=version();
	boolGood = str2double(strVersion(1)) > 8;
	if boolGood
		imagesc(sFig.ptrAxesHandle,matPlot);
	else
		axes(sFig.ptrAxesHandle);
		imagesc(matPlot);
	end
	
	%clean up figure
	title(sFig.ptrAxesHandle,strChannel);
	fixfig(sFig.ptrAxesHandle,false);
	grid(sFig.ptrAxesHandle,'off');
	axis(sFig.ptrAxesHandle,'off');
	drawnow;
end