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
	dblSampFreqIM = sOT.dblSampFreqIM;
	dblSampFreqNI = sOT.dblSampFreqNI;
	dblSubSampleToReq = str2double(get(sFig.ptrEditDownsample,'String'));
	sOT.intSubSampleFactorIM = round(dblSubSampleToReq*dblSampFreqIM);
	if isnan(sOT.intSubSampleFactorIM),sOT.intSubSampleFactorIM=0;end
	sOT.dblSubSampleTo = sOT.intSubSampleFactorIM/dblSampFreqIM;
	if isnan(sOT.dblSubSampleTo),sOT.dblSubSampleTo=0;end
	sOT.dblSubSampleFactorNI = dblSampFreqNI*sOT.dblSubSampleTo;
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',sOT.dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(sOT.intSubSampleFactorIM));
	
	%sample frequency
	set(sFig.ptrTextFreqIM,'String',sprintf('%.2f',dblSampFreqIM));
	set(sFig.ptrTextFreqNI,'String',sprintf('%.2f',dblSampFreqNI));
	
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
	
	%load channel map
	sOT.sChanMap = load([sOT.metaData.strChanMapPath sOT.metaData.strChanMapFile]);
	
	%enable all fields
	OT_enable(sFig);
	
	%set msg
	sOT.IsInitialized = true;
	cellText(end+1) = {''};
	cellText(end+1) = {'OT mapper initialized!'};
	cellText(end+1) = {''};
	cellText(end+1) = {'Please wait for initial data read...'};
	OT_updateTextInformation(cellText);
end

