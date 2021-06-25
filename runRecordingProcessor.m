%runRecordingProcessor GUI to perform Acquipix recording pre-processing
%
%This GUI interfaces with the outputs of "RunExperiment" (this repo),
%"runEyeTrackerOffline" (EyeTracking repo) and SpikeGLX and provides an 
%easy to use interface for managing your library of Acquipix recordings.
%
%	Created by Jorrit Montijn, 2021-06-17 (YYYY-MM-DD)

%Version history:
%0.0 - 17 June 2021
%	Created by Jorrit Montijn

%% add subfolder to path
cellPaths = strsplit(path(),';');
strPathFile=mfilename('fullpath');
cellCodePath = strsplit(strPathFile,filesep);
strCodePath = fullfile(strjoin(cellCodePath(1:(end-1)),filesep),'subfunctionsRP');
if isempty(find(contains(cellPaths,strCodePath),1))
	addpath(strCodePath);
end

%% check if dependencies are present
if ~exist('uilock','file')
	error([mfilename ':MissingDependency'],sprintf('This function requires the "GeneralAnalysis" repository to function. You can get it here: %s','https://github.com/JorritMontijn/GeneralAnalysis'));
end

%% define globals
global sFigRP;
global sRP;

%% load defaults
sRP = RP_populateStructure();
sFigRP = struct;

%% run
%check if instance is already running
if isstruct(sFigRP) && isfield(sFigRP,'IsRunning') && sFigRP.IsRunning == 1
	error([mfilename ':SingularGUI'],'RecordingProcessorModule instance is already running; only one simultaneous GUI is allowed');
end

%clear data & disable new instance
sFigRP.IsRunning = true;

%generate gui
[sFigRP,sRP] = RP_genGUI(sFigRP,sRP);


