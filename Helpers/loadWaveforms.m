function [sAggStim,sAggNeuron] = loadWaveforms(sAggStim,sAggNeuron)
	%loadWaveforms Adds the average waveform per cluster to the supplied sAggNeuron structure
	%	[sAggStim,sAggNeuron] = loadWaveforms(sAggStim,sAggNeuron)
	%
	%Input:
	%- sAggStim: single recording, first output of loadDataNpx.m
	%- sAggNeuron: aggregate neuron structure, second output of loadDataNpx.m
	%
	%Output:
	%- sAggStim: same as input, adds fields .sample_rate and.KSdir
	%- sAggNeuron: same as input, adds field .Waveform
	%
	%Note: this is simply a wrapper for the getWaveformPerCluster.m function
	%
	%2022-03-02 by Jorrit Montijn
	
	%% load raw data file
	hTic=tic;
	intFiles = numel(sAggStim);
	for intFile=1:intFiles
		%prep
		strRec = sAggStim(intFile).Exp;
		sThisRec = sAggStim(strcmpi(strRec,{sAggStim(:).Exp}));
		if toc(hTic) > 5
			hTic=tic;
			fprintf('Loading recording %d/%d: %s [%s]\n',intFile,intFiles,strRec,getTime);
		end
		
		%load
		sLoad = load(sThisRec.File);
		sAP = sLoad.sAP;
		sFile = sAP.sSources;
		strPathAP = sFile.sEphysAp.folder;
		try
			try
				strPathKS = strPathAP;
				sSpikes = loadKSdir(strPathKS);
			catch
				strPathKS = fullpath(strPathAP,'kilosort3');
				sSpikes = loadKSdir(strPathKS);
			end
		catch
			%cannot find file, ask user for folder
			
		end
		vecAllSpikeClust = sSpikes.clu;
		vecClustIdx = unique(vecAllSpikeClust);
		sAggStim(intFile).sample_rate = sSpikes.sample_rate;
		sAggStim(intFile).KSdir = strPathKS;
		
		%% load chanmap file
		if isfield(sFile.sClustered,'ops') && isfield(sFile.sClustered.ops,'chanMap')
			%get customized chan map file
			strChanMapFile = sFile.sClustered.ops.chanMap;
		else
			%otherwise get default
			sRP = RP_populateStructure();
			strPathToConfigFile = sRP.strConfigFilePath;
			strConfigFileName = sRP.strConfigFileName;
			
			% get config file data
			%get initial ops struct
			ops = struct;
			run(fullpath(strPathToConfigFile, strConfigFileName));
			strChanMapFile = ops.chanMap;
		end
		sChanMap = load(strChanMapFile);
		dblLength = range(sChanMap.ycoords) + median(diff(sort(unique(sChanMap.ycoords))));
		%invert channel depth
		sSpikes.ycoords = dblLength - sSpikes.ycoords;
		
		%load properties
		[vecClustIdx,matClustWaveforms] = getWaveformPerCluster(sSpikes,vecClustIdx);
		
		%% prepare spiking cell array
		indQualifyingNeurons = contains({sAggNeuron.Exp},strRec);
		vecFindNeurons = find(indQualifyingNeurons);
		for intNeuron=1:numel(vecFindNeurons)
			intNeuronEntry = vecFindNeurons(intNeuron);
			vecClustWaveform = matClustWaveforms(sAggNeuron(intNeuronEntry).IdxClust == vecClustIdx,:);
			sAggNeuron(intNeuronEntry).Waveform = vecClustWaveform;
		end
	end
end