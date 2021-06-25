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

%% get data
%load data
strDataPath = 'D:\Data\Processed\Neuropixels\';
strExp = 'Exp2019-11-20_MP2';
%AP
strExp_AP = [strExp '_AP.mat'];
strFileAP = [strDataPath strExp_AP];
sLoad = load(strFileAP);
sAP = sLoad.sAP;clear sLoad;
%DG
strExp_DG = [strExp '_DG.mat'];
strFileDG = [strDataPath strExp_DG];
sLoad = load(strFileDG);
sDG = sLoad.sDG;clear sLoad;
%set output
strOutPath = ['D:\Data\Results\2019_Neuropixels_NOT\NeuronGraphs\' strExp filesep];
if ~exist('strOutPath','dir')
	mkdir(strOutPath);
end

%% go through neurons & blocks
%make figure
close all;
hFig=figure;
maxfig(hFig);

%run
intBlocks = numel(sAP.cellStim);
intNeurons = numel(sAP.SU_st);
for intBlock=1:intBlocks
for intNeuron=1:intNeurons
	%raster plot
	clf;
	subplot(2,2,1);
	plotRaster(sAP.SU_st{intNeuron},sAP.cellStim{intBlock}.structEP.vecStimOnTime,1.5);
	title(sprintf('%s, B%d, N %d; ~Stat: %.3f, viol: %.1f%%',strExp,intBlock,intNeuron,sDG.sB(intBlock).vecNonStatIdx(intNeuron),sDG.sB(intBlock).vecViolIdx(intNeuron)*100),'Interpreter','none');
	
	%ori tuning
	dblPrefDir = rad2deg(sDG.sB(intBlock).vecPrefDir(:,intNeuron));
	vecFitR = sDG.sB(intBlock).matFitResp(:,intNeuron);
	vecOri = rad2deg(sDG.sB(intBlock).cellRawOri{intNeuron});
	[dummy,intPrefStim] = min(abs(vecOri-dblPrefDir));
	intPrefOri = round(vecOri(intPrefStim));
	vecMeanR = sDG.sB(intBlock).cellRawMean{intNeuron};
	vecSDR = sDG.sB(intBlock).cellRawSD{intNeuron};
	
	%plot
	subplot(2,2,2);
	errorbar(vecOri,vecMeanR,vecSDR./sqrt(numel(sAP.cellStim{intBlock}.structEP.vecStimOnTime)/numel(vecMeanR)));
	hold on;
	plot(vecOri,vecFitR,'k--');
	hold off
	xlabel('Orientation (deg)');
	ylabel('Spiking rate (Hz)');
	title(sprintf('Ori t-test,p: %.3f, %s'': %.3f, OPI: %.3f, %s: %.3f',sDG.sB(intBlock).vecOriTtest(intNeuron),getGreek('delta'),sDG.sB(intBlock).vecDeltaPrime(intNeuron),...
		sDG.sB(intBlock).vecOPI(intNeuron),getGreek('rho'),sDG.sB(intBlock).vecRho(intNeuron)));
	fixfig;
	
	
	%psth
	hAx=subplot(2,2,3);
	vecX = -0.1:0.1:1.5;
	doPEP(sAP.SU_st{intNeuron},vecX,sAP.cellStim{intBlock}.structEP.vecStimOnTime(sAP.cellStim{intBlock}.structEP.Orientation==intPrefOri),hAx);
	xlim([min(vecX) max(vecX)]);
	xlabel('Time from stim onset (s)');
	ylabel('Spiking rate (Hz)');
	title(sprintf('Pref stim %d, Mean +/- SEM over trials',intPrefOri));
	fixfig;
	
	%zeta
	subplot(2,2,4)
	plot(sDG.sB(intBlock).cellSpikeT{intNeuron},sDG.sB(intBlock).cellZeta{intNeuron});
	xlabel('Time from stim onset (s)');
	ylabel('Z-score');
	title(sprintf('Zeta=%.3f, p(Hz)=%.3f',sDG.sB(intBlock).vecZeta(intNeuron),sDG.sB(intBlock).vecHzP(intNeuron)));
	fixfig

	%save
	strFile = sprintf('%s_B%02d_N%04d_DG',strExp,intBlock,intNeuron);
	drawnow;
	export_fig([strOutPath strFile '.tif']);
	export_fig([strOutPath strFile '.pdf']);
	
end
end

%% plot pref ori
matInclude = [...
	abs(sDG.sB(intBlock).vecNonStatIdx) < 0.15;
	sDG.sB(intBlock).vecViolIdx < 0.2;
	(sDG.sB(intBlock).vecHzP < 0.05 | abs(sDG.sB(intBlock).vecZeta) > 2 | sDG.sB(intBlock).vecOriTtest < 0.05)];
indInclude = all(matInclude,1);

vecPrefDeg = rad2deg(sDG.sB(intBlock).vecPrefDir);
scatter(vecPrefDeg(indInclude),-sAP.SU_depth(indInclude));
