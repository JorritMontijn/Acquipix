function [vecClustIdx,matClustWaveforms] = getWaveformPerCluster(sSpikes,vecClustIdx)
	% getWaveformPerCluster Computes the average waveform per cluster
	% [vecClustIdx,matClustWaveforms] = getWaveformPerCluster(sSpikes, vecClustIdx)
	%
	%Input:
	%- sSpikes: output of loadKSdir(), a function in the "spikes" repository: https://github.com/cortex-lab/spikes
	%- [vecClustIdx]: optional; which clusters to return; if none supplied, it returns all clusters
	%
	%Output:
	%- vecClustIdx: list of cluster indices [n x 1], match them to clusters in sAP using:
	%					vecClustWaveform = matClustWaveforms(sAP.sCluster(i).IdxClust == vecClustIdx,:)
	%- matClustWaveforms: matrix of waveforms [n x p]
	%					n is the number of clusters, 
	%					p is the number of samples per waveform (as supplied by sSpikes.temps)
	%
	%2021-11-05 by Jorrit Montijn, as an extension for the "spikes" repository
	
	%unpack structure
	temps = sSpikes.temps;
	winv = sSpikes.winv;
	clu = sSpikes.clu;
	spikeTemplates = sSpikes.spikeTemplates;
	
	%which clusters?
	if ~exist('vecClustIdx','var') || isempty(vecClustIdx)
		vecClustIdx = unique(clu);
	end
	
	%unwhiten templates
	tempsUnW = zeros(size(temps));
	for t = 1:size(temps,1)
		tempsUnW(t,:,:) = squeeze(temps(t,:,:))*winv;
	end
	
	% The amplitude on each channel is the positive peak minus the negative
	tempChanAmps = squeeze(max(tempsUnW,[],2))-squeeze(min(tempsUnW,[],2));
	
	%get waveform per template
	intTemplateNum = size(tempChanAmps,1);
	matMaxWF = nan(intTemplateNum,size(tempsUnW,2));
	for intT = 1:intTemplateNum
		theseChanAmps = tempChanAmps(intT,:);
		matMaxWF(intT,:) = tempsUnW(intT,:,find(theseChanAmps==max(theseChanAmps),1));
	end
	
	%get weighted waveform per cluster
	matClustWaveforms = nan(numel(vecClustIdx),size(tempsUnW,2));
	for intClust=1:numel(vecClustIdx)
		intClustIdx = vecClustIdx(intClust);
		matClustWaveforms(intClust,:)=mean(matMaxWF(spikeTemplates(clu==intClustIdx)+1,:),1);
	end