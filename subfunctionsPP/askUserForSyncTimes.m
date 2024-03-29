function [dblStartHiDefT,dblUserStartT,dblFinalStartHiDefT,dblUserFinalT] = askUserForSyncTimes(vecPupilSyncLum,vecPupilTime,intBlock,vecReferenceT)
	%askUserForSyncTimes Request user input to synchronize on/offsets
	%   [dblStartHiDefT,dblUserStartT,dblFinalStartHiDefT,dblUserFinalT] = askUserForSyncTimes(vecPupilSyncLum,vecPupilTime,intBlock,vecReferenceT)
	
	%filter to 0.1-30Hz
	dblSampRatePupil = 1/median(diff(vecPupilTime));
	vecWindow2 = [0.5./(dblSampRatePupil./2) 0.99];
	[fb,fa] = butter(2,vecWindow2,'bandpass');
	vecFiltSyncLum = filtfilt(fb,fa, double(vecPupilSyncLum));
	boolPupilSync = vecFiltSyncLum>(std(vecFiltSyncLum)/3);
	
	figure
	subplot(2,1,1)
	hold on
	plot(vecPupilTime,zscore(vecPupilSyncLum));
	plot(vecPupilTime,boolPupilSync);
	scatter(vecReferenceT,zeros(size(vecReferenceT)),'bx');
	hold off
	xlabel('Time (s)');
	ylabel('Synchronization signal');
	hold off;
	fixfig(gca,[],1);
	
	subplot(2,1,2)
	hold on
	plot(vecPupilTime,vecFiltSyncLum./std(vecFiltSyncLum));
	plot(vecPupilTime,boolPupilSync);
	scatter(vecReferenceT,zeros(size(vecReferenceT)),'bx');
	hold off
	xlabel('Time (s)');
	ylabel('Synchronization signal');
	fixfig(gca,[],1);
	
	%ask when the stimuli start
	dblUserStartT = [];
	while isempty(dblUserStartT)
		dblUserStartT = input(sprintf('\nPlease enter a time point during the final blanking prior to start of stim1 for stimulation block %d (s):\n',intBlock));
		intStartT = find(vecPupilTime > dblUserStartT,1);
		if ~isempty(intStartT) && (boolPupilSync(intStartT) == 1)
			dblUserStartT = [];
			
			%print message
			ptrDialog = dialog('Name','Wrong selection','Position',[400 500 300 100]);
			ptrMsg = uicontrol('Parent',ptrDialog,...
				'Style','text',...
				'FontSize',10,...
				'Position',[10 0 280 90],...
				'String',sprintf('The selected timepoint is not during a blank!\n        (You selected t=%f)',dblUserStartT));
			ptrButton = uicontrol('Parent',ptrDialog,...
				'Position',[75 10 150 25],...
				'FontSize',10,...
				'String','Sorry... I''ll try again',...
				'Callback','delete(gcf)');
		end
	end
	
	%find first onset
	boolPupilSync(1:intStartT) = 0;
	intStartHiDef = find(boolPupilSync==1,1);
	dblStartHiDefT = vecPupilTime(intStartHiDef);
	if nargout > 2
		%ask when the stimuli stop
		dblUserFinalT = [];
		while isempty(dblUserFinalT)
			dblUserFinalT = input(sprintf('\nPlease enter a time point during the final blanking prior to start of the final stimulus presentation for stimulation block %d (s):\n',intBlock));
			intStopT = round(dblUserFinalT*dblSampRatePupil);
			if ~isempty(intStopT) && (boolPupilSync(intStopT) == 1)
				dblUserFinalT = [];
				
				%print message
				ptrDialog = dialog('Name','Wrong selection','Position',[400 500 300 100]);
				ptrMsg = uicontrol('Parent',ptrDialog,...
					'Style','text',...
					'FontSize',10,...
					'Position',[10 0 280 90],...
					'String',sprintf('The selected timepoint is not during a blank!\n        (You selected t=%f)',dblUserFinalT));
				ptrButton = uicontrol('Parent',ptrDialog,...
					'Position',[75 10 150 25],...
					'FontSize',10,...
					'String','Sorry... I''ll try again',...
					'Callback','delete(gcf)');
			end
		end
		intFinalUserT = find(vecPupilTime > dblUserFinalT,1);
		%find last offset
		boolPupilSyncLast = boolPupilSync;
		boolPupilSyncLast(1:intFinalUserT) = 0;
		intFinalHiDef = find(boolPupilSyncLast==1,1);
		dblFinalStartHiDefT = vecPupilTime(intFinalHiDef);
	end
	close;
end

