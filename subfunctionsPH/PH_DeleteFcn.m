function PH_DeleteFcn(hObject,varargin)
	
	%get data
	if strcmp(hObject.UserData,'close')
		delete(hObject);
		return;
	end
	sGUI = guidata(hObject);
	
	%ask to quit
	opts = struct;
	opts.Default = 'Cancel';
	opts.Interpreter = 'none';
	strAns = questdlg('Are you sure you wish to exit?','Confirm exit','Save & Exit','Exit & Discard data','Cancel',opts);
	switch strAns
		case 'Save & Exit'
			%retrieve original data
			sProbeCoords = sGUI.sProbeCoords;
			
			%name
			if isfield(sProbeCoords,'name')
				strDefName = sProbeCoords.name;
			else
				strDefName = 'RecXXX_ProbeCoords.mat';
			end
			%export probe coord file
			try
				if isempty(sProbeCoords.folder),error('dummy error');end
				save(fullpath(sProbeCoords.folder,sProbeCoords.name),'sProbeCoords');
			catch
				[strFile,strPath]=uiputfile('*.*','Save file as',strDefName);
				if isempty(strFile) || (numel(strFile)==1 && strFile==0)
					return;
				end
				sProbeCoords.folder = strPath;
				sProbeCoords.name = strFile;
				save(fullpath(sProbeCoords.folder,sProbeCoords.name),'sProbeCoords');
			end
			fprintf('Saved probe coordinates to %s\n',fullpath(sProbeCoords.folder,sProbeCoords.name));
			
			%update gui &close
			hObject.UserData = 'close';
			sGUI.sProbeCoords = sProbeCoords;
			guidata(hObject,sGUI);
		case 'Exit & Discard data'
			sGUI.output = [];
			sGUI.sProbeAdjusted = [];
			sGUI.sProbeCoords = [];
			hObject.UserData = 'close';
			guidata(hObject,sGUI);
			PH_DeleteFcn(hObject);
		case 'Cancel'
			return;
	end
end