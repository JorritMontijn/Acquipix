function [vecAlignedTime,vecRefinedT,vecError,sSyncStruct] = SC_syncSignals(vecReferenceT,vecNoisyHighResT,sUserVars)
	%SC_syncSignals Synchronize signals
	%   [vecAlignedTime,vecRefinedT,vecError,sSyncStruct] = SC_syncSignals(vecReferenceT,vecNoisyHighResT,sUserVars)
	%optional input: sUserVars
	%optional output: sSyncStruct
	
	%go through onsets to check which one aligns with timings
	intEventNum = numel(vecNoisyHighResT);
	vecError = nan(1,intEventNum);
	parfor intStartEvent=1:intEventNum
		%select onsets
		vecUseSignalOnT = vecNoisyHighResT(intStartEvent:end) - vecNoisyHighResT(intStartEvent);
		%vecUseSignalOnT = vecSignalOnT - vecSignalOnT(intStartStim);
		
		%get ON times
		[vecRefinedT,vecIntervalError] = SC_refineDiffT(vecReferenceT,vecUseSignalOnT);
		vecError(intStartEvent) = nansum(vecIntervalError.^2);
	end
	[dblMin,intStartEvent] = min(vecError);
	dblStartT = vecNoisyHighResT(intStartEvent);
	
	
	%% calculate probability & request input if low
	%get probability
	[vecP,vecMax10]=findmax(-vecError,10);
	vecSoftmin = softmax(vecP);
	[vecP,vecI]=findmax(vecSoftmin,10);
	dblAlignmentCertainty = vecP(1)/sum(vecP);
	fprintf('Aligned events with %.3f%% certainty; start stim is at t=%.3fs\n',dblAlignmentCertainty*100,dblStartT);
	if dblAlignmentCertainty < 0.9 || isnan(dblAlignmentCertainty)
		if ~exist('sUserVars','var') || isempty(sUserVars)
			warning([mfilename ':UncertainAlignment'],'Uncertain alignment & variables for manual intervention were not supplied');
		else
			%message
			fprintf('\n << Alignment certainty of %s is under 90%%, please check manually >>\n',sUserVars.strType);
			[dblStartHiDefT,dblUserStartT] = askUserForSyncTimes(sUserVars.vecSignalVals,sUserVars.vecSignalTime,sUserVars.intBlockNr);
			
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
	[vecRefinedT,vecIntervalError] = SC_refineDiffT(vecReferenceT,vecUseSignalOnT);
	
	%replace out-of-bounds values
	dblMaxErrZ = 5;
	indReplace = abs(zscore(vecIntervalError)) > dblMaxErrZ;
	dblMedianError = median(vecIntervalError(~indReplace));
	dblMeanAbsErr = mean(abs(vecIntervalError(~indReplace)));
	
	%replace
	vecAlignedTime0 = vecRefinedT;
	vecAlignedTime0(indReplace) = vecAlignedTime0(indReplace) + vecIntervalError(indReplace) + dblMedianError;
	
	%get type
	if exist('sUserVars','var') && isfield(sUserVars,'strType')
		strType = [sUserVars.strType ' '];
	else
		strType = '';
	end
	fprintf('Mean absolute timing error is %.3fs for %ssync events; %d events corrected\n',dblMeanAbsErr,strType,sum(indReplace));
	
	%recenter
	dblFirstError = vecAlignedTime0(1);
	vecAlignedTime = vecAlignedTime0 + dblStartT;
	
	%% build output
	if nargout > 3
		sSyncStruct = struct;
		sSyncStruct.vecIntervalError = vecIntervalError;
		sSyncStruct.dblFirstError = dblFirstError;
		sSyncStruct.vecAlignedTime0 = vecAlignedTime0;
		sSyncStruct.intStartEvent = intStartEvent;
	end
end

