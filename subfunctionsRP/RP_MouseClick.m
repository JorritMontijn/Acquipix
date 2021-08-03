function RP_MouseClick(hObject,eventdata)
	global sFigRP;
	
	mousePos=get(hObject,'CurrentPoint');
	if strcmp(eventdata.Source.SelectionType,'normal') %left
		x=eventdata.Source;
	elseif strcmp(eventdata.Source.SelectionType,'alt') %right
		x=eventdata.Source;
	elseif strcmp(eventdata.Source.SelectionType,'extend') %middle
		
	end
end