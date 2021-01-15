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
		
		if ~boolDidSomething
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
	
