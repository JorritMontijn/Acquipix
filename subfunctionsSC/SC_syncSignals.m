function [vecAlignedTime,vecRefinedT,vecError,sSyncStruct] = SC_syncSignals(vecReferenceT,vecNoisyHighResT,sUserVars)
	%SC_syncSignals Synchronize signals
	%   [vecAlignedTime,vecRefinedT,vecError,sSyncStruct] = SC_syncSignals(vecReferenceT,vecNoisyHighResT,sUserVars)
	%optional input: sUserVars
	%optional output: sSyncStruct
	
	%remove all events that are not close to the reference
	dblPrePostWindow = 1.5;
	indRemEvents = vecNoisyHighResT < (vecReferenceT(1)-dblPrePostWindow) ...
		| vecNoisyHighResT > (vecReferenceT(end)+dblPrePostWindow);
	vecNoisyHighResT(indRemEvents) = [];
	
	%go through onsets to check which one aligns with timings
	intEventNum = numel(vecNoisyHighResT);
	vecError = nan(1,intEventNum);
	vecDurCorr = nan(1,intEventNum);
	vecRealDur = diff(vecReferenceT);
	parfor intStartEvent=1:intEventNum
		%select onsets
		vecUseSignalOnT = vecNoisyHighResT(intStartEvent:end);
		
		%get ON times
		[vecRefinedT,vecIntervalError] = SC_refineDiffT(vecReferenceT-vecReferenceT(1),vecUseSignalOnT-vecUseSignalOnT(1));
		vecRefinedDur = diff(vecRefinedT);
		vecError(intStartEvent) = nansum(vecIntervalError.^2);
		vecDurCorr(intStartEvent) = corr(vecRefinedDur',vecRealDur');
	end
	[dblMin,intStartEvent] = min(vecError);
	dblStartT = vecNoisyHighResT(intStartEvent);
	[dblMax,intStartEventR] = max(vecDurCorr);
	
	%check if any events are present
	if numel(vecError) < 2
		vecAlignedTime = vecReferenceT;
		vecRefinedT = vecReferenceT;
		vecError = zeros(size(vecReferenceT));
		if nargout > 3
			sSyncStruct = struct;
			sSyncStruct.vecIntervalError = vecError;
			sSyncStruct.dblFirstError = vecRefinedT(1);
			sSyncStruct.vecAlignedTime0 = vecRefinedT;
			sSyncStruct.intStartEvent = [];
		end
		return;
	end
	
	%% calculate probability & request input if low
	%get probability
	[vecP,vecMax10]=findmax(-vecError,10);
	vecSoftmin = softmax(vecP(~isnan(vecP)));
	[vecP,vecI]=findmax(vecSoftmin,10);
	dblAlignmentCertainty = vecP(1)/nansum(vecP);
	fprintf('Aligned events with %.3f%% certainty; start stim is at t=%.3fs\n',dblAlignmentCertainty*100,dblStartT);
	if dblAlignmentCertainty < 0.9 || isnan(dblAlignmentCertainty) || (intStartEventR ~= intStartEvent)
		if ~exist('sUserVars','var') || isempty(sUserVars)
			warning([mfilename ':UncertainAlignment'],'Uncertain alignment & variables for manual intervention were not supplied');
		else
			%message
			fprintf('\n << Alignment certainty of %s is under 90%%, please check manually >>\n',sUserVars.strType);
			[dblStartHiDefT,dblUserStartT] = askUserForSyncTimes(sUserVars.vecSignalVals,sUserVars.vecSignalTime,sUserVars.intBlockNr,vecReferenceT);
			
			%re-align
			[dblMin,intStartEvent] = min(abs(vecNoisyHighResT-dblStartHiDefT));
			intIndex = find(vecMax10==intStartEvent,1);
			if isempty(intIndex)
				dblProb = 0;
			else
				dblProb = vecP(intIndex)/sum(vecP);
			end
			
			%message
			fprintf('My guess (%.3f%% confidence): %.3fs; your guess: %.3fs (I gave it %.3f%% probability)\n',dblAlignmentCertainty*100,dblStartT,dblStartHiDefT,dblProb*100);
			dblStartT = dblStartHiDefT;
		end
	end
	
	%re-run alignment for chosen stimulus
	vecUseSignalOnT = vecNoisyHighResT(intStartEvent:end) - vecNoisyHighResT(intStartEvent);
	[vecRefinedT,vecIntervalError] = SC_refineDiffT(vecReferenceT-vecReferenceT(1),vecUseSignalOnT);
	
	%replace out-of-bounds values
	dblMaxErrZ = 5;
	indReplace = abs(zscore(vecIntervalError)) > dblMaxErrZ;
	dblMedianError = median(vecIntervalError(~indReplace));
	dblMeanAbsErr = mean(abs(vecIntervalError(~indReplace)));
	
	%replace
	vecAlignedTime0 = vecRefinedT;
	vecAlignedTime0(indReplace) = vecAlignedTime0(indReplace) + vecIntervalError(indReplace) + dblMedianError;
	
	%recenter
	dblFirstError = vecAlignedTime0(1);
	vecAlignedTime = vecAlignedTime0 + dblStartT;
	dblAlignment = vecAlignedTime(1) - vecReferenceT(1);
	
	%get type
	if exist('sUserVars','var') && isfield(sUserVars,'strType')
		strType = [sUserVars.strType ' '];
	else
		strType = '';
	end
	fprintf('Mean duration error after alignment by %.3fs is %.3fs for %s sync events; %d events refined by median\n',...
		dblAlignment,dblMeanAbsErr,strType,sum(indReplace));
	
	
	%% build output
	if nargout > 3
		sSyncStruct = struct;
		sSyncStruct.vecIntervalError = vecIntervalError;
		sSyncStruct.dblFirstError = dblFirstError;
		sSyncStruct.vecAlignedTime0 = vecAlignedTime0;
		sSyncStruct.intStartEvent = intStartEvent;
	end
end

