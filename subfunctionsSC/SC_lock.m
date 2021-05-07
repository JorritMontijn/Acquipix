function SC_lock(handles)
	%SC_lock Shared Core GUI locker
	%   SC_lock(handles)
	%Enable,'off'
	
	cellNames = fieldnames(handles);
	for intPtr=1:numel(cellNames)
		if (~isempty(strfind(cellNames{intPtr},'ptrButton')) || ...
				~isempty(strfind(cellNames{intPtr},'ptrList')) || ...
				~isempty(strfind(cellNames{intPtr},'ptrEdit'))) && ...
				isempty(strfind(cellNames{intPtr},'ptrButtonSave'))
			set(handles.(cellNames{intPtr}),'Enable','off');
			if strcmpi(get(handles.(cellNames{intPtr}),'UserData'),'lock')
				set(handles.(cellNames{intPtr}),'UserData','unlock');
			end
		end
	end
end

