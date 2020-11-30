function OT_main(varargin)
	%% OT_main Main OT mapper function called every second to check for updates
	%get globals
	global sFig;
	global sOT;
	
	try
		%% check if busy
		cellText = {};
		
		%check initialization
		if ~sOT.IsInitialized,return;end
		%check if busy
		if sFig.boolIsBusy,return;end
		sFig.boolIsBusy = true;
		
		%% run common stream processing module
		[sFig,sOT,boolDidSomething] = StreamCore(sFig,sOT,@SC_updateTextInformation);
		
		%% retrieve variables
		%get stim data from stream structure
		sStimObject = sOT.sStimObject;
		if isempty(sStimObject),clear sStimObject;end
		
		%get stim data from figure structure
		strStimPath = get(sFig.ptrTextStimPath, 'string');
		
		%stream variables
		intEphysTrialN = sOT.intEphysTrialN; %not used, only updated
		dblEphysTrialT = sOT.dblEphysTrialT; %not used, only updated
		intRespTrialN = sOT.intRespTrialN; %not used, only updated
		intStimTrialN = sOT.intStimTrialN;
		dblStimTrialT = sOT.dblStimTrialT; %updated later
		
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
			vecNewStimOnT = cell2mat({sStimObject(:).dblStimOnNI});
			vecNewStimOffT = cell2mat({sStimObject(:).dblStimOffNI});
			vecOriDegs = cell2mat({sStimObject(:).Orientation});
			[vecTrialIdx,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
			dblStimTrialT = max(cat(2,vecNewStimOnT,vecNewStimOffT));
			intStimTrialN = vecNewObjectIDs(1);
			dblStimCoverage = (intStimTrialN/numel(vecUnique))*100;
			%save vars
			sOT.sStimObject = sStimObject;
			sOT.dblStimCoverage = dblStimCoverage;
			sOT.intStimTrialN = intStimTrialN;
			sOT.dblStimTrialT = dblStimTrialT;
			sOT.vecStimOnT = vecNewStimOnT;
			sOT.vecStimOffT = vecNewStimOffT;
			
			%update fig
			set(sFig.ptrTextStimTrialT, 'string',sprintf('%.2f',dblStimTrialT));
			set(sFig.ptrTextStimTrialN, 'string',sprintf('%d',intStimTrialN));
			set(sFig.ptrTextStimCoverage, 'string',sprintf('%.2f',dblStimCoverage));
			set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
			drawnow;
			
			%msg
			cellText{end+1} = sprintf('Loaded %d stimulus objects',numel(vecNewObjectIDs));
			cellText{end+1} = '';
			SC_updateTextInformation(cellText);
			boolDidSomething = true;
		end
		
		%% update trial-average data matrix
		intTrials = min([intEphysTrialN intStimTrialN]);
		if intTrials > intRespTrialN
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
			%get selected channels
			vecUseSpkChans = sOT.vecSpkChans;
			intMaxChan = min(sOT.intMaxChan,numel(vecUseSpkChans));
			intMinChan = min(sOT.intMinChan,numel(vecUseSpkChans));
			vecSelectChans = intMinChan:intMaxChan;
			intUseCh = numel(vecUseSpkChans);
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
			
			%% update maps
			OT_redraw(0);
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
				cellText{end+1} = strcat(strBaseString,' -');
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
	
