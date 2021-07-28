function PH_DeleteFcn(hObject,varargin)
	
	%get data
	if strcmp(hObject.UserData,'close')
		delete(hObject);
		return;
	end
	sGUI = guidata(hObject);
	
	%ask to quit
	opts = struct;
	opts.Default = 'Confirm exit?';
	opts.Interpreter = 'none';
	strAns = questdlg('Are you sure you wish to exit?','Confirm exit','Save & Exit','Exit & Discard data','Cancel',opts);
	switch strAns
		case 'Save & Exit'
			%retrieve original data
			sProbeCoords = sGUI.sProbeCoords;
			
			%add adjusted position
			sProbeAdjusted = sGUI.output;
			sGUI.sProbeAdjusted = sProbeAdjusted;
			sProbeCoords.sProbeAdjusted = sProbeAdjusted;
			
			%export probe coord file
			try
				save(fullpath(sProbeCoords.folder,sProbeCoords.name),'sProbeCoords');
			catch
				[strFile,strPath]=uiputfile('*.*','Save file as',sProbeCoords.name);
				if isempty(strFile) || (numel(strFile)==1 && strFile==0)
					return;
				end
				sProbeCoords.folder = strPath;
				sProbeCoords.name = strFile;
				save(fullpath(sProbeCoords.folder,sProbeCoords.name),'sProbeCoords');
			end
			
			%update gui &close
			hObject.UserData = 'close';
			sGUI.sProbeCoords = sProbeCoords;
			guidata(hObject,sGUI);
		case 'Exit & Discard data'
			sGUI.output = [];
			sGUI.sProbeAdjusted = [];
			hObject.UserData = 'close';
			guidata(hObject,sGUI);
		case 'Cancel'
			return;
	end
end