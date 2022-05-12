function PH_DelayDeleteFcn(hTimer,eventdata,hObject)
	%get data
	if strcmp(hObject.UserData,'close')
		try
			delete(hObject);
		catch
		end
	end
end