function RP_Scrollwheel(hObject,eventdata)
	global sFigRP;
	
	if ~isfield(sFigRP,'ptrSliderLibrary') || isempty(sFigRP.ptrSliderLibrary),return;end
	
	%calculate new position
	dblMove = eventdata.VerticalScrollCount*eventdata.VerticalScrollAmount;
	dblNewVal = sFigRP.ptrSliderLibrary.Value - dblMove/100;
	if dblNewVal < 0
		dblNewVal = 0;
	end
	if dblNewVal > 1
		dblNewVal = 1;
	end
	
	%move slider
	sFigRP.ptrSliderLibrary.Value = dblNewVal;
	
	%change window
	RP_SliderCallback(sFigRP.ptrSliderLibrary,[],sFigRP.ptrSliderLibrary.Callback{2});
	
end