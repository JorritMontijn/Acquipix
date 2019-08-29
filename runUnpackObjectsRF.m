%% unpacks stim log file into separate temp-style stim files
%set locations
intBlock = 3;
strDate = '20190315';
strMouse = 'B2';
strSearchPath = ['D:\Data\Raw\ePhys\StimLogs\M*' strMouse '*_' strDate filesep];
sSource = dir([strSearchPath strDate '*_B' num2str(intBlock) '_*' strMouse '*.mat']);
strSourceFile = sSource(1).name;
strSourcePath = sSource(1).folder;
strTargetPath = 'D:\Data\Raw\ePhys\StimLogs\TempObjects';

%load data
sLoad = load([strSourcePath filesep strSourceFile]);
sStimObject = sLoad.structEP.sStimObject;
clear sLoad;
delete([strTargetPath filesep '*.mat']);
for intObject=1:numel(sStimObject)
	sObject = sStimObject(intObject);
	save(strcat(strTargetPath,filesep,'Object',num2str(intObject),'.mat'),'sObject');
	%pause(1);
end