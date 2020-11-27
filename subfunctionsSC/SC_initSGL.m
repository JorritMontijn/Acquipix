function [sFig,sStream] = SC_initSGL(sFig,sStream)
	%SC_initSGL Shared Core SGL Initialization
	%   [sFig,sStream] = SC_initSGL(sFig,sStream)
	
	%start run if it's not already running
	boolInitSGL = IsInitialized(sStream.hSGL);
	boolIsRunningSGL = IsRunning(sStream.hSGL);
	if boolInitSGL && ~boolIsRunningSGL
		%start run
		StartRun(sStream.hSGL);
	end
	%set global switch
	sStream.boolInitSGL = true;
	
	% get data
	%set stream IDs
	intUseStreamIMEC = get(sFig.ptrListSelectProbe,'Value');
	vecStreamIM = [0];
	intStreamNI = -1;
	
	%get name for this run
	strRecording = GetRunName(sStream.hSGL);
	
	%get probe ID
	[cellSN,vecType] = GetImProbeSN(sStream.hSGL, vecStreamIM(intUseStreamIMEC));
	
	%get number of channels per type
	vecSaveChans = GetSaveChans(sStream.hSGL, vecStreamIM(intUseStreamIMEC));
	vecChPerType = GetAcqChanCounts(sStream.hSGL, vecStreamIM(intUseStreamIMEC));
	if numel(vecSaveChans) ~= sum(vecChPerType)
		%we're not saving all channels... is this correct?
		cellText{end+1} = '';
		cellText{end+1} = '<< WARNING >>';
		cellText{end+1} = sprintf('Only %d/%d available channels are being saved!',numel(vecSaveChans),sum(vecChPerType));
		SC_updateTextInformation(cellText);
		vecAllChans = 0:(sum(vecChPerType)-1);
	else
		vecAllChans = vecSaveChans;
	end
	
	%get samp freq
	sStream.dblSampFreqIM = GetSampleRate(sStream.hSGL, vecStreamIM(intUseStreamIMEC));
	sStream.dblSampFreqNI = GetSampleRate(sStream.hSGL, intStreamNI);
	
	%get current times
	intTimeNI = GetScanCount(sStream.hSGL, intStreamNI);
	intTimeIM = GetScanCount(sStream.hSGL, vecStreamIM(intUseStreamIMEC));
	
	%remove LFP channels
	vecUseChans = vecAllChans(1:vecChPerType(1));
	
	%assign
	sStream.vecAllChans = vecAllChans;
	sStream.vecUseChans = vecUseChans;
	sStream.vecSpkChans = vecUseChans;
	sStream.vecChPerType = vecChPerType;
	strChanNum = [num2str(sStream.vecUseChans(1)),' (1) - ',num2str(vecUseChans(end)),' (',num2str(numel(vecUseChans)),')'];

	%assign data buffer matrix
	intBufferT = round(sStream.dblDataBufferSize * sStream.dblSampFreqIM);
	sStream.intDataBufferSize = intBufferT;
	sStream.matDataBufferIM = zeros(intBufferT,numel(vecUseChans),'int16');
	sStream.vecTimestampsIM = zeros(intBufferT,1);
	sStream.intDataBufferPos = 1;
	sStream.dblSubLastUpdate = -1;
	
	%set sync channel
	sStream.intStimSyncChanNI = str2double(get(sFig.ptrEditStimSyncNI,'String'));
	
	%get analog channel voltage range
	sParamsSGL = GetParams(sStream.hSGL);
	sStream.NI2V = (sParamsSGL.niAiRangeMax) / (double(intmax('int16'))/2);
	
	%fill figure with data
	set(sFig.ptrTextChanNumIM, 'string', strChanNum);
	set(sFig.ptrTextRecording, 'string', strRecording);
	set(sFig.ptrListSelectProbe, 'string', cellSN);
	set(sFig.ptrTextFreqIM, 'string', sprintf('%.3f',sStream.dblSampFreqIM));
	set(sFig.ptrTextFreqNI, 'string', sprintf('%.3f',sStream.dblSampFreqNI));
	set(sFig.ptrTextTimeIM, 'string', sprintf('%.3f',intTimeIM/sStream.dblSampFreqIM));
	set(sFig.ptrTextTimeNI, 'string', sprintf('%.3f',intTimeNI/sStream.dblSampFreqNI));
end

