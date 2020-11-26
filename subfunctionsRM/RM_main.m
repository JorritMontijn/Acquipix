function RM_main(varargin)
	%% RM_main Main RF mapper function called every second to check for updates
	%get globals
	global sFig;
	global sRM;
	
	try
		%% check if busy
		cellText = {};
		
		%check initialization
		if ~sRM.IsInitialized,return;end
		%check if busy
		if sFig.boolIsBusy,return;end
		
		%% run common stream processing module
		[sFig,sRM] = StreamCore(sFig,sRM,@RM_updateTextInformation);
		
		%% retrieve variables
		sFig.boolIsBusy = true;
		boolDidSomething = false;
		
		%get stim data from stream structure
		sStimObject = sRM.sStimObject;
		if isempty(sStimObject),clear sStimObject;end
		
		%get stim data from figure structure
		strStimPath = get(sFig.ptrTextStimPath, 'string');
		
		%stream variables
		intEphysTrialN = sRM.intEphysTrialN; %not used, only updated
		dblEphysTrialT = sRM.dblEphysTrialT; %not used, only updated
		intRespTrialN = sRM.intEphysTrialN; %not used, only updated
		intStimTrialN = sRM.intStimTrialN;
		dblStimTrialT = sRM.dblStimTrialT; %updated later
		
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
			dblStimCoverage = 100*sum(sStimObject(end).UsedLinLocOff(:))/numel(sStimObject(end).UsedLinLocOff);
			
			%save vars
			sRM.sStimObject = sStimObject;
			sRM.dblStimCoverage = dblStimCoverage;
			sRM.intStimTrialN = intStimTrialN;
			sRM.dblStimTrialT = dblStimTrialT;
			sRM.vecStimOnT = vecNewStimOnT;
			sRM.vecStimOffT = vecNewStimOffT;
			sRM.FlickerFreq = sStimObject(end).FlickerFreq;
			
			%update fig
			set(sFig.ptrTextStimTrialT, 'string',sprintf('%.2f',dblStimTrialT));
			set(sFig.ptrTextStimTrialN, 'string',sprintf('%d',intStimTrialN));
			set(sFig.ptrTextStimCoverage, 'string',sprintf('%.2f',dblStimCoverage));
			set(sFig.ptrTextStimType, 'string',sStimObject(intLoadObject).StimType);
			drawnow;
			
			%msg
			RM_updateTextInformation(sprintf('Loaded %d stimulus objects',numel(vecNewObjectIDs)));
			boolDidSomething = true;
		end
		
		%% update trial-average data matrix
		intTrials = min([intEphysTrialN intStimTrialN]);
		if intTrials > intRespTrialN
			%% calc RF estimate
			%ON, OFF, ON-base OFF-base
			cellStimON = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellBaseON = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellStimOFF = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			cellBaseOFF = cell(size(sStimObject(end).LinLoc)); %[y by x] cell with [chan x rep] matrix
			
			%get data
			vecSpikeT = sRM.vecSubSpikeT; %time in ms (uint32)
			vecSpikeCh = sRM.vecSubSpikeCh; %channel id (uint16); 1-start
			vecStimOnT = sRM.vecDiodeOnT; %on times of all stimuli (diode on time)
			vecStimOffT = sRM.vecDiodeOffT; %off times of all stimuli (diode off time)
			
			%get selected channels
			vecAllChans = sRM.vecAllChans; %AP, LFP, NI; 0-start
			vecSpkChans = sRM.vecSpkChans; %AP; 0-start
			vecIncChans = sRM.vecIncChans; %AP, minus culled; 0-start
			vecSelectChans = sRM.vecSelectChans; %AP, selected chans; 1-start
			vecActChans = sRM.vecIncChans(ismember(sRM.vecIncChans,sRM.vecSelectChans)); %AP, active channels (selected and unculled); 0-start
			intSpkChNum = numel(vecSpkChans); %number of original spiking channels
			
			%% go through objects and assign to matrices
			for intTrial=1:intTrials
				%get repetitions of locations
				vecLinLocOn = sStimObject(intTrial).LinLocOn;
				vecLinLocOff = sStimObject(intTrial).LinLocOff;
				matLinLoc = sStimObject(intTrial).LinLoc;
				
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
				vecBaseResp((end+1):intSpkChNum) = 0;
				
				%stim resp
				vecStimResp = accumarray(vecSpikeCh(vecStimSpikes),1) ./ (dblStopStim - dblStartStim);
				vecStimResp((end+1):intSpkChNum) = 0;
				%assign data
				for intLocOn=vecLinLocOn(:)'
					cellBaseON{matLinLoc==intLocOn}(:,end+1) = vecBaseResp;
					cellStimON{matLinLoc==intLocOn}(:,end+1) = vecStimResp;
				end
				for intLocOff=vecLinLocOff(:)'
					cellBaseOFF{matLinLoc==intLocOff}(:,end+1) = vecBaseResp;
					cellStimOFF{matLinLoc==intLocOff}(:,end+1) = vecStimResp;
				end
			end
			
			%% save data to globals
			sRM.intRespTrialN = intTrials;
			sRM.vecSelectChans = vecSelectChans;
			sRM.cellStimON = cellStimON; %[y by x] cell with [chan x rep] matrix
			sRM.cellBaseON = cellBaseON; %[y by x] cell with [chan x rep] matrix
			sRM.cellStimOFF = cellStimOFF; %[y by x] cell with [chan x rep] matrix
			sRM.cellBaseOFF = cellBaseOFF; %[y by x] cell with [chan x rep] matrix
			
			
			%% update maps
			RM_redraw(0);
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
			RM_updateTextInformation(cellText);
			pause(0.5);
		end
		
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		RM_unlock(sFig);
	catch ME
		%unlock busy & GUI
		sFig.boolIsBusy = false;
		RM_unlock(sFig);
		
		%send error
		dispErr(ME);
	end
	%end
	
	
	
