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
	if ~iscell(cellText)
		cellText = {cellText};
	end
	cellNewText = [cellOldText(:); cellText(:)];
	if numel(cellNewText) > 7,cellNewText(1:(end-8)) = [];end
	set(sFig.ptrTextInformation, 'string', cellNewText );
	drawnow;
end
