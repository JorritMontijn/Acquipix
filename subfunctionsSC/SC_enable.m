function SC_enable(handles)
	%SC_enable Shared Core GUI enabler
	%   SC_enable(handles)
	%'UserData','unlock'
	
	cellNames = fieldnames(handles);
	for intPtr=1:numel(cellNames)
		if ~isempty(strfind(cellNames{intPtr},'ptrButton')) ||...
				~isempty(strfind(cellNames{intPtr},'ptrList')) ||...
				~isempty(strfind(cellNames{intPtr},'ptrEdit'))
			if strcmpi(get(handles.(cellNames{intPtr}),'UserData'),'lock')
				set(handles.(cellNames{intPtr}),'UserData','unlock');
			end
		end
	end
end

