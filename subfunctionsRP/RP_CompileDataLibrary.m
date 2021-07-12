function sFiles = RP_CompileDataLibrary(sRP,ptrText)
	
	%%
	%strOutputPath: 'D:\Data\Processed\Neuropixels'
	%       strTempPath: 'E:\_TempData'
	%      strEphysPath: 'D:\Data\Raw\Neuropixels'
	%    strStimLogPath: 'D:\Data\Raw\Neuropixels'
	%strEyeTrackingPath: 'D:\Data\Raw\Neuropixels'
	%   strProbeLocPath: 'D:\Data\Raw\Neuropixels'
	
	%% compile potential raw SpikeGLX ephys files (using Nidq as master)
	sPossibleEphysFiles = dir(fullfile(sRP.strEphysPath, '**','*.meta'));
	cellEphysFilesNidq = regexp({sPossibleEphysFiles.name},sRP.strEphysRegExpNidq);
	sEphysFilesNidq = sPossibleEphysFiles(~cellfun(@isempty,cellEphysFilesNidq));
	
	%% compile potential stim files
	sAllStimMatStimFiles = dir(fullfile(sRP.strStimLogPath, '**','*.mat'));
	cellStimFiles = regexp({sAllStimMatStimFiles.name},sRP.strStimLogRegExpStim);
	sPossibleStimFiles = sAllStimMatStimFiles(~cellfun(@isempty,cellStimFiles));
	
	%% compile potential pupil files
	sAllPupilMatFiles = dir(fullfile(sRP.strEyeTrackingPath, '**','*Processed*.mat'));
	cellPupilFiles = regexp({sAllPupilMatFiles.name},sRP.strEyeTrackingRegExpVid);
	sPossiblePupilFiles = sAllPupilMatFiles(~cellfun(@isempty,cellPupilFiles));
	
	%% group files
	indDelete=false(1,numel(sEphysFilesNidq));
	sFiles = [];
	for intFile=1:numel(sEphysFilesNidq)
		%% nidq
		sEphysNidq = sEphysFilesNidq(intFile);
		strNidqFile = sEphysNidq.name;
		strNidqPath = sEphysNidq.folder;
		try
			if ~strcmp(strNidqPath(end),filesep),strNidqPath(end+1)=filesep;end
			sMeta = DP_ReadMeta(strNidqFile, strNidqPath);
			[dummy,strNidqName] = fileparts(sMeta.fileName);
			strNidqName = strrep(strNidqName,'.nidq','');
			sMeta.strNidqName = strNidqName;
			
			%extract date
			[intB,intE]=regexp(strNidqFile,'(\d{4}[-/]?(\d{2})[-/]?\d{2})');
			strDate1 = strrep(strNidqFile(intB:intE),'-','');
			strDate2 = strjoin({strDate1(1:4),strDate1(5:6),strDate1(7:8)},'-');
			
			if exist('ptrText','var') && ~isempty(ptrText)
				ptrText.String = sprintf('Compiling data library...\nFound %d recordings',sum(~indDelete(1:intFile)));
				drawnow;
			end
		catch
			indDelete(intFile) = true;
			continue;
		end
		
		%% ap
		strApFile = strrep(strNidqFile,'nidq','imec*.ap');
		sEphysAp = dir(fullfile(sRP.strEphysPath, '**',strApFile));
		
		%% lf
		strLfFile = strrep(strNidqFile,'nidq','imec*.lf');
		sEphysLf = dir(fullfile(sRP.strEphysPath, '**',strLfFile));
		
		%% processed kilosort data
		sClustered = dir(strcat(strNidqPath,sRP.strEphysFindClustered));
		if isempty(sClustered)
			%try /kilosort3/ subfolder
			sClustered = dir(fullpath(strNidqPath,'kilosort3',sRP.strEphysFindClustered));
		end
		if isempty(sClustered)
			%if still empty, try any subfolder
			sClustered = dir(fullpath(strNidqPath,'**',sRP.strEphysFindClustered));
			if numel(sClustered) > 1
				error([mfilename ':MultipleSortedFiles'],'Multiple sorted cluster files found in subdirectories of "%s"',strNidqPath);
			end
		end
		
		%% synthesized data
		sSynthesis = dir(strcat(strNidqPath,sRP.strEphysFindSynthesis));
		if isempty(sSynthesis)
			%try /kilosort3/ subfolder
			sSynthesis = dir(fullpath(strNidqPath,'kilosort3',sRP.strEphysFindSynthesis));
		end
		
		%% raw stimulus files
		cellPossibleStimFiles = {sPossibleStimFiles.name};
		indPossFiles = contains(cellPossibleStimFiles,strDate1) | contains(cellPossibleStimFiles,strDate2);
		sSameDateStimFiles = sPossibleStimFiles(indPossFiles);
		sStimFiles = sSameDateStimFiles;
		sStimFiles(:)=[];
		%check if spikeglx run name matches
		for intStimFile=1:numel(sSameDateStimFiles)
			sLoad=load(fullpath(sSameDateStimFiles(intStimFile).folder,sSameDateStimFiles(intStimFile).name));
			if isfield(sLoad,'sParamsSGL') && isfield(sLoad.sParamsSGL,'snsRunName')
				strRunName = sLoad.sParamsSGL.snsRunName;
			elseif isfield(sLoad,'structEP') && isfield(sLoad.structEP,'strRecording')
				strRunName = sLoad.structEP.strRecording;
			else
				continue;
			end
			if strcmp(strRunName,strNidqName(1:numel(strRunName))) || (numel(strNidqName) > (numel(strRunName)+2) && strcmp(strRunName,strNidqName(4:(numel(strRunName)+3))))
				%match
				sStimFiles(end+1) = sSameDateStimFiles(intStimFile);
			end
		end
		if isempty(sStimFiles) && ~isempty(sSameDateStimFiles)
			warning([mfilename ':MatchingByDate'],'No matching stim file names were found; matching by date only. Please double-check the matched files.');
			sStimFiles = sSameDateStimFiles;
		end
		
		%% processed eye-tracking data
		cellPossiblePupilFiles = {sPossiblePupilFiles.name};
		indPossFiles = contains(cellPossiblePupilFiles,strDate1) | contains(cellPossiblePupilFiles,strDate2);
		sSameDatePupilFiles = sPossiblePupilFiles(indPossFiles);
		sPupilFiles = sSameDatePupilFiles;
		sPupilFiles(:)=[];
		warning('off','MATLAB:elementsNowStruc');
		%check if spikeglx run name matches
		for intPupilFile=1:numel(sSameDatePupilFiles)
			sLoad=load(fullpath(sSameDatePupilFiles(intPupilFile).folder,sSameDatePupilFiles(intPupilFile).name));
			if isfield(sLoad.sPupil,'sParamsSGL')
				strRunName = sLoad.sPupil.sParamsSGL.snsRunName;
				if strcmp(strRunName,strNidqName(1:numel(strRunName)))
					%match
					sPupilFiles(end+1) = sSameDatePupilFiles(intPupilFile);
				end
			else
				%cannot check run name, so we'll just add it anyway
				sPupilFiles(end+1) = sSameDatePupilFiles(intPupilFile);
			end
		end
		warning('on','MATLAB:elementsNowStruc');
		
		%% histology/probe location data
		sProbeCoords = []; %to do
		
		%% assign data
		sFiles(intFile).sMeta = sMeta;
		sFiles(intFile).sEphysNidq = sEphysNidq;
		sFiles(intFile).sEphysAp = sEphysAp;
		sFiles(intFile).sEphysLf = sEphysLf;
		sFiles(intFile).sClustered = sClustered;
		sFiles(intFile).sSynthesis = sSynthesis;
		sFiles(intFile).sStimFiles = sStimFiles;
		sFiles(intFile).sPupilFiles = sPupilFiles;
		sFiles(intFile).sProbeCoords = sProbeCoords;
	end
	sFiles(indDelete) = [];
end