% =========================================================
% Return gain arrays for imec channels.
%
% Index into these with original (acquired) channel IDs.
%
function [APgain,LFgain] = DP_ChanGainsIM(meta)
    % First check if this is 3A or 3B data. For 3A metadata
    % there is a unique field "typeEnabled" which was replaced
    % with "typeImEnabled" and "typeNiEnabled" in 3B.
    % The 3B imro table has an additional field for the
    % high pass filter enabled/disabled
    if isfield(meta,'typeEnabled')
        % 3A data
        C = textscan(meta.imroTbl, '(%*s %*s %*s %d %d', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
    else
        % 3B data
        C = textscan(meta.imroTbl, '(%*s %*s %*s %d %d %*s', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
    end
    APgain = double(cell2mat(C(1)));
    LFgain = double(cell2mat(C(2)));
end % ChanGainsIM