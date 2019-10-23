function strFile = getStimTexDB(cellTexDB,sStimObject)
	%getStimTexDB Finds stimulus texture file from database
	%	 strFile = getStimTexDB(cellTexDB,sStimObject);
	
	%pre-allocate
	strFile = '';
	%check all entries
	for intFile=1:size(cellTexDB,1)
		%get saved object
		sThisStimObject = cellTexDB{intFile,2};
		try
			if isMatchStimObj(sStimObject,sThisStimObject)
				strFile = cellTexDB{intFile,1};
				return;
			end
		catch ME
			error([mfilename ':IncorrectFieldType'],sprintf('%s of file %s (object %d in TexDB)',...
						ME.message,cellTexDB{intFile,1},intFile)); %#ok<SPERR>
		end
	end
end
	
	