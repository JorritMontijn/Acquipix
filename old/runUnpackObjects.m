%% unpacks stim log file into separate temp-style stim files
%set locations
intBlock = 4;
strSourcePath = 'D:\Data\Raw\ePhys\StimLogs\MB2_20190315\';
sSource = dir([strSourcePath '20190315*_B' num2str(intBlock) '_MouseB2*.mat']);
strSourceFile = sSource(1).name;
strTargetPath = 'D:\Data\Raw\ePhys\StimLogs\TempObjects';

%load data
sLoad = load([strSourcePath strSourceFile]);
sStimObject = sLoad.structEP.sStimObject;
vecTrialStimTypes = sLoad.structEP.vecTrialStimTypes;
clear sLoad;
delete([strTargetPath filesep '*.mat']);
for intTrial=1:numel(vecTrialStimTypes)
	sObject = sStimObject(vecTrialStimTypes(intTrial));
	save(strcat(strTargetPath,filesep,'Object',num2str(intTrial),'.mat'),'sObject');
	%pause(1);
end