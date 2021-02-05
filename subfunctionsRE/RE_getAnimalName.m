function strRecording = RE_getAnimalName()

	sOpt = struct;
	sOpt.Interpreter = 'tex';
	sOpt.Default = 'OK';
	boolAccept = false;
	while ~boolAccept
		strRecording = inputdlg('\fontsize{10} Enter animal name:','Experiment ID',[1 40],{''},sOpt);
		if isempty(strRecording)
			sFigRE.IsRunning = false;
			close(ptrMainGUI);
			break;
		end
		cellExpr = regexp(strRecording,'(?![_])\w','match');
		strRecording2 = flat(char(cell2vec(cellExpr{1})))';
		if isempty(strRecording2)
			continue;
		elseif strcmp(strRecording,strRecording2)
			boolAccept = true;
		else
			strAns = questdlg(['\fontsize{10} Name will be: "' strRecording2 '"'],'Experiment ID','OK','Cancel',sOpt);
			if strcmp(strAns,'OK')
				boolAccept = true;
				strRecording = strRecording2;
			end
		end
	end
	strRecording = char(strRecording);
end