function rez = PP_ClusterKilosort3(ops,strDataOutputDir,sWaitbar)
	
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
	try
		strStep = 'Preprocessing...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	rez                = preprocessDataSub(ops);
	
	try
		strStep = 'Datashift2...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	rez                = datashift2(rez, 1);
	
	try
		strStep = 'Extract spikes...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	[rez, st3, tF]     = extract_spikes(rez);
	
	try
		strStep = 'Template learning...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	rez                = template_learning(rez, tF, st3);
	
	try
		strStep = 'Track and sort...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	[rez, st3, tF]     = trackAndSort(rez);
	
	try
		strStep = 'Final clustering...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	rez                = final_clustering(rez, tF, st3);
	
	try
		strStep = 'Find merges...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	rez                = find_merges(rez, 1);
	
	%check if we want to save temp_wh.dat
	if ops.intPermaSaveOfTempWh == 1
		try
			strStep = 'Copying temp_wh.dat...';
			intStep = intStep + 0.5;
			waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
		catch;end
		
		%copy temp_wh
		[strPath,strFile,strExt]=fileparts(rez.ops.fproc);
		strPermaTempWh = fullpath(strDataOutputDir,strcat(strFile,strExt));
		[status,message,messageId] = copyfile(rez.ops.fproc,strPermaTempWh);
		if status == 0
			warndlg(message,'File copy failure');
		else
			%save new location to rez/ops
			rez.ops.fproc = strPermaTempWh;
		end
	end
	
	try
		strStep = 'Exporting to phy...';
		intStep = intStep + 1;
		waitbar(intStep/intStepNum, ptrWaitbarHandle, sprintf('%s (step %d/%d)',strStep,intStep,intStepNum));
	catch;end
	rezToPhy2(rez, strDataOutputDir);
	
end