function [sFig,sRM] = RM_initSGL(sFig,sRM)
	%UNTITLED3 Summary of this function goes here
	%   Detailed explanation goes here
	
	%start run if it's not already running
	boolInitSGL = IsInitialized(sRM.hSGL);
	boolIsRunningSGL = IsRunning(sRM.hSGL);
	if boolInitSGL && ~boolIsRunningSGL
		%start run
		StartRun(sRM.hSGL);
	end
	%set global switch
	sRM.boolInitSGL = true;
	
	% get data
	%set stream IDs
	intUseStreamIMEC = get(sFig.ptrListSelectProbe,'Value');
	vecStreamIM = [0];
	intStreamNI = -1;
	
	%get name for this run
	strRecording = GetRunName(sRM.hSGL);
	
	%get probe ID
	[cellSN,vecType] = GetImProbeSN(sRM.hSGL, vecStreamIM(intUseStreamIMEC));
	
	%get number of channels per type
	vecSaveChans = GetSaveChans(sRM.hSGL, vecStreamIM(intUseStreamIMEC));
	vecChPerType = GetAcqChanCounts(sRM.hSGL, vecStreamIM(intUseStreamIMEC));
	if numel(vecSaveChans) ~= sum(vecChPerType)
		%we're not saving all channels... is this correct?
		cellText{end+1} = '';
		cellText{end+1} = '<< WARNING >>';
		cellText{end+1} = sprintf('Only %d/%d available channels are being saved!',numel(vecSaveChans),sum(vecChPerType));
		OT_updateTextInformation(cellText);
		vecAllChans = 0:(sum(vecChPerType)-1);
	else
		vecAllChans = vecSaveChans;
	end
	
	%get samp freq
	sRM.dblSampFreqIM = GetSampleRate(sRM.hSGL, vecStreamIM(intUseStreamIMEC));
	sRM.dblSampFreqNI = GetSampleRate(sRM.hSGL, intStreamNI);
	
	%get current times
	intTimeNI = GetScanCount(sRM.hSGL, intStreamNI);
	intTimeIM = GetScanCount(sRM.hSGL, vecStreamIM(intUseStreamIMEC));
	
	%remove LFP channels
	vecUseChans = vecAllChans(1:vecChPerType(1));
	
	%assign
	sRM.vecAllChans = vecAllChans;
	sRM.vecUseChans = vecUseChans;
	sRM.vecSpkChans = vecUseChans;
	sRM.vecChPerType = vecChPerType;
	strChanNum = [num2str(sRM.vecUseChans(1)),' (1) - ',num2str(vecUseChans(end)),' (',num2str(numel(vecUseChans)),')'];

	%assign data buffer matrix
	intBufferT = round(sRM.dblDataBufferSize * sRM.dblSampFreqIM);
	sRM.intDataBufferSize = intBufferT;
	sRM.matDataBufferIM = zeros(intBufferT,numel(vecUseChans),'int16');
	sRM.vecTimestampsIM = zeros(intBufferT,1);
	sRM.intDataBufferPos = 1;
	sRM.dblSubLastUpdate = -1;
	
	%set sync channel
	sRM.intStimSyncChanNI = str2double(get(sFig.ptrEditStimSyncNI,'String'));
	
	%get analog channel voltage range
	sParamsSGL = GetParams(sRM.hSGL);
	sRM.NI2V = (sParamsSGL.niAiRangeMax) / (double(intmax('int16'))/2);
	
	%fill figure with data
	set(sFig.ptrTextChanNumIM, 'string', strChanNum);
	set(sFig.ptrTextRecording, 'string', strRecording);
	set(sFig.ptrListSelectProbe, 'string', cellSN);
	set(sFig.ptrTextFreqIM, 'string', sprintf('%.3f',sRM.dblSampFreqIM));
	set(sFig.ptrTextFreqNI, 'string', sprintf('%.3f',sRM.dblSampFreqNI));
	set(sFig.ptrTextTimeIM, 'string', sprintf('%.3f',intTimeIM/sRM.dblSampFreqIM));
	set(sFig.ptrTextTimeNI, 'string', sprintf('%.3f',intTimeNI/sRM.dblSampFreqNI));
end

