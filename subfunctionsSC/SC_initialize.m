function [sFig,sStream] = SC_initialize(sFig,sStream)
	%SC_initialize initializes all fields when data paths are set
	
	%lock GUI
	SC_lock(sFig);
	drawnow;
	
	%msg
	SC_updateTextInformation('Initializing...');
	
	%data processing
	set(sFig.ptrListSelectDataProcessing,'String',sStream.metaData.cellProcess);
	
	%metrics
	set(sFig.ptrListSelectMetric,'String',sStream.metaData.cellMetric);
	
	%channel list
	set(sFig.ptrListSelectChannel,'String',sStream.metaData.cellChannels);
	
	%default downsample
	dblSampFreqIM = sStream.dblSampFreqIM;
	dblSampFreqNI = sStream.dblSampFreqNI;
	dblSubSampleToReq = str2double(get(sFig.ptrEditDownsample,'String'));
	sStream.intSubSampleFactorIM = round(dblSubSampleToReq*dblSampFreqIM);
	if isnan(sStream.intSubSampleFactorIM),sStream.intSubSampleFactorIM=0;end
	sStream.dblSubSampleTo = sStream.intSubSampleFactorIM/dblSampFreqIM;
	if isnan(sStream.dblSubSampleTo),sStream.dblSubSampleTo=0;end
	sStream.dblSubSampleFactorNI = dblSampFreqNI*sStream.dblSubSampleTo;
	set(sFig.ptrEditDownsample,'String',sprintf('%.3f',sStream.dblSubSampleTo));
	set(sFig.ptrTextDownsampleFactor,'String',num2str(sStream.intSubSampleFactorIM));
	
	%sample frequency
	set(sFig.ptrTextFreqIM,'String',sprintf('%.2f',dblSampFreqIM));
	set(sFig.ptrTextFreqNI,'String',sprintf('%.2f',dblSampFreqNI));
	
	%test GPU
	SC_updateTextInformation('Testing GPU Compute Capability...');
	
	try
		objGPU=gpuDevice;
		strCompCap = objGPU.ComputeCapability;
	catch
		strCompCap = '0';
	end
	dblCompCap = str2double(strCompCap);
	if dblCompCap >= 3
		sStream.UseGPU = true;
		SC_updateTextInformation(['GPU CC is good (' strCompCap '); GPU processing enabled!']);
	else
		sStream.UseGPU = false;
		SC_updateTextInformation(['GPU CC is bad (' strCompCap '); GPU processing disabled!']);
	end
	
	%load channel map
	sStream.sChanMap = load([sStream.metaData.strChanMapPath sStream.metaData.strChanMapFile]);
	
	%enable all fields
	SC_enable(sFig);
	
	%set msg
	sStream.IsInitialized = true;
	cellText = {'','Please wait for initial data read...'};
	SC_updateTextInformation(cellText);
end

