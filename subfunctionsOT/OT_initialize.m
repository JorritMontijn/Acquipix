function [sFig,sOT] = OT_initialize(sFig,sOT)
	%OT_initialize initializes all fields when data paths are set
	
	%attempt to read which channels exist
	cellText = {};
	try
		%set data
		sMetaData = struct;
		sMetaData.Myevent = 'dRAW';
		sMetaData.Mytank = get(sFig.ptrTextRecording, 'string');
		sMetaData.Myblock = get(sFig.ptrTextBlock, 'string');
		%read
		sMetaData = getMetaDataTDT(sMetaData);
		%assign
		vecChannels = 1:sMetaData.strms(1).channels;
		dblSampFreq = sMetaData.strms(strcmpi(sMetaData.Myevent, {sMetaData.strms(:).name} )).sampf;
		sOT.dblSampFreq = dblSampFreq;
		%msg
		cellText(end+1) = {'TDT data tank query has succeeded!'};
	catch ME
		%prep message
		cellText(end+1) = {'TDT data tank query has failed!'};
		cellText(end+1) = {''};
		cellText(end+1) = {'Please reinitialize when ready'};
		cellText(end+1) = {''};
		cellText(end+1) = {ME.message};
		OT_updateTextInformation(cellText);
		return
	end
	%lock GUI
	OT_lock(sFig);
	drawnow;
			
	%data processing
	set(sFig.ptrListSelectDataProcessing,'String',sOT.metaData.cellProcess);
	
	%metrics
	set(sFig.ptrListSelectMetric,'String',sOT.metaData.cellMetric);
	
	%channel list
	cellPreChannels{1} = 'Best';
	cellPreChannels{2} = 'Mean';
	intPreNum = numel(cellPreChannels);
	cellChannels = cell(1,intPreNum+numel(vecChannels));
	cellChannels(1:intPreNum) = cellPreChannels;
	for intChannel=1:numel(vecChannels)
		cellChannels(intChannel+intPreNum) = {sprintf('Ch-%02d',vecChannels(intChannel))};
	end
	set(sFig.ptrListSelectChannel,'String',cellChannels);
	
	%default downsample
	dblSubSampleToReq = sOT.metaData.dblSubSampleToReq;
	intSubSampleFactor = round(dblSubSampleToReq*dblSampFreq);
	dblSubSampleTo = intSubSampleFactor/dblSampFreq;
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(intSubSampleFactor));
	
	%sample frequency
	set(sFig.ptrTextEphysFreq,'String',sprintf('%.2f',sOT.dblSampFreq));
	
	%default high-pass frequency
	set(sFig.ptrEditHighpassFreq,'String',sprintf('%.1f',sOT.metaData.dblFiltFreq));
	
	%test GPU
	cellText(end+1) = {'Testing GPU Compute Capability...'};
	OT_updateTextInformation(cellText);
	try
		objGPU=gpuDevice;
		strCompCap = objGPU.ComputeCapability;
	catch
		strCompCap = '0';
	end
	dblCompCap = str2double(strCompCap);
	if dblCompCap >= 3
		sOT.UseGPU = true;
		cellText(end+1) = {['GPU CC is good (' strCompCap '); GPU processing enabled!']};
		OT_updateTextInformation(cellText);
	else
		sOT.UseGPU = false;
		cellText(end+1) = {['GPU CC is bad (' strCompCap '); GPU processing disabled!']};
		OT_updateTextInformation(cellText);
	end
	
	%set msg
	sOT.IsInitialized = true;
	cellText(end+1) = {''};
	cellText(end+1) = {'OT mapper initialized!'};
	cellText(end+1) = {''};
	cellText(end+1) = {'Please wait for initial data read...'};
	OT_updateTextInformation(cellText);
end

