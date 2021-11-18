function [dblInstalledVersion,strKilosortPath] = RP_AssertKilosort()
	
	%check for kilosort3 or kilosort2.5
	strK3 = which('purge_rez');
	strK2 = which('learnAndSolve8b');
	if ~isempty(strK3)
		dblInstalledVersion = 3;
	elseif ~isempty(strK2)
		dblInstalledVersion = 2;
	else
		dblInstalledVersion = 0;
	end
	
	%check if CUDA files are compiled
	strGPU = which('spikedetector3');
	if dblInstalledVersion>0 && isempty(strGPU)
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
	
	%check
	strGPU = which('spikedetector3');
	if nargout > 1 && dblInstalledVersion>0
		cellPath = strsplit(strGPU,filesep);
		strKilosortPath = fullpath(cellPath{1:(end-2)});
	else
		strKilosortPath = '';
	end
end