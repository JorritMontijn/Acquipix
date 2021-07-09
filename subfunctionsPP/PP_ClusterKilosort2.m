function rez = PP_ClusterKilosort2(ops,strDataOutputDir,sWaitbar)
	
	%% extract inputs
	if nargin > 2
		intStep = sWaitbar.intStartStep - 1;
		intStepNum = sWaitbar.intStepNum;
		ptrWaitbarHandle = sWaitbar.ptrWaitbarHandle;
	else
		ptrWaitbarHandle = [];
	end
	
	%% this block runs all the steps of the algorithm
	% find the binary file
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Preprocessing...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rez                = preprocessDataSub(ops);
	
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Datashift2...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rez                = datashift2(rez, 1);
	
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Template learning...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rez = learnAndSolve8b(rez, 1);
	
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Merging clusters...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rez = find_merges(rez, 1);
	
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Splitting clusters...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rez = splitAllClusters(rez, 1);
	
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Setting cut-off...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rez = set_cutoff(rez);
	
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Finding good units...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rez.good = get_good_units(rez);
	
	if ~isempty(ptrWaitbarHandle)
		strStep = 'Exporting to phy...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	end
	rezToPhy2(rez, strDataOutputDir);
end