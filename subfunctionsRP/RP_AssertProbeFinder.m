function dblInstalledVersion = RP_AssertProbeFinder()
	
	%check for helpers
	strFile1=which('UniversalProbeFinder');
	strFile2=which('PF_getIniVar');
	if ~isempty(strFile1) && ~isempty(strFile2)
		dblInstalledVersion = 1;
	else
		dblInstalledVersion = 0;
	end
end