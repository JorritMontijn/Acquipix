%% Acquipix toolbox for visual stimulation, recording, and pre-processing with neuropixels
%By Jorrit Montijn
%
%This toolbox contains two components: acquisition scripts for running
%experiments as well as pre-processing scripts to transform your
%experimental data into useable clustered data:
%
%% i) Data acquisition during experiments
%You can use the EyeTracking toolbox to record the mouse's eyetracking, and
%experiment scripts such as RunDriftingGratings.m
%
%% ii) Data pre-processing
%After data acquisition, do the following steps:
%1) run runPreProcessPix.m (or your personalized version) to cluster the
%   data with Kilosort
%2) run runEyeTrackerOffline.m (or your personalized version) to
%   pre-process the eyetracking data
%2a) optional: run runProcessPixClustering.m to look at your clusters in phy
%3) run runPostProcessPix.m to combine stimulus timings & parameters,
%   eye-tracking and electrophysiology into one file
%4) run runPostProcessProbeAreas.m to add the brain area to each cluster