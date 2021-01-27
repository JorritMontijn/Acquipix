function sPanelSettings = SC_getPanelSettings(ptrPanel)
	sPanelSettings = struct;
	objEntries = ptrPanel.Children;
	for intEntry=numel(objEntries):-1:1
		if mod(intEntry,2) == 0
			%fieldname
			strField = objEntries(intEntry).String;
		else
			%value
			strVal = objEntries(intEntry).String;
			try
				sPanelSettings.(strField) = eval(strVal);
			catch
				try
					sPanelSettings.(strField) = str2num(strVal);
				catch
					sPanelSettings.(strField) = strVal;
				end
			end
		end
	end
end