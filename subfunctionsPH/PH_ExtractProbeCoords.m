function [matProbePoints,matProbeVector,sProbeAdjusted] = PH_ExtractProbeCoords(sProbeCoords)
	%PH_ExtractProbeCoords Transforms coordinate system of input file to ProbeHistology coordinates
	%
	%Coordinates are [ML=x AP=y DV=z], using the atlas's Bregma in native atlas grid entry indices. For
	%example, the rat SD atlas has bregma [ML=246,AP=653,DV=440]; Note:
	% - probe coordinates are transformed to microns and the origin (x=0,y=0,z=0) is bregma
	% - the location of the "probe" is the location of the _tip_ relative to bregma
	% - low ML (-x) is left of bregma, high ML (+x) is right of bregma
	% - low AP is posterior (i.e., -y in AP coordinates is posterior to bregma)
	% - low DV is ventral (i.e., -z w.r.t. lambda is ventral and inside of the brain, while
	% - Note that this is not the native Allen Brain CCF coordinates, as those do not make any sense.
	% - the probe has two angles: ML
	%
	%outputs:
	% - matProbePoints: original histology points of electrode track [or original vector endpoints]
	% - matProbeVector: current probe location
	% - sProbeAdjusted: adjusted probe location (can be empty)
	
	%check formats
	if isfield(sProbeCoords,'probe_ccf')
		%AP_histology output
		matProbeVector = sProbeCoords.probe_ccf(sProbeCoords.intProbeIdx);
	elseif isfield(sProbeCoords,'cellPoints') && ~isempty(sProbeCoords.cellPoints)
		%cell array of points per probe
		matProbeVector = sProbeCoords.cellPoints{sProbeCoords.intProbeIdx};
	elseif isfield(sProbeCoords,'cellPoints')
		matProbeV = [0   0   0;...AP depth ML (wrt atlas at (0,0,0))
			0   384   0];
		matProbeVector = bsxfun(@plus,matProbeV,vecBregma);
	else
		%file not recognized
		error([mfilename ':UnknownFormat'],'Probe location file format is not recognized');
	end
	matProbePoints = matProbeVector;
	%overwrite probe location if adjusted position is present
	if isfield(sProbeCoords,'sProbeAdjusted') && isfield(sProbeCoords.sProbeAdjusted,'probe_vector')
		%this gui's output
		matProbeVector = sProbeCoords.sProbeAdjusted.probe_vector([1 3 2],:)';
		sProbeAdjusted = sProbeCoords.sProbeAdjusted;
	else
		sProbeAdjusted = [];
	end
end