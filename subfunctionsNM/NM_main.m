function NM_main(varargin)
	%% NM_main Main natural movie mapper function called every second to check for updates
	%get globals
	global sFig;
	global sNM;
	sNM = 1;
	
	try
		%% check if busy
		cellText = {};
		
		%check initialization
		if ~sNM.IsInitialized,return;end
		%check if busy
		if sFig.boolIsBusy,return;end
		sFig.boolIsBusy = true;
		
		%% run common stream processing module
		[sFig,sNM,boolDidSomething] = StreamCore(sFig,sNM,@SC_updateTextInformation);
		
		%% retrieve variables
		%get stim data from stream structure
		sStimObject = sNM.sStimObject;
		if isempty(sStimObject),clear sStimObject;end
		
		%get stim data from figure structure
		strStimPath = get(sFig.ptrTextStimPath, 'string');
		
		%stream variables
		intEphysTrialN = sNM.intEphysTrialN; %not used, only updated
		dblEphysTrialT = sNM.dblEphysTrialT; %not used, only updated
		intRespTrialN = sNM.intRespTrialN; %not used, only updated
		intStimTrialN = sNM.intStimTrialN;
		dblStimTrialT = sNM.dblStimTrialT; %updated later
		
		%% retrieve & update stim log data
		%get stimulus object files
		sFiles = dir(strcat(strStimPath,filesep,'Object*.mat'));
		cellNames = {sFiles(:).name};
		vecObjectID = cellfun(@str2double,cellfun(@getFlankedBy,cellNames,cellfill('Object',size(cellNames)),cellfill('.mat',size(cellNames)),'uniformoutput',false));
		vecNewObjectIDs = sort(vecObjectID(vecObjectID>intStimTrialN),'descend');
		if ~isempty(vecNewObjectIDs)
			%if there is new data, load it
			for intLoadObject=vecNewObjectIDs
				sLoad = load([strStimPath filesep sprintf('Object%d.mat',intLoadObject)]);
				sStimObject(intLoadObject) = sLoad.sObject;
			end
			
			%update variables
			vecNewStimOnT = cell2mat({sStimObject(:).ActOnNI});
			vecNewStimOffT = cell2mat({sStimObject(:).ActOffNI});
			dblStimTrialT = max(cat(2,vecNewStimOnT,vecNewStimOffT));
			intStimTrialN = vecNewObjectIDs(1);
			dblStimCoverage = numel(sStimObject);
			
			%save vars
			sNM.sStimObject = sStimObject;
			sNM.dblStimCoverage = dblStimCoverage;
			sNM.intStimTrialN = intStimTrialN;
			sNM.dblStimTrialT = dblStimTrialT;
			sNM.vecStimOnT = vecNewStimOnT;
			sNM.vecStimOffT = vecNewStimOffT;
			sNM.FlickerFreq = sStimObject(end).FlickerFreq;
			
			%update fig
			set(sFig.ptrTextStimTrialT, 'string',sprintf('%.2f',dblStimTrialT));
			set(sFig.ptrTextStimTrialN, 'string',sprintf('%d',intStimTrialN));
			set(sFig.ptrTextStimCoverage, 'string',sprintf('%d',dblStimCoverage));
			set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
			drawnow;
			
			%msg
			SC_updateTextInformation(sprintf('Loaded %d stimulus objects',numel(vecNewObjectIDs)));
			boolDidSomething = true;
		end
		
		%% update trial-average data matrix
		intTrials = min([intEphysTrialN intStimTrialN]);
		if intTrials > intRespTrialN
			%% calc NM response
			%get data
			vecSpikeT = sNM.vecSubSpikeT; %time in ms (uint32)
			vecSpikeCh = sNM.vecSubSpikeCh; %channel id (uint16); 1-start
			vecStimOnT = sNM.vecDiodeOnT; %on times of all stimuli (diode on time)
			vecStimDurT = sNM.vecStimOffT - sNM.vecStimOnT; %stim duration (reliable NI timestamps difference)
			vecStimOffT = vecStimOnT + vecStimDurT; %off times of all stimuli (diode on + dur time)
			
			%get selected channels
			vecAllChans = sNM.vecAllChans; %AP, LFP, NI; 0-start
			vecSpkChans = sNM.vecSpkChans; %AP; 0-start
			vecIncChans = sNM.vecIncChans; %AP, minus culled; 0-start
			vecSelectChans = sNM.vecSelectChans; %AP, selected chans; 1-start
			vecActChans = sNM.vecIncChans(ismember(sNM.vecIncChans,sNM.vecSelectChans)); %AP, active channels (selected and unculled); 0-start
			intSpkChNum = numel(vecSpkChans); %number of original spiking channels
			
			%% build binning vector
			dblBinSize = 0.100;
			vecBinEdges = 0:dblBinSize:vecStimDurT(1);
			vecBinCenters = vecBinEdges(2:end) + dblBinSize/2;
			intBins = numel(vecBinCenters);
			
			%% go through objects and assign to matrices
			vecRunTrials = (intRespTrialN+1):intTrials;
			matResp_temp = zeros(intBins,numel(vecRunTrials),intSpkChNum);%[bin x rep x chan] matrix
			intRep = 0;
			for intTrial=vecRunTrials
				%get data
				intRep = intRep + 1;
				dblStartStim = vecStimOnT(intTrial);
				dblStopStim = vecStimOffT(intTrial);
				
				%subselect spikes
				vecStimSpikes = find(vecSpikeT>uint32(dblStartStim*1000) & vecSpikeT<uint32(dblStopStim*1000));
				%if ePhys data is not available yet, break
				if isempty(vecStimSpikes)
					continue;
				end
				vecSubT = vecSpikeT(vecStimSpikes);
				vecSubCh = vecSpikeCh(vecStimSpikes);
				
				%find which channels to run
				vecRunCh = find(ismember(vecSpkChans+1,vecSubCh));
				for intCh=vecRunCh(:)'
					%bin
					vecChSpikeT = vecSubT(vecSubCh==intCh);
					matResp_temp(:,intRep,intCh) = histcounts(vecChSpikeT,vecBinEdges+dblStartStim);
				end
			end
			
			%% save data to globals
			sNM.intRespTrialN = intTrials;
			sNM.vecBinCenters = vecBinCenters;
			sNM.matRespNM(:,vecRunTrials,:) = matResp_temp./dblBinSize; %[bin x rep x chan] matrix
			
			%% update maps
			NM_redraw(0);
			boolDidSomething = true;
		elseif ~boolDidSomething
			%% show waiting bar
			cellOldText = get(sFig.ptrTextInformation, 'string');
			strBaseString = 'No new data';
			if ~isempty(cellOldText) && numel(cellOldText{1}) > numel(strBaseString) && strcmpi(cellOldText{1}(1:numel(strBaseString)),strBaseString)
				cellBar = {'-','\','|','/'};
				cellText{1} = cellOldText{1};
				intPrev = find(strcmpi(cellText{1}(end),cellBar));
				if isempty(intPrev)
					intNext = 1;
				else
					intNext = mod(intPrev,numel(cellBar)) + 1;
				end
				cellText{1}(end) = cellBar{intNext};
			else
				cellText = {strcat(strBaseString,' -'),''};
			end
			SC_updateTextInformation(cellText);
			pause(0.5);
		end
		
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		SC_unlock(sFig);
	catch ME
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		SC_unlock(sFig);
		
		%send error
		dispErr(ME);
	end
	%end
	
	
	
