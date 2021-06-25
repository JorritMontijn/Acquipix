function dblInstalledVersion = RP_AssertNpy()
	
	%check for kilosort3
	strNpy1=which('readNPY');
	if ~isempty(strNpy1)
		dblInstalledVersion = 1;
	else
		dblInstalledVersion = 0;
	end
end