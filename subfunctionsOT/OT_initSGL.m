function [sFig,sOT] = OT_initSGL(sFig,sOT)
	%UNTITLED3 Summary of this function goes here
	%   Detailed explanation goes here
	
	%start run if it's not already running
	boolInitSGL = IsInitialized(sOT.hSGL);
	boolIsRunningSGL = IsRunning(sOT.hSGL);
	if boolInitSGL && ~boolIsRunningSGL
		%start run
		StartRun(sOT.hSGL);
	end
	%set global switch
	sOT.boolInitSGL = true;
	
	% get data
	%set stream IDs
	intUseStreamIMEC = get(sFig.ptrListSelectProbe,'Value');
	vecStreamIM = [0];
	intStreamNI = -1;
	
	%get name for this run
	strRecording = GetRunName(sOT.hSGL);
	
	%get probe ID
	[cellSN,vecType] = GetImProbeSN(sOT.hSGL, vecStreamIM(intUseStreamIMEC));
	
	%get number of channels per type
	vecSaveChans = GetSaveChans(sOT.hSGL, vecStreamIM(intUseStreamIMEC));
	vecChPerType = GetAcqChanCounts(sOT.hSGL, vecStreamIM(intUseStreamIMEC));
	if numel(vecSaveChans) ~= sum(vecChPerType)
		%we're not saving all channels... is this correct?
		cellText{end+1} = '';
		cellText{end+1} = '<< WARNING >>';
		cellText{end+1} = sprintf('Only %d/%d available channels are being saved!',numel(vecSaveChans),sum(vecChPerType));
		OT_updateTextInformation(cellText);
		sOT.vecAllChans = 0:(sum(vecChPerType)-1);
	else
		sOT.vecAllChans = vecSaveChans;
	end
	
	%get samp freq
	sOT.dblSampFreqIM = GetSampleRate(sOT.hSGL, vecStreamIM(intUseStreamIMEC));
	sOT.dblSampFreqNI = GetSampleRate(sOT.hSGL, intStreamNI);
	
	%get current times
	intTimeNI = GetScanCount(sOT.hSGL, intStreamNI);
	intTimeIM = GetScanCount(sOT.hSGL, vecStreamIM(intUseStreamIMEC));
	
	%check whether to show AP or LFP
	intLoadLFP = get(sFig.ptrButtonDataLFP,'Value');
	if intLoadLFP == 1 %LFP
		vecUseChans = sOT.vecAllChans((vecChPerType(1)+1):(vecChPerType(1)+vecChPerType(2)));
	else %AP
		vecUseChans = sOT.vecAllChans(1:vecChPerType(1));
	end
	sOT.vecUseChans = vecUseChans;
	strChanNum = [num2str(sOT.vecUseChans(1)),' - ',num2str(sOT.vecUseChans(end))];

	%set sync channel
	sOT.intStimSyncChanNI = str2double(get(sFig.ptrEditStimSyncNI,'String'));
	
	%get analog channel voltage range
	sParamsSGL = GetParams(sOT.hSGL);
	sOT.NI2V = (sParamsSGL.niAiRangeMax) / (double(intmax('int16'))/2);
	
	%fill figure with data
	set(sFig.ptrTextChanNumIM, 'string', strChanNum);
	set(sFig.ptrTextRecording, 'string', strRecording);
	set(sFig.ptrListSelectProbe, 'string', cellSN);
	set(sFig.ptrTextFreqIM, 'string', sprintf('%.3f',sOT.dblSampFreqIM));
	set(sFig.ptrTextFreqNI, 'string', sprintf('%.3f',sOT.dblSampFreqNI));
	set(sFig.ptrTextTimeIM, 'string', sprintf('%.3f',intTimeIM/sOT.dblSampFreqIM));
	set(sFig.ptrTextTimeNI, 'string', sprintf('%.3f',intTimeNI/sOT.dblSampFreqNI));
end

