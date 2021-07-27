function PH_PlotProbeEphys(hAxZeta,hAxMua,hAxClust,sFile)
	%% get data
	sEphysData = PH_LoadEphys(sFile);
	max_depths = 3840; % (hardcode, sometimes kilosort2 drops channels)
	try
		sLoad = load(fullpath(sFile.sSynthesis.folder,sFile.sSynthesis.name));
		sSynthData = sLoad.sSynthData;
		vecDepth = cell2vec({sSynthData.sCluster.Depth});
		vecZetaP = cellfun(@min,{sSynthData.sCluster.ZetaP});
		vecZeta = norminv(1-(vecZetaP/2));
		strZetaTit = 'ZETA (z-score)';
	catch
		vecDepth = max_depths-sEphysData.templateDepths;
		vecZeta = sEphysData.ContamP;
		strZetaTit = 'Contamination';
	end
	
	%% plot zeta
	scatter(hAxZeta,vecZeta,vecDepth,15,'b','filled');
	title(hAxZeta,strZetaTit);
	set(hAxZeta,'FontSize',12);
	ylabel(hAxZeta,'Depth (\mum)');
	set(hAxZeta,'XAxisLocation','top','YLim',[0,max_depths],'YColor','k','YDir','reverse');
	
	%% calc mua & spike rates
	% Get normalized log spike n
	[vecTemplateIdx,dummy,spike_templates_reidx] = unique(sEphysData.spikeTemplates);
	norm_template_spike_n = mat2gray(log10(accumarray(spike_templates_reidx,1)+1));
	
	% Get multiunit correlation
	n_corr_groups = 40;
	depth_group_edges = linspace(0,max_depths,n_corr_groups+1);
	depth_group = discretize(max_depths-sEphysData.templateDepths,depth_group_edges);
	depth_group_centers = depth_group_edges(1:end-1)+(diff(depth_group_edges)/2);
	unique_depths = 1:length(depth_group_edges)-1;
	
	spike_binning = 0.01; % seconds
	corr_edges = nanmin(sEphysData.st):spike_binning:nanmax(sEphysData.st);
	corr_centers = corr_edges(1:end-1) + diff(corr_edges);
	
	binned_spikes_depth = zeros(length(unique_depths),length(corr_edges)-1);
	for curr_depth = 1:length(unique_depths)
		binned_spikes_depth(curr_depth,:) = histcounts(sEphysData.st( ...
			ismember(sEphysData.spikeTemplates,find(depth_group == unique_depths(curr_depth)))), ...
			corr_edges);
	end
	
	mua_corr = corrcoef(binned_spikes_depth');
	mua_corr(diag(diag(true(size(mua_corr)))))=0;
	mua_corr(mua_corr<0)=0;
	
	%% Plot spike depth vs rate
	scatter(hAxClust,norm_template_spike_n,max_depths-sEphysData.templateDepths(vecTemplateIdx+1),15,'k','filled');
	set(hAxClust,'YDir','reverse');
	ylim(hAxClust,[0,max_depths]);
	xlabel(hAxClust,'N spikes')
	title(hAxClust,'Template depth & rate')
	set(hAxClust,'FontSize',12)
	ylabel(hAxClust,'Depth (\mum)');
	
	%% Plot multiunit correlation
	matMuaScaled = mua_corr./max(mua_corr(:));
	hAxMua.Children(1).XData = depth_group_centers;
	hAxMua.Children(1).YData = depth_group_centers;
	hAxMua.Children(1).CData = cat(3,ones(size(matMuaScaled)),1-matMuaScaled,1-matMuaScaled);
	title(hAxMua,'MUA correlation');
	set(hAxMua,'FontSize',12)
	
