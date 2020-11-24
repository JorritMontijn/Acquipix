function RM_updateTextInformation(varargin)
	%update cell information window
	global sFig;
	global sRM;
	
	%check if data has been loaded
	if isempty(sFig) || (isempty(sRM) && nargin == 0)
		return;
	else
		try
			cellOldText = get(sFig.ptrTextInformation, 'string');
		catch
			return;
		end
	end
	
	%check if msg is supplied, otherwise ...
	if nargin > 0
		cellText = varargin{1};
	else
		cellText = {'...'};
	end
	cellNewText = [cellOldText cellText];
	if numel(cellNewText) > 6,cellNewText((end-6):end) = [];end
	set(sFig.ptrTextInformation, 'string', cellNewText );
	drawnow;
end
