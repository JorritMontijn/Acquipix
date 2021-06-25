% =========================================================
% Read nSamp timepoints from the binary file, starting
% at timepoint offset samp0. The returned array has
% dimensions [nChan,nSamp]. Note that nSamp returned
% is the lesser of: {nSamp, timepoints available}.
%
function dataArray = DP_ReadBin(samp0, nSamp, meta, binName, path, strClass,vecReadCh)
samp0 = -inf
nSamp=inf
meta=sMeta
binName=[strFile,strExt]
path=strPath
vecReadCh=intSyncCh

	if ~exist('strClass','var') || isempty(strClass)
		strClass = 'int16';
	end
	
	nChan = str2double(meta.nSavedChans);
	if ~exist('vecReadCh','var') || isempty(vecReadCh)
		vecReadCh = 1:nChan;
	end
	
    nFileSamp = str2double(meta.fileSizeBytes) / (2 * nChan);
    samp0 = max(samp0, 0);
    nSamp = min(nSamp, nFileSamp - samp0);

    sizeA = [nChan, nSamp];

	strFile = fullpath(path, binName);
    fid = fopen(strFile, 'rb');
    status = fseek(fid, samp0 * 2 * nChan, 'bof');
	if status == -1 %try again once
		status = fseek(fid, samp0 * 2 * nChan, 'bof');
		if status  == -1
			error([mfilename 'E:ReadError'],sprintf('Cannot read file "%s"',binName));
		end
	end
	
	if numel(vecReadCh) == nChan
		dataArray = fread(fid, sizeA, sprintf('int16=>%s',strClass));
	else
		%read specific channels
		dataArray = [numel(vecReadCh), nSamp];
		hTic=tic;
		intSampsPerRead = 1000;
		vecStartSamp = 1:intSampsPerRead:nSamp;
		for intStartSamp=vecStartSamp
			intReadSamps = min(nSamp-intStartSamp,intSampsPerRead);
			dataArrayTemp = fread(fid, [nChan,intReadSamps], sprintf('int16=>%s',strClass));
			dataArray(:,(intStartSamp:(intStartSamp+intReadSamps-1))) = dataArrayTemp(vecReadCh,:);
			if toc(hTic) > 5
				fprintf('Reading sample %d/%d (%.1f%%) [%s]\n',intStartSamp,nSamp,(intStartSamp/nSamp)*100,getTime());
				hTic=tic;
			end
		end
	end
    fclose(fid);
end % ReadBin