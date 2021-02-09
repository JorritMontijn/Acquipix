function [dblStartHiDefT,dblUserStartT,dblStopHiDefT,dblUserStopT] = askUserForSyncTimes(vecPupilSyncLum,vecPupilTime,intBlock)
	%askUserForSyncTimes Request user input to synchronize on/offsets
	%   [dblStartHiDefT,dblUserStartT,dblStopHiDefT,dblUserStopT] = askUserForSyncTimes(vecPupilSyncLum,vecPupilTime,intBlock)
	
	%filter to 0.1-30Hz
	dblSampRatePupil = 1/median(diff(vecPupilTime));
	vecWindow2 = [0.5 30]./(dblSampRatePupil./2);
	[fb,fa] = butter(2,vecWindow2,'bandpass');
	vecFiltSyncLum = filtfilt(fb,fa, double(vecPupilSyncLum));
	boolPupilSync = vecFiltSyncLum>(std(vecFiltSyncLum)/3);
	
	figure
	subplot(2,1,1)
	hold on
	plot(vecPupilTime,vecPupilSyncLum - mean(vecPupilSyncLum));
	plot(vecPupilTime,boolPupilSync);
	hold off
	xlabel('Time (s)');
	ylabel('Synchronization signal');
	hold off;
	fixfig(gca,[],1);
	
	subplot(2,1,2)
	hold on
	plot(vecPupilTime,vecFiltSyncLum./std(vecFiltSyncLum));
	plot(vecPupilTime,boolPupilSync);
	hold off
	xlabel('Time (s)');
	ylabel('Synchronization signal');
	fixfig(gca,[],1);
	
	%ask when the stimuli start
	dblUserStartT = [];
	while isempty(dblUserStartT)
		dblUserStartT = input(sprintf('\nPlease enter a time point during the final blanking prior to start of stim1 for stimulation block %d (s):\n',intBlock));
		intStartT = round(dblUserStartT*dblSampRatePupil);
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
	dblStartHiDefT = intStartHiDef/dblSampRatePupil;
	if nargout > 2
		%ask when the stimuli stop
		dblUserStopT = [];
		while isempty(dblUserStopT)
			dblUserStopT = input(sprintf('\nPlease enter a time point during the final stimulus presentation for stimulation block %d (s):\n',intBlock));
			intStopT = round(dblUserStopT*dblSampRatePupil);
			if ~isempty(intStopT) && (boolPupilSync(intStopT) == 0)
				dblUserStopT = [];
				
				%print message
				ptrDialog = dialog('Name','Wrong selection','Position',[400 500 300 100]);
				ptrMsg = uicontrol('Parent',ptrDialog,...
					'Style','text',...
					'FontSize',10,...
					'Position',[10 0 280 90],...
					'String',sprintf('The selected timepoint is not during a stimulus!\n        (You selected t=%f)',dblUserStopT));
				ptrButton = uicontrol('Parent',ptrDialog,...
					'Position',[75 10 150 25],...
					'FontSize',10,...
					'String','Sorry... I''ll try again',...
					'Callback','delete(gcf)');
			end
		end
		intStopT = round(dblUserStopT*dblSampRatePupil);
		%find last offset
		boolPupilSyncOff = boolPupilSync;
		boolPupilSyncOff(1:intStopT) = 1;
		intStopHiDef = find(boolPupilSyncOff==0,1);
		dblStopHiDefT = intStopHiDef/dblSampRatePupil;
	end
	%close;
end

