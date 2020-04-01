function [vecStimResp,vecBaseResp] = getTrialResp(vecSpikeTimes,vecStimOn,vecStimOff)
	%getTrialResp Transforms spiking data into epoch rate.
	%syntax 1: [vecStimResp,vecBaseResp] = getTrialResp(vecSpikeTimes,vecStimOn,vecStimOff)
	%syntax 2: [matStimResp,matBaseResp] = getTrialResp(cellSpikeTimes,vecStimOn,vecStimOff)
	%
	%Version history:
	%1.0 - 27 March 2020
	%	Created by Jorrit Montijn
	
	%% parse inputs
	vecStimOn = vecStimOn(:);
	if ~exist('vecStimOff','var')
		vecStimOff = [vecStimOn(2:end);vecStimOn(end) + median(diff(vecStimOn))];
	end
	vecStimOff = vecStimOff(:);
	vecEvents = sort([vecStimOn(1)-1;vecStimOn;vecStimOff],'ascend');
	
	%% process
	if iscell(vecSpikeTimes)
		cellCounts = cellfun(@histcounts,vecSpikeTimes,cellfill(vecEvents,size(vecSpikeTimes)),'uniformoutput',false);
		vecBaseResp = cell2mat(cellfun(@(x) x(1:2:end),cellCounts,'uniformoutput',false)');
		vecStimResp = cell2mat(cellfun(@(x) x(2:2:end),cellCounts,'uniformoutput',false)');
	else
		vecCounts = histcounts(vecSpikeTimes,vecEvents);
		vecBaseResp = vecCounts(1:2:end);
		vecStimResp = vecCounts(2:2:end);
	end
end

