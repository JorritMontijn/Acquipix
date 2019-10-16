function [sFig,sOT] = OT_initialize(sFig,sOT)
	%OT_initialize initializes all fields when data paths are set
	
	%lock GUI
	OT_lock(sFig);
	drawnow;
	
	%msg
	cellText = {'Initializing...'};
	
	OT_updateTextInformation(cellText);
	%data processing
	set(sFig.ptrListSelectDataProcessing,'String',sOT.metaData.cellProcess);
	
	%metrics
	set(sFig.ptrListSelectMetric,'String',sOT.metaData.cellMetric);
	
	%channel list
	cellChannels{1} = 'Best';
	cellChannels{2} = 'Mean';
	cellChannels{3} = 'Single';
	set(sFig.ptrListSelectChannel,'String',cellChannels);
	
	%default downsample
	dblSampFreq = sOT.dblSampFreq;
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

