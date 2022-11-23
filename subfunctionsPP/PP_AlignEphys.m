function hFig = PP_AlignEphys(vecFullSignal,dblNISamprate,vecTimestampSecsRaw,vecTimestampSecsRefined,vecTimestampSecsRefinedCorrected,strPlotRec)
	%PP_AlignEphys Plots ephys alignment summary
	%   hFig = PP_AlignEphys(vecFullSignal,dblNISamprate,vecTimestampSecsRaw,vecTimestampSecsRefined,vecTimestampSecsRefinedCorrected,strPlotRec)

	
	%% plot
	intPlotSubSample=1000;
	vecPlotSignal = double(vecFullSignal(1:intPlotSubSample:end));
	dblMeanSignal = mean(vecPlotSignal);
	vecPlotSignalSecs = (1:numel(vecPlotSignal))/(dblNISamprate/intPlotSubSample);
	
	%calculate which corrections were out-of-bounds
	indRejected = vecTimestampSecsRefined~=vecTimestampSecsRefinedCorrected;
	vecTimestampSecsRawRejected = vecTimestampSecsRaw(indRejected);
	vecTimestampSecsRefinedRejected = vecTimestampSecsRefined(indRejected);
	
	hFig=figure;maxfig;
	subplot(2,3,1:3)
	plot(vecPlotSignalSecs,vecPlotSignal,'k')
	hold on
	scatter(vecTimestampSecsRaw,dblMeanSignal*ones(size(vecTimestampSecsRaw)),'xb')
	scatter(vecTimestampSecsRefinedCorrected,dblMeanSignal*ones(size(vecTimestampSecsRefinedCorrected)),'xg')
	scatter(vecTimestampSecsRefinedRejected,(1/20)*range(vecPlotSignal)+dblMeanSignal*ones(size(vecTimestampSecsRefinedRejected)),'xr')
	hold off
	xlim([min([min(vecTimestampSecsRaw) min(vecTimestampSecsRefinedRejected) min(vecTimestampSecsRefinedCorrected)])-1 ...
		max([max(vecTimestampSecsRaw) max(vecTimestampSecsRefinedRejected) max(vecTimestampSecsRefinedCorrected)])+1]);
	xlabel('Time (s)');
	ylabel('Signal (NI signal value)')
	legend({'Signal','Raw NI stamps','Accepted corrections','Rejected corrections'});
	title(sprintf('Ephys alignment - %s - Rejected corrections=%d - average correction=%dms',...
		strPlotRec,numel(vecTimestampSecsRawRejected),round(1000*mean(vecTimestampSecsRefinedCorrected-vecTimestampSecsRaw))),...
		'interpreter','none');
	
	h4=subplot(2,3,4);
	dblDur = median(diff(vecTimestampSecsRaw));
	sOpt = struct;
	sOpt.vecWindow = [-dblDur/2 dblDur];
	sOpt.handleFig = -1;
	[vecMean,vecSEM,vecWindowBinCenters,matPET] = doPEP(vecPlotSignalSecs,vecPlotSignal,vecTimestampSecsRaw,sOpt);
	plot([0 0],[min(matPET(:)) max(matPET(:))],'--');
	hold on
	plot(vecWindowBinCenters,matPET);
	hold off
	xlim(sOpt.vecWindow);
	h4.ColorOrder = [0 0 0; redbluepurple(numel(vecTimestampSecsRaw))];
	xlabel('Time after raw NI onset (s)');
	ylabel('Signal')
	title(sprintf('Pre-correction alignment'));
	
	h5=subplot(2,3,5);
	dblDur = median(diff(vecTimestampSecsRefinedCorrected));
	sOpt = struct;
	sOpt.vecWindow = [-dblDur/2 dblDur];
	sOpt.handleFig = -1;
	[vecMean,vecSEM,vecWindowBinCenters,matPET] = doPEP(vecPlotSignalSecs,vecPlotSignal,vecTimestampSecsRefinedCorrected,sOpt);
	plot([0 0],[min(matPET(:)) max(matPET(:))],'--');
	hold on
	plot(vecWindowBinCenters,matPET);
	hold off
	xlim(sOpt.vecWindow);
	h5.ColorOrder = [0 0 0; redbluepurple(numel(vecTimestampSecsRefinedCorrected))];
	xlabel('Time after signal-refined onset (s)');
	ylabel('Signal (z-score)')
	title(sprintf('Post-correction alignment'));
	
	subplot(2,3,6)
	scatter(vecTimestampSecsRaw,1000*(vecTimestampSecsRefinedCorrected-vecTimestampSecsRaw),'xg');
	hold on
	scatter(vecTimestampSecsRawRejected,1000*(vecTimestampSecsRefinedRejected-vecTimestampSecsRawRejected),'xr');
	hold off
	xlabel('Raw NI timestamp (s)');
	ylabel('Temporal correction (ms)')
	title(sprintf('Correction per event'));
	drawnow;
	
end

