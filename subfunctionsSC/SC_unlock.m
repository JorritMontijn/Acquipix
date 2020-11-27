function SC_unlock(handles)
	%SC_unlock Shared Core GUI unlocker
	%   SC_unlock(handles)
	%Enable,'off'
	
	cellNames = fieldnames(handles);
	for intPtr=1:numel(cellNames)
		if ~isempty(strfind(cellNames{intPtr},'ptrButton')) ||...
				~isempty(strfind(cellNames{intPtr},'ptrList')) ||...
				~isempty(strfind(cellNames{intPtr},'ptrEdit'))
			if ~strcmpi(get(handles.(cellNames{intPtr}),'UserData'),'lock')
				set(handles.(cellNames{intPtr}),'Enable','on');
			end
		end
	end
end

