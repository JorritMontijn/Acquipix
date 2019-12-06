function ops = DP_GetParamStruct(sMeta)

	if ~exist('sMeta','var')
		sMeta = struct;
	end
	
% sample rate
ops.fs = getOr(sMeta,'imSampRate',30000);  
if ischar(ops.fs);ops.fs = str2double(ops.fs);end

%channel number
ops.NchanTOT= getOr(sMeta,'nSavedChans',384);  
if ischar(ops.NchanTOT);ops.NchanTOT = str2double(ops.NchanTOT);end

% frequency for high pass filtering (150)
ops.fshigh = 150;   

% minimum firing rate on a "good" channel (0 to skip)
ops.minfr_goodchannels = 0.5; 

%which range to process
ops.trange = [0 Inf]; % time range to sort

% threshold on projections (like in Kilosort1, can be different for last pass like [10 4])
%ops.Th = [10 4];  

% how important is the amplitude penalty (like in Kilosort1, 0 means not used, 10 is average, 50 is a lot) 
%ops.lam = 10;  

% number of samples to average over (annealed from first to second value) 
%ops.momentum = [20 400]; 

% spatial constant in um for computing residual variance of spike
%ops.sigmaMask = 30; 

% threshold crossings for pre-clustering (in PCA projection space)
%ops.ThPre = 8; 
%% danger, changing these settings can lead to fatal errors
% options for determining PCs
ops.spkTh           = -6;      % spike threshold in standard deviations (-6)
%ops.reorder         = 1;       % whether to reorder batches for drift correction. 
%ops.nskip           = 25;  % how many batches to skip for determining spike PCs

%ops.GPU                 = 1; % has to be 1, no CPU version yet, sorry
% ops.Nfilt               = 1024; % max number of clusters
%ops.nfilt_factor        = 4; % max number of clusters per good channel (even temporary ones)
ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection
ops.NT                  = 64*1024+ ops.ntbuff; % must be multiple of 32 + ntbuff. This is the batch size (try decreasing if out of memory). 
%ops.whiteningRange      = 32; % number of channels to use for whitening each channel
%ops.nSkipCov            = 25; % compute whitening matrix from every N-th batch
%ops.scaleproc           = 200;   % int16 scaling of whitened data
%ops.nPCs                = 3; % how many PCs to project the spikes into
%ops.useRAM              = 0; % not yet available
