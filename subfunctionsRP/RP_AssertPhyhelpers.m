function dblInstalledVersion = RP_AssertPhyhelpers()
	
	%check for helpers
	strFile1=which('loadKSdir');
	strFile2=which('templatePositionsAmplitudes');
	if ~isempty(strFile1) && ~isempty(strFile2)
		dblInstalledVersion = 1;
	else
		dblInstalledVersion = 0;
	end
end