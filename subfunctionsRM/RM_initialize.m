function [sFig,sRM] = RM_initialize(sFig,sRM)
	%RM_initialize initializes all fields when data paths are set
	
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
		sRM.dblSampFreq = dblSampFreq;
		%msg
		cellText(end+1) = {'TDT data tank query has succeeded!'};
	catch ME
		%prep message
		cellText(end+1) = {'TDT data tank query has failed!'};
		cellText(end+1) = {''};
		cellText(end+1) = {'Please reinitialize when ready'};
		cellText(end+1) = {''};
		cellText(end+1) = {ME.message};
		RM_updateTextInformation(cellText);
		return
	end
	%lock GUI
	RM_lock(sFig);
	drawnow;
	
	%map pre-processing
	set(sFig.ptrListSelectImage,'String',sRM.metaData.cellFilter);
	
	%channel list
	cellPreChannels{1} = 'Magic+';
	cellPreChannels{2} = 'Mean';
	cellPreChannels{3} = 'Best';
	intPreNum = numel(cellPreChannels);
	cellChannels = cell(1,intPreNum+numel(vecChannels));
	cellChannels(1:intPreNum) = cellPreChannels;
	for intChannel=1:numel(vecChannels)
		cellChannels(intChannel+intPreNum) = {sprintf('Ch-%02d',vecChannels(intChannel))};
	end
	set(sFig.ptrListSelectChannel,'String',cellChannels);
	
	%default downsample
	dblSubSampleToReq = sRM.metaData.dblSubSampleToReq;
	intSubSampleFactor = round(dblSubSampleToReq*dblSampFreq);
	dblSubSampleTo = intSubSampleFactor/dblSampFreq;
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(intSubSampleFactor));
	
	%sample frequency
	set(sFig.ptrTextEphysFreq,'String',sprintf('%.2f',sRM.dblSampFreq));
	
	%default high-pass frequency
	set(sFig.ptrEditHighpassFreq,'String',sprintf('%.1f',sRM.metaData.dblFiltFreq));
	
	%test GPU
	cellText(end+1) = {'Testing GPU Compute Capability...'};
	RM_updateTextInformation(cellText);
	try
		objGPU=gpuDevice;
		strCompCap = objGPU.ComputeCapability;
	catch
		strCompCap = '0';
	end
	dblCompCap = str2double(strCompCap);
	if dblCompCap >= 3
		sRM.UseGPU = true;
		cellText(end+1) = {['GPU CC is good (' strCompCap '); GPU processing enabled!']};
		OT_updateTextInformation(cellText);
	else
		sRM.UseGPU = false;
		cellText(end+1) = {['GPU CC is bad (' strCompCap '); GPU processing disabled!']};
		OT_updateTextInformation(cellText);
	end
	
	%set msg
	sRM.IsInitialized = true;
	cellText(end+1) = {''};
	cellText(end+1) = {'RF mapper initialized!'};
	cellText(end+1) = {''};
	cellText(end+1) = {'Please wait for initial data read...'};
	RM_updateTextInformation(cellText);
end

