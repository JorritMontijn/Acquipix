function [sFig,sRM] = RM_initialize(sFig,sRM)
	%RM_initialize initializes all fields when data paths are set
	
	%lock GUI
	RM_lock(sFig);
	drawnow;
	
	%msg
	cellText = {'Initializing...'};
	
	RM_updateTextInformation(cellText);
	%data processing
	set(sFig.ptrListSelectDataProcessing,'String',sRM.metaData.cellProcess);
	
	%metrics
	set(sFig.ptrListSelectMetric,'String',sRM.metaData.cellMetric);
	
	%channel list
	cellChannels{1} = 'Magic+';
	cellChannels{2} = 'Mean';
	cellChannels{3} = 'Best';
	cellChannels{4} = 'Single';
	set(sFig.ptrListSelectChannel,'String',cellChannels);
	
	%default downsample
	dblSampFreqIM = sRM.dblSampFreqIM;
	dblSampFreqNI = sRM.dblSampFreqNI;
	dblSubSampleToReq = str2double(get(sFig.ptrEditDownsample,'String'));
	sRM.intSubSampleFactorIM = round(dblSubSampleToReq*dblSampFreqIM);
	if isnan(sRM.intSubSampleFactorIM),sRM.intSubSampleFactorIM=0;end
	sRM.dblSubSampleTo = sRM.intSubSampleFactorIM/dblSampFreqIM;
	if isnan(sRM.dblSubSampleTo),sRM.dblSubSampleTo=0;end
	sRM.dblSubSampleFactorNI = dblSampFreqNI*sRM.dblSubSampleTo;
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',sRM.dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(sRM.intSubSampleFactorIM));
	
	%sample frequency
	set(sFig.ptrTextFreqIM,'String',sprintf('%.2f',dblSampFreqIM));
	set(sFig.ptrTextFreqNI,'String',sprintf('%.2f',dblSampFreqNI));
	
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
		RM_updateTextInformation(cellText);
	else
		sRM.UseGPU = false;
		cellText(end+1) = {['GPU CC is bad (' strCompCap '); GPU processing disabled!']};
		RM_updateTextInformation(cellText);
	end
	
	%load channel map
	sRM.sChanMap = load([sRM.metaData.strChanMapPath sRM.metaData.strChanMapFile]);
	
	%enable all fields
	RM_enable(sFig);
	
	%set msg
	sRM.IsInitialized = true;
	cellText(end+1) = {''};
	cellText(end+1) = {'RF mapper initialized!'};
	cellText(end+1) = {''};
	cellText(end+1) = {'Please wait for initial data read...'};
	RM_updateTextInformation(cellText);
end

