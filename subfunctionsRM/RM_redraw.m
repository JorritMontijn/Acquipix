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
	
	%% get data & requested parameters
	intChannel = get(sFig.ptrListSelectChannel,'Value');
	cellChannels = get(sFig.ptrListSelectChannel,'String');
	strChannel = cellChannels{intChannel}; %type of selection; best, magic, etc
	%intTrials = sRM.intRespTrialN;
	cellStimON = sRM.cellStimON; %[y by x] cell with [chan x rep] matrix
	%cellBaseON = sRM.cellBaseON; %[y by x] cell with [chan x rep] matrix
	cellStimOFF = sRM.cellStimOFF; %[y by x] cell with [chan x rep] matrix
	%cellBaseOFF = sRM.cellBaseOFF; %[y by x] cell with [chan x rep] matrix
	dblFlickerFreq = sRM.FlickerFreq; %ON/OFF if 0, otherwise merge
	
	%% get channel selection vectors
	vecAllChans = sRM.vecAllChans; %AP, LFP, NI; 0-start
	vecSpkChans = sRM.vecSpkChans; %AP; 0-start
	vecIncChans = sRM.vecIncChans; %AP, minus culled; 0-start
	vecSelectChans = sRM.vecSelectChans; %AP, selected chans; 1-start
	vecActChans = vecSpkChans(ismember(vecSpkChans,vecSelectChans)); %AP, selected chans; 0-start
	intSpkChNum = numel(vecSpkChans); %number of original spiking channels
			
	%% prep data
	%define smoothing filter
	%matFilter = normpdf(-2:2,0,0.5)' * normpdf(-2:2,0,0.5);
	%matFilter = matFilter ./ sum(matFilter(:));
	
	%fill empty entries with zeros
	[intNumCh,intNonEmptyIdx] = max(flat(cellfun(@size,cellStimON,cellfill(1,size(cellStimON)))));
	cellStimON(cellfun(@isempty,cellStimON)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	%cellBaseON(cellfun(@isempty,cellBaseON)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	cellStimOFF(cellfun(@isempty,cellStimOFF)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	%cellBaseOFF(cellfun(@isempty,cellBaseOFF)) = {zeros(intNumCh,1,'like',cellStimON{intNonEmptyIdx})}; 
	
	%get mean/sd responses; [y by x by ch]
	vecSize = size(cellStimON); %[y by x]
	matMeanStimON = cell2mat(cellfun(@reshape,cellfun(@mean,cellStimON,cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	matMeanStimOFF = cell2mat(cellfun(@reshape,cellfun(@mean,cellStimOFF,cellfill(2,vecSize),'uniformoutput',false),cellfill([1 1 intNumCh],vecSize),'uniformoutput',false));
	
	% get response
	if dblFlickerFreq == 0
		matMeanR = matMeanStimON - matMeanStimOFF;
	else
		matMeanR = matMeanStimON + matMeanStimOFF;
	end
	
	%% calculate best map
	matAbsR = abs(matMeanR);
	intChMax = size(matMeanR,3);
	vecSd = nan(1,intChMax);
	for intCh=vecSelectChans
		vecSd(intCh) = std(flat(matAbsR(:,:,intCh)));
	end
	matRelR = bsxfun(@rdivide,matAbsR,reshape(vecSd,[1 1 intChMax]));
	vecRelMax = nan(1,intChMax);
	for intCh=vecSelectChans
		vecRelMax(intCh) = max(flat(matRelR(:,:,intCh)));
	end
	vecRelMax(isnan(vecRelMax)) = 0;
	[dblRelMax,intBest]=max(vecRelMax);
	intUnculledChannels = numel(vecRelMax);
	
	%% draw image
	%select channel
	if strcmp(strChannel,'Magic+')
		matPlot = mean(bsxfun(@mtimes,matMeanR,reshape(vecRelMax,[1 1 intChMax])),3);
	elseif strcmp(strChannel,'Mean')
		matPlot = mean(matMeanR(:,:,vecSelectChans),3);
	elseif strcmp(strChannel,'Best')
		matPlot = matMeanR(:,:,intBest);
		strChannel = strcat(strChannel,sprintf('=%d/%d (Ch%d)',intBest,intUnculledChannels,vecActChans(intBest)));

	elseif strcmp(strChannel,'Single')
		intChannelNumber = vecSelectChans(1);
		matPlot = matMeanR(:,:,intChannelNumber);
		strChannel = strcat(strChannel,sprintf('=%d/%d (Ch%d)',intChannelNumber,intUnculledChannels,vecActChans(intChannelNumber)));
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