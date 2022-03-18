function [dblStimOnNI,dblStimOffNI]=PresentFlyOver(hSGL,ptrWindow,intStimNr,intStimType,sStimParams)
	
	%% get NI onset timestamp
	if ~isempty(hSGL)
		intStreamNI = -1;
		dblSampFreqNI = GetSampleRate(hSGL, intStreamNI);
		dblStimOnNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
	else
		dblStimOnNI = nan;
	end
	
	%% do stuff
	Screen('FillOval',ptrWindow, 1,[10 10 100 100]);
	Screen('Flip',ptrWindow);
	pause(0.5)
	Screen('FillRect',ptrWindow, sStimParams.intBackground);
	Screen('Flip',ptrWindow);
	
	%% get NI offset timestamp
	if ~isempty(hSGL)
		dblStimOffNI = GetScanCount(hSGL, intStreamNI)/dblSampFreqNI;
	else
		dblStimOffNI = nan;
	end
	
	%% save temp object
	%save object
	sObject = sStimParams;
	%add timestamps
	sObject.dblStimOnNI = dblStimOnNI;
	sObject.dblStimOffNI = dblStimOffNI;
	sObject.intStimType = intStimType;
	save(fullfile(sStimParams.strTempObjectPath,['Object',num2str(intStimNr),'.mat']),'sObject');
end