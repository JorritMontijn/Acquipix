%% define structure
%{
sNeuron = struct;
sNeuron(1).Area = {'NOT','V1','SC'};
sNeuron(1).MouseType = {'WT','Albino'};
sNeuron(1).Mouse = 'MB4';
sNeuron(1).Date = '20190315';
sNeuron(1).DepthCh = 6;
sNeuron(1).DepthMicron = 2000;
sNeuron(1).IdxSU = 1;
sNeuron(1).IdxClust = 201;
sNeuron(1).Recording = struct;
Recording(1).StimType = {'DG'};
Recording(1).SpikeTimes = {};
Recording(1).vecStimOnTime = [];
Recording(1).vecStimOffTime = [];
Recording(1).cellStimObject = {};
Recording(1).vecStimOriDegrees = [];
Recording(1).vecEyeTimestamps = [];
Recording(1).matEyeData = [];
%}

%% get data file
%load data
strDataPath = 'D:\Data\Processed\Neuropixels\';
strExp = 'Exp2019-11-20_MP2_AP.mat';
strFileAP = [strDataPath strExp];
sLoad = load(strFileAP);
sAP = sLoad.sAP;clear sLoad;

%% check overall stationarity
fprintf('Calculating cluster qualities [%s]\n',getTime);
hTic = tic;
sDG = struct;
% get cluster quality
boolMakePlotsCQ = false;
intNeurons = numel(sAP.SU_st);
vecNonStatIdx = nan(1,intNeurons);
vecViolIdx = nan(1,intNeurons);
for intNeuron = 1:intNeurons
	if toc(hTic) > 5
		fprintf('   Neuron %d/%d [%s]\n',intNeuron,intNeurons,getTime);
		hTic = tic;
	end
	vecSpikeTimes = sAP.SU_st{intNeuron};
	sClustQual = getClusterQuality(vecSpikeTimes,boolMakePlotsCQ);
	vecNonStatIdx(intNeuron) = sClustQual.dblNonstationarityIndex;
	vecViolIdx(intNeuron) = sClustQual.dblViolIdx1ms;
end
sDG.vecNonStatIdx = vecNonStatIdx;
sDG.vecViolIdx = vecViolIdx;

%% get stim block
sB = struct;
intStimBlocks = numel(sAP.cellStim);
for intStimBlock=1:intStimBlocks
	%get timings & stim data
	[vecSpikeTimes,vecStimOnTime,vecStimOffTime,vecStimType,sStimObject] = getDataAP(sAP,1,'stimblock',intStimBlock);
	vecTrialStartTime = vecStimOnTime - 0.4;
	vecOrientationsDeg = cell2vec({sStimObject(vecStimType).Orientation});
	vecOrientationsRad = deg2rad(vecOrientationsDeg);
	vecOriTypesDeg = unique(vecOrientationsDeg);
	vecOriTypesRad = deg2rad(vecOriTypesDeg);
	intOris = numel(vecOriTypesDeg);
	intTrials = numel(vecOrientationsDeg);
	intReps = intTrials/intOris;
	
	%build response matrix
	matStimCounts = getSpikeCounts(sAP.SU_st, vecStimOnTime,vecStimOffTime);
	matStimResp = bsxfun(@rdivide,matStimCounts,(vecStimOffTime-vecStimOnTime)); %transform to Hz
	matBaseCounts = getSpikeCounts(sAP.SU_st,vecTrialStartTime,vecStimOnTime);
	matBaseResp = bsxfun(@rdivide,matBaseCounts,(vecStimOnTime-vecTrialStartTime)); %transform to Hz
	matResp = matStimResp - matBaseResp;
	
	%pre-allocate
	cellArea = cell(1,intNeurons);
	matFitParams = nan(5,intNeurons);
	vecPrefDir = nan(1,intNeurons);
	matFitResp = nan(intOris,intNeurons);
	matBandwidth = nan(2,intNeurons);
	matVariance = nan(2,intNeurons);
	
	vecOriTtest = nan(1,intNeurons);
	cellRawOri = cell(1,intNeurons);
	cellRawMean = cell(1,intNeurons);
	cellRawSD = cell(1,intNeurons);
	
	vecZeta = nan(1,intNeurons);
	vecHzP = nan(1,intNeurons);
	cellSpikeT = cell(1,intNeurons);
	cellZeta = cell(1,intNeurons);
		
	vecRho = nan(1,intNeurons);
	vecDeltaPrime = nan(1,intNeurons);
	vecOPI = nan(1,intNeurons);
	
	vecNonStatIdx = nan(1,intNeurons);
	vecViolIdx = nan(1,intNeurons);
	
	%% get neuron
	%retrieve spiking data
	for intNeuron = 1:intNeurons
		fprintf('Processing block %d, neuron %d/%d [%s]\n',intStimBlock,intNeuron,intNeurons,getTime);
		
		%get single neuron data
		vecSpikeTimes = sAP.SU_st{intNeuron};
		strArea = '';
		
		% plot
		close all
		hFig = figure;
		vecPtrs = nan(1,25);
		vecZetaPerOri = nan(1,intOris);
		vecZetaP = nan(1,intOris);
		for intOriIdx = 1:intOris
			%get zeta
			if intOriIdx == 1
				intPlot = 0;%2;
			else
				intPlot = 0;
			end
			dblOri = vecOriTypesDeg(intOriIdx);
			[vecZetaPerOri(intOriIdx),sOptionalOutputs] = getZeta(vecSpikeTimes,[vecStimOnTime(vecOrientationsDeg==dblOri)' vecStimOffTime(vecOrientationsDeg==dblOri)'],intPlot,1.5);
			%{
			%plot
			figure(hFig);
			vecPtrs(intOriIdx) = subplot(5,5,intOriIdx);
			vecWindow = -0.1:0.05:1.4;
			dblOri = vecOriTypesDeg(intOriIdx);
			[vecMean,vecSEM,vecWindowBinCenters] = doPEP(vecSpikeTimes,vecWindow,vecStimOnTime(vecOrientationsDeg==dblOri),vecPtrs(intOriIdx));
			if mod(intOriIdx,5) == 1
				ylabel('Rate (Hz)');
			end
			if intOriIdx > 20
				xlabel('Time from onset (s)');
			end
			title(sprintf('O=%d;Zp=%.3f,Dp=%.3f',dblOri,sOptionalOutputs.dblP,sOptionalOutputs.dblHzP));
			fixfig;
			
			%}
		end
		
		%build response vector
		[vecTrialPerSpike,vecTimePerSpike] = getSpikesInTrial(vecSpikeTimes,vecStimOnTime);
		indRem = vecTrialPerSpike == 0 | vecTimePerSpike > 1;
		vecUseTrials = vecTrialPerSpike(~indRem);
		vecSpikesPerTrial = accumarray(vecUseTrials,ones(size(vecUseTrials)));
		vecSpikesPerTrial((end+1):intTrials) = 0;
		%vecSpikesPerTrial(vecOrientationsDeg==dblOri)
		vecMeanRespPerOri = accumarray(vecStimType(:),vecSpikesPerTrial)./intReps;
		
		%final plot
		[dblZeta,sOptionalOutputs] = getZeta(vecSpikeTimes,[vecStimOnTime' vecStimOffTime'],0,1.5);
		
		%{
		figure(hFig);
		subplot(5,5,25);
		polar([vecOriTypesRad(1);vecOriTypesRad],[vecMeanRespPerOri(1); vecMeanRespPerOri]);
		title(sprintf('Zp=%.3f,Dp=%.3f',sOptionalOutputs.dblP,sOptionalOutputs.dblHzP));
		fixfig;
		%}
		%% get tuning curves & parameters
		dblRho = getTuningRho(vecSpikesPerTrial',vecOrientationsRad');
		dblDeltaPrime = getDeltaPrime(vecSpikesPerTrial',vecOrientationsRad');
		dblOPI = getOPI(vecSpikesPerTrial',vecOrientationsRad');
		sTuning = getTuningCurves(vecSpikesPerTrial',vecOrientationsDeg');
		%[matRespNSR,vecStimTypes,vecUniqueDegs] = getStimulusResponses(vecSpikesPerTrial',vecOrientationsRad');
		
	
		%% save data
		cellArea{intNeuron} = strArea;
		vecParams = sTuning.matFittedParams;
		matFitParams(:,intNeuron) = vecParams;
		vecPrefDir(intNeuron) = vecParams(1);
		matFitResp(:,intNeuron) = feval(sTuning.funcFit,vecParams,vecOriTypesRad);
		%vecParams(1) = pi/2;
		%zeta
		vecZeta(intNeuron) = dblZeta;
		vecHzP(intNeuron) = sOptionalOutputs.dblHzP;
		cellSpikeT{intNeuron} = sOptionalOutputs.vecSpikeT;
		cellZeta{intNeuron} = sOptionalOutputs.vecZ;
		
		%rho
		vecRho(intNeuron) = dblRho;
		%d'
		vecDeltaPrime(intNeuron) = dblDeltaPrime;
		vecOPI(intNeuron) = dblOPI;
		%raw ori, mean per ori, and sd per ori
		vecOriTtest(intNeuron) = sTuning.vecOriTtest;
		cellRawOri{intNeuron} = sTuning.vecUniqueRads;
		cellRawMean{intNeuron} = sTuning.matMeanResp;
		cellRawSD{intNeuron} = sTuning.matSDResp;
		%peak CV + BW
		matVariance(:,intNeuron) = sTuning.matVariance;
		matBandwidth(:,intNeuron) = real(sTuning.matBandwidth);
		
		% get cluster quality
		%build figure name
		%strFileName = sprintf('%s%sB%sSU%dC%d',strArea,strDate,strBlock,intSU,intClust);
		boolMakePlotsCQ = false;
		indSpikeTimesThisBlock = vecSpikeTimes > vecStimOnTime(1) & vecSpikeTimes < vecStimOffTime(end);
		sClustQual = getClusterQuality(vecSpikeTimes(indSpikeTimesThisBlock),boolMakePlotsCQ);
		vecNonStatIdx(intNeuron) = sClustQual.dblNonstationarityIndex;
		vecViolIdx(intNeuron) = sClustQual.dblViolIdx1ms;
		
	end
	%% assign to block structure
	sB(intStimBlock).matStimResp = matStimResp;
	sB(intStimBlock).matBaseResp = matBaseResp;
	sB(intStimBlock).matResp = matResp;
	
	sB(intStimBlock).cellArea = cellArea;
	sB(intStimBlock).matFitParams = matFitParams;
	sB(intStimBlock).vecPrefDir = vecPrefDir;
	sB(intStimBlock).matFitResp = matFitResp;
	sB(intStimBlock).matVariance = matVariance;
	sB(intStimBlock).matBandwidth = matBandwidth;
	
	sB(intStimBlock).vecOriTtest = vecOriTtest;
	sB(intStimBlock).cellRawOri = cellRawOri;
	sB(intStimBlock).cellRawMean = cellRawMean;
	sB(intStimBlock).cellRawSD = cellRawSD;
	
	sB(intStimBlock).cellZeta = cellZeta;
	sB(intStimBlock).cellSpikeT = cellSpikeT;
	
	sB(intStimBlock).vecZeta = vecZeta;
	sB(intStimBlock).vecHzP = vecHzP;
	sB(intStimBlock).vecRho = vecRho;
	sB(intStimBlock).vecDeltaPrime = vecDeltaPrime;
	sB(intStimBlock).vecOPI = vecOPI;
	
	sB(intStimBlock).vecNonStatIdx = vecNonStatIdx;
	sB(intStimBlock).vecViolIdx = vecViolIdx;
end

%% save
sDG.sB = sB;
sDG.strFileAP = strFileAP;
strExpDG =strrep(strExp,'AP','DG');
fprintf('Saving DG data to %s in path %s...\n',strExpDG,strDataPath);
save([strDataPath strExpDG],'sDG');
fprintf('\b   Done! [%s]\n',getTime);
