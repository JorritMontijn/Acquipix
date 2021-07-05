function [ptrPanelParent,ptrSlider,ptrPanelTitle,sPointers] = RP_genSliderPanel(ptrMasterFigure,vecLocation,sFiles)
	
	%% set constants
	% check which version of matlab this is; naming of tooltips changed between R2019a and R2019b.
	if verLessThan('matlab','9.7')
		strTooltipField = 'TooltipString';
	else
		strTooltipField = 'Tooltip';
	end
	
	%unpack location vector
	dblTitleHeight = 0.15;
	dblTitleY = vecLocation(2)+vecLocation(4)-dblTitleHeight;
	dblPanelX = vecLocation(1);
	dblPanelY = vecLocation(2);
	dblPanelWidth = vecLocation(3);
	dblPanelHeight = vecLocation(4)-dblTitleHeight;
	dblStartVal = 0;
	
	%size contants
	intHorzYN = 20;
	intHorzCheck = 20;
	intHorzName = 330;
	intHorzDate = 70;
	intHorzBytes = 70;
	
	%calculate the total size of the subpanel content
	intFiles = numel(sFiles);
	ptrMasterFigure.Units = 'pixels';
	vecMasterSize = ptrMasterFigure.Position;
	ptrMasterFigure.Units = 'normalized';
	vecTotSize = (intFiles+1)*30;
	dblRelSize = (vecTotSize/(vecMasterSize(end)*dblPanelHeight))+dblPanelHeight;
	
	%% make title panel
	ptrPanelTitle = uipanel('Parent',ptrMasterFigure);
	set(ptrPanelTitle,'Position',[dblPanelX dblTitleY dblPanelWidth dblTitleHeight]);
	ptrCrapHack = axes(ptrPanelTitle,'Color','none','Position',[0 0 1 1],'Clipping','off');
	axis off;
	
	%%
	%output
	dblY = 0.1;
	dblW = vecMasterSize(3)*dblPanelWidth*0.9;
	%checkbox: run?
	vecLoc = [0.01 0 intHorzCheck/dblW];
	vecStartHorzAt(1) = vecLoc(1);
	dblAngle = 80;
	dblFontSize = 10;
	text(ptrCrapHack,vecLoc(1),dblY,'Run?','Rotation',dblAngle,'FontSize',dblFontSize);
	%synthesis
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'Synthesized','Rotation',dblAngle,'FontSize',dblFontSize);
	%Clustered
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'Clustered','Rotation',dblAngle,'FontSize',dblFontSize);
	%pupil
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'Pupil data','Rotation',dblAngle,'FontSize',dblFontSize);
	%Probe
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'Probe coords','Rotation',dblAngle,'FontSize',dblFontSize);
	%stim files
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'Stim files','Rotation',dblAngle,'FontSize',dblFontSize);
	%AP ephys
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'AP Ephys','Rotation',dblAngle,'FontSize',dblFontSize);
	%LFP ephys
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'LFP Ephys','Rotation',dblAngle,'FontSize',dblFontSize);
	%NI ephys
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),dblY,'NI Ephys','Rotation',dblAngle,'FontSize',dblFontSize);
	%name
	vecLoc = [vecLoc(1)+vecLoc(3)*2 0 intHorzName/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1),0.2,'File name','FontSize',12);
	%date
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzDate/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1)*0.915,0.2,'Date','FontSize',12);
	%size
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzBytes/dblW];
	vecStartHorzAt(end+1) = vecLoc(1);
	text(ptrCrapHack,vecLoc(1)*0.918,0.2,'Total size','FontSize',12);
	
	
	%% create the subpanels
	ptrPanelParent = uipanel('Parent',ptrMasterFigure);
	set(ptrPanelParent,'Position',[dblPanelX dblPanelY dblPanelWidth dblPanelHeight]);
	ptrPanelChild = uipanel('Parent',ptrPanelParent);
	set(ptrPanelChild,'Position',[0 0 1 dblRelSize]);
	ptrSlider = uicontrol('Style','Slider','Parent',ptrMasterFigure,...
		'Units','normalized','Position',[0.94 dblPanelY 0.05 dblPanelHeight],...
		'Value',dblStartVal,'Callback',{@RP_SliderCallback,ptrPanelChild});
	
	
	%% add all variables
	sPointers = [];
	dblH = 25;
	for intFile=1:intFiles
		%checkbox: run?
		strTip = 'Select to process';
		vecLoc = [1 4+(intFiles*30)-((intFile-1)*30) intHorzCheck dblH];
		sPointers(intFile).CheckRun = uicontrol(ptrPanelChild,'style','checkbox',...
			'Position',vecLoc,'String','',strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles(intFile).sSynthesis = sSynthesis;
		if isfield(sFiles(intFile),'sSynthesis') && ~isempty(sFiles(intFile).sSynthesis)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = ['Combined data at: ' sFiles(intFile).sSynthesis.folder];
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Not yet synthesized';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).Synthesized = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles(intFile).sClustered = sClustered;
		if isfield(sFiles(intFile),'sClustered') && ~isempty(sFiles(intFile).sClustered)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = ['Clustered data at: ' sFiles(intFile).sClustered.folder];
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Not yet clustered';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).Clustered = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		
		%sFiles(intFile).sPupilFiles = sPupilFiles;
		if isfield(sFiles(intFile),'sPupilFiles') && ~isempty(sFiles(intFile).sPupilFiles)
			intPupilFileNum = numel(sFiles(intFile).sPupilFiles);
			strText = sprintf('%d',intPupilFileNum);
			vecColor = [0 0.8 0];
			strTip = sprintf('Found %d pupil files:',intPupilFileNum);
			for intPupilFile=1:numel(sFiles(intFile).sPupilFiles)
				strTip = [strTip newline sFiles(intFile).sPupilFiles(intPupilFile).name];
			end
		else
			strText = '0';
			vecColor = [0.8 0 0];
			strTip = 'Did not find any pre-processed pupil data';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).Pupil = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles(intFile).sProbeCoords = sProbeCoords;
		if isfield(sFiles(intFile),'sProbeCoords') && ~isempty(sFiles(intFile).sProbeCoords)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = ['Probe track/coordinate data at: ' sFiles(intFile).sProbeCoords.name];
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Did not find probe track/coordinate data';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).Coords = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles(intFile).sStimFiles = sStimFiles;
		if isfield(sFiles(intFile),'sStimFiles') && ~isempty(sFiles(intFile).sStimFiles)
			intStimFileNum = numel(sFiles(intFile).sStimFiles);
			strText = sprintf('%d',intStimFileNum);
			vecColor = [0 0.8 0];
			strTip = sprintf('Found %d stim files:',intStimFileNum);
			for intStimFile=1:numel(sFiles(intFile).sStimFiles)
				strTip = [strTip newline sFiles(intFile).sStimFiles(intStimFile).name];
			end
		else
			strText = '0';
			vecColor = [0.8 0 0];
			strTip = 'Did not find any stim files';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).Stim = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		
		%sFiles(intFile).sEphysAp = sEphysAp;
		if isfield(sFiles(intFile),'sEphysAp') && ~isempty(sFiles(intFile).sEphysAp)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = ['AP channel data at: ' sFiles(intFile).sEphysAp.name];
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Did not find AP channel data';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).AP = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		%sFiles(intFile).sEphysLf = sEphysLf;
		if isfield(sFiles(intFile),'sEphysLf') && ~isempty(sFiles(intFile).sEphysLf)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = ['LFP channel data at: ' sFiles(intFile).sEphysLf.name];
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Did not find LFP channel data';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).LFP = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles(intFile).sEphysNidq = sEphysNidq;
		if isfield(sFiles(intFile),'sEphysNidq') && ~isempty(sFiles(intFile).sEphysNidq)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = ['NI stream data at: ' sFiles(intFile).sEphysNidq.name];
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Did not find NI stream data';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN dblH];
		sPointers(intFile).NI = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3)*2;
		
		%sFiles.name %file name
		strText = sFiles(intFile).sMeta.strNidqName;
		if numel(strText) > 47
			strText = [strText(1:45) '...'];
		end
		strTip = [sFiles(intFile).sMeta.strNidqName ' at ' sFiles(intFile).sEphysNidq.folder];
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzName dblH];
		sPointers(intFile).Name = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles.date %date
		strDate = num2str(yyyymmdd(datetime(sFiles(intFile).sEphysNidq.date,'Locale','system')));
		strText = strDate;
		strTip = sFiles(intFile).sEphysNidq.date;
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzDate dblH];
		sPointers(intFile).Date = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%compile total size of all files
		cellFields = fieldnames(sFiles(intFile));
		vecTotSize = zeros(1,numel(cellFields));
		strSize = [];
		for intField=2:numel(cellFields)
			if ~isfield(sFiles(intFile).(cellFields{intField}),'name')
				continue;
			end
			cellFiles = {sFiles(intFile).(cellFields{intField}).name};
			cellFolders = {sFiles(intFile).(cellFields{intField}).folder};
			dblSize = 0;
			for intSubFile=1:numel(cellFiles)
				dblSize = dblSize + sum(cellfun(@sum,{sFiles(intFile).(cellFields{intField}).bytes}));
				[a,strFile,strExt]=fileparts(cellFiles{intSubFile});
				if strcmp(strExt,'.meta')
					sTempFile = dir(fullpath(cellFolders{intSubFile},[strFile '.bin']));
					if isempty(sTempFile)
						warning([mfilename ':BinaryFileNotFound'],sprintf('Binary file for %s is missing!',cellFiles{intSubFile}));
						sPointers(intFile).AP.String = 'N';
						sPointers(intFile).AP.ForegroundColor = [0.8 0 0];
						sPointers(intFile).AP.(strTooltipField) = 'Did not find AP channel data';
					else
						dblSize = dblSize + sTempFile.bytes;
					end
				end
			end
			vecTotSize(intField) = dblSize;
			strSize = [strSize cellFields{intField}(2:end) '=' sprintf('%.1fGB\n',dblSize/(1024^3))];
		end
		
		%sFiles.bytes %date
		strText = sprintf('%.1fGB',sum(vecTotSize)/(1024^3));
		strTip = [sprintf('Size per component:\n') strSize];
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzBytes dblH];
		sPointers(intFile).Bytes = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','FontSize',10,strTooltipField,strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
	end
	
	%show panel
	RP_SliderCallback(ptrSlider,[],ptrPanelChild);
end