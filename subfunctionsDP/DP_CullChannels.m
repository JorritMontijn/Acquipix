function [vecUseChannelsFilt,vecUseChannelsOrig] = DP_CullChannels(vecSpikeCh,vecSpikeT,dblTotT,sP,sChanMap)
	%DP_CullChannels Decides which channels to use
	%	[vecUseChannelsFilt,vecUseChannelsOrig] = DP_CullChannels(vecSpikeCh,vecSpikeT,dblTotT,sP,sChanMap);
	%
	%input:
	% - vecSpikeCh [S x 1]: vector with channel index per spike
	% - vecSpikeT [S x 1]: vector with timestamp in ms per spike
	% - dblTotT [double]: total time of recording
	% - sP [struct]: structure containing parameters, same as KiloSort2's ops
	% - sChanMap [struct]: structure containing probe configuration data
	%
	%output:
	% - vecUseChannelsFilt; vector containing good channels (smoothed)
	% - vecUseChannelsOrig; vector containing good channels (unsmoothed)
	%
	%Version history:
	%1.0 - 5 Dec 2019
	%	Created by Jorrit Montijn
	
	%get y step
	vecY = sChanMap.ycoords;
	vecAllY = unique(vecY);
	vecStepsY = diff(sort(vecY));
	dblStepY = min(vecStepsY(vecStepsY>0));
	
	%get x step
	vecX = sChanMap.xcoords;
	vecAllX = unique(vecX);
	vecStepsX = diff(sort(vecX));
	dblStepX = min(vecStepsX(vecStepsX>0));
	
	%get biggest
	dblMaxStep = max(dblStepY,dblStepX);
	
	%get greatest common divisor
	dblStepBoth = gcd(dblStepY,dblStepX);
	
	%build grids
	vecGridX = (min(vecX)-dblMaxStep):dblStepBoth:(max(vecX)+dblMaxStep);
	vecGridY = (min(vecY)-dblMaxStep):dblStepBoth:(max(vecY)+dblMaxStep);
	[matMapX,matMapY] = meshgrid(vecGridX,vecGridY);
	
	%get spike rate per channel
	vecSpikeRatePerChannel = gather(accumarray(vecSpikeCh,1) ./ dblTotT);
	vecSpikeRatePerChannel(end+1:numel(vecY)) = 0;
	
	%interpolate
	objInterp = scatteredInterpolant(vecX,vecY,vecSpikeRatePerChannel,'linear','linear');
	matGridAct = objInterp(matMapX,matMapY);
	
	%2D smooth
	vecSpreadFilt = -2*dblMaxStep:dblStepBoth:2*dblMaxStep;
	matFilt = normpdf(vecSpreadFilt,0,dblMaxStep)' * normpdf(vecSpreadFilt,0,dblMaxStep);
	matFilt = matFilt ./ sum(matFilt(:));
	matFiltAct = conv2(matGridAct,matFilt,'same');
	
	%recover original points
	vecFiltAct = nan(size(vecY));
	for intPoint=1:numel(vecFiltAct)
		%retrieve
		vecFiltAct(intPoint) = matFiltAct(vecX(intPoint)==matMapX & vecY(intPoint)==matMapY);
	end
	
	%define which channels to use
	vecUseChannelsFilt = find(vecFiltAct > sP.minfr_goodchannels);
	vecUseChannelsOrig = find(vecSpikeRatePerChannel > sP.minfr_goodchannels);
