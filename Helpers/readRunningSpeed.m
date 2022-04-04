function [vecSamples,vecRunningData,vecSyncData,sStream]=readRunningSpeed(sStream,intRunningChanNI,intStimOnsetChanNI)
	%readRunningSpeed Read real-time running speed. Syntax:
	%   [vecSamples,vecRunningData,vecSyncData,sStream]=readRunningSpeed(sStream,intRunningChanNI,intStimOnsetChanNI)
	%
	%inputs:
	% - sStream: structure containing SpikeGLX data-stream metadata
	% - intRunningChanNI: NI channel connected to running wheel
	% - intStimOnsetChanNI: (optional) NI channel connected to screen diode
	%
	%outputs:
	% - vecSamples: NI sample numbers corresponding to vecRunningData/vecSyncData
	% - vecRunningData: raw running wheel data
	% - vecSyncData: screen diode data (empty if channel definition was not supplied)
	% - sStream: updated structure
	%
	%Version 1.0 [2021-11-23]
	%	Created by Jorrit Montijn
	
	%% get variables
	%check if stim onset channel is supplied
	if nargin < 3 || ~exist('intStimOnsetChanNI','var') || isempty(intStimOnsetChanNI)
		intStimOnsetChanNI = [];
	end
	
	%get stream variables
	hSGL = sStream.hSGL;
	intStreamNI = sStream.intStreamNI;
	intLastFetchNI = sStream.intLastFetchNI;
	dblSampFreqNI = sStream.dblSampFreqNI;
	
	%get probe variables
	dblStreamBufferSizeSGL = 5; %stream buffer size should be 8 seconds, but we'll set the maximum retrieval lower to be safe
	intMaxFetchNI = round(dblSampFreqNI*dblStreamBufferSizeSGL);
	
	% SGL data
	%prep meta data
	intDownsampleNI = 1;
	
	%% get NI I/O box data
	%get current scan number for IM streams
	intCurCountNI = GetScanCount(hSGL, intStreamNI);
	
	%check if this is the initial fetch
	if intLastFetchNI == 0 || (intLastFetchNI < (intCurCountNI - intMaxFetchNI))
		intRetrieveSamplesNI = round(1*dblSampFreqNI); %retrieve last 1 second
		intRetrieveSamplesNI = min(intCurCountNI-1,intRetrieveSamplesNI); %ensure we're not requesting data prior to start
		intStartFetch = intCurCountNI - intRetrieveSamplesNI; %set last fetch to starting position
	else
		intStartFetch = intLastFetchNI - round(0.2*dblSampFreqNI);
		intStartFetch = max(intStartFetch,1); %ensure we're not requesting data prior to start
		intRetrieveSamplesNI = intCurCountNI - intStartFetch; %retrieve as many samples as acquired between previous fetch and now
	end
	
	%check that requested fetch does not exceed buffer limit
	if intRetrieveSamplesNI > intMaxFetchNI
		%crop Fetch
		intRetrieveSamplesNI = intMaxFetchNI;
		%send warning
		fprintf('<< WARNING >> Requested NI Fetch was %.1fs, max query is %.1fs',...
			intRetrieveSamplesNI/dblSampFreqNI,intMaxFetchNI/dblSampFreqNI);
		
		%crop Fetch
		intRetrieveSamplesNI = intMaxFetchNI;
	end
	
	%get NI data
	if intRetrieveSamplesNI > 0
		%fetch in try-catch block
		try
			%fetch "intRetrieveSamplesNI" samples starting at "intFetchStartCountNI"
			[matDataNI,intStartCountNI] = Fetch(hSGL, intStreamNI, intStartFetch, intRetrieveSamplesNI, [intRunningChanNI intStimOnsetChanNI],intDownsampleNI);
		catch ME
			%buffer has likely already been cleared; unable to fetch data
			cellText = {'<< ERROR >>',ME.identifier,ME.message};
			feval(f_updateTextInformation,cellText);
			return;
		end
	end
	
	%update NI time
	dblEphysTimeNI = intCurCountNI/dblSampFreqNI;
	%save to globals
	sStream.intLastFetchNI = intCurCountNI;
	sStream.dblEphysTimeNI = dblEphysTimeNI;
	
	%process NI data
	vecSamplesNI = ((intStartFetch+1):intDownsampleNI:intCurCountNI);
	if isempty(intStimOnsetChanNI)
		vecNewSyncData = [];
	else
		vecNewSyncData = sStream.NI2V*single(matDataNI(:,1)); %transform to voltage
	end
	
	%collect outputs
	vecSamples = vecSamplesNI;
	vecRunningData = matDataNI(:,1);
	vecSyncData = vecNewSyncData;
end