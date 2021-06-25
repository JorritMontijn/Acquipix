function dblInstalledVersion = RP_AssertKilosort()
	
	%check for kilosort3
	strK3=which('datashift2');
	strK2 = which('learnAndSolve8b');
	if ~isempty(strK3)
		dblInstalledVersion = 3;
		
		%check if files are compiled
		strGPU = which('spikedetector3');
		if isempty(strGPU)
			%attempt compilation
			strCompileGPU = which('mexGPUall');
			
			if isempty(strCompileGPU)
				%error
				strMsg = 'Cannot find compiled Kilosort GPU code, nor a suitable compiler.';
				errordlg(strMsg,'GPU code not found');
			else
				try
					ptrWarn = warndlg('Attempting to compile GPU-accelerated mex files','Warning');
					strPath = fileparts(strCompileGPU);
					strOldPath = cd(strPath);
					run(strCompileGPU);
					cd(strOldPath);
					delete(ptrWarn);
				catch ME
					%show message
					delete(ptrWarn);
					strMsg = sprintf('Attempt to compile Kilosort GPU code failed:\n%s',ME.message);
					errordlg(strMsg,'GPU code not found');
				end
			end
			
		end
	elseif ~isempty(strK2)
		dblInstalledVersion = 2;
	else
		dblInstalledVersion = 0;
	end
end