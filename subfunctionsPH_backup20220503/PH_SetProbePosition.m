function PH_SetProbePosition(hMain,varargin)
	
	% Get guidata
	gui_data = guidata(hMain);
	
	% Prompt for angles
	prompt_text = { ...
		'AP position (\mum from bregma)', ...
		'ML position (\mum from bregma)', ...
		'Depth (\mum below bregma)', ...
		'AP angle', ....
		'ML angle'};
	cellInput = inputdlg(prompt_text,'Set probe position',1);
	if isempty(cellInput)
		return
	end
	cellInput(cellfun(@isempty,cellInput)) = {'0'};
	new_probe_position = cellfun(@str2num,cellInput)';
	
	% Convert probe position: mm->CCF and degrees->radians
	probe_ccf_coordinates = round(gui_data.bregma - [new_probe_position(1) new_probe_position(3) new_probe_position(2)]/10);
	probe_ccf_coordinates(2,:) = probe_ccf_coordinates(1,:) + [0 3840+new_probe_position(2) 0]/10;
	
	PH_SetProbeLocation(hMain,probe_ccf_coordinates);
	PH_UpdateProbeAngle(hMain,new_probe_position(4:5));
	
end

