function [varData,vecStimOn,vecStimOff,vecStimType,sStimObject] = getDataAP(sAP,intCluster,varargin)
	%getDataAP Retrieves ephys data from sAP structure. Syntax (4 options):
	% 1)  vecSpikeTimes = getDataAP(sAP,intCluster)
	%		Retrieves the spike times for the requested cluster (intCluster)
	%
	% 2)  varClusterData = getDataAP(sAP,intCluster,'var')
	%		Retrieves the requested cluster data 'var'; example:
	%		varClusterData = getDataAP(sAP,intCluster,'Depth')
	%
	% 3)  varStimData = getDataAP(sAP,'var')
	%		Retrieves the requested stimulus block data 'var'; example:
	%		vecStimulusOrientation = getDataAP(sAP,'Orientation')
	%
	% 4)  vecPupilData = getDataAP(sAP,'Pupil','var')
	%		Retrieves pupil tracking data 'var'; example:
	%		vecPupilData = getDataAP(sAP,'Pupil','CenterX')
	%
	%	  [...] = getDataAP(...,'stimblock',i)
	%		Selects stimulus block i; examples:
	%		[vecSpikeTimesCell23,vecStimOnBlock2] = getDataAP(sAP,23,'stimblock',2)
	%		[vecStimOriBlock3,vecStimOnBlock3] = getDataAP(sAP,'Orientation','stimblock',3)
	%		[vecPupilData,vecStimOnBlock2] = getDataAP(sAP,'Pupil','CenterX','stimblock',2)
	%
	%Optional outputs:
	%	 [varData,vecStimOn,vecStimOff,vecStimType,sStimObject] = getDataAP(...)
	%		Retrieves stimulus on/off times, types and object structures
	%
	%Version history:
	%1.0 - February 25 2020
	%	Created by Jorrit Montijn
	%1.1 - March 27 2020
	%	Added syntax option [by JM]
	
	%% define possible variables for name/value parameters and target variables
	cellAssignInputTo = {'stimblock','intStimBlock';...
		'test','intTest'};
	
	%% parse inputs
	%check if pupil
	strVar = '';
	if ischar(intCluster) && contains(intCluster,'Pupil')
		strVar = strrep(varargin{1},'vecPupil','');
		strVar = strrep(strVar,'Pupil','');
		strVar = strcat('vecPupil',strVar);
	elseif isnumeric(intCluster)
		if nargin > 2
			strVar = varargin{1};
		end
	else
		strVar = intCluster;
		%error([mfilename ':ParseError'],sprintf('Parse error; neuron # is not numeric'));
	end
	if isempty(strVar) || ismember(strVar,cellAssignInputTo(:,1)),strVar='SpikeTimes';end
	
	%parse optional inputs
	cellInputs = varargin;
	intInputCounter = 0;
	while intInputCounter < numel(cellInputs)
		intInputCounter = intInputCounter + 1;
		strParam = cellInputs{intInputCounter};
		if ischar(strParam)
			%get variable
			intVar = find(contains(cellAssignInputTo(:,1),strParam));
			if numel(intVar) == 1
				%get value
				intInputCounter = intInputCounter + 1;
				varVal = cellInputs{intInputCounter}; %#ok<NASGU>
				eval(strcat(cellAssignInputTo{intVar,2},'=varVal;'));
			elseif ~isempty(strParam) && numel(intVar) > 1
				error([mfilename ':ParseError'],sprintf('Parse error; ambiguous parameter %d: %s',intInputCounter,strParam));
			end
		end
	end
	
	%% set defaults if none supplied
	if ~exist('intStimBlock','var') || isempty(intStimBlock),intStimBlock = 1;end %#ok<NODEF>
	
	%% retrieve data
	if ~isnumeric(intCluster) 
		if contains(intCluster,'Pupil')
			%pupil data requested
			varData = sAP.sPupil.(strVar);
			vecStimOn = sAP.cellStim{intStimBlock}.structEP.vecPupilStimOnFrame;
			vecStimOff = sAP.cellStim{intStimBlock}.structEP.vecPupilStimOffFrame;
		else
			varData = sAP.cellStim{intStimBlock}.structEP.(strVar);
			vecStimOn = sAP.cellStim{intStimBlock}.structEP.vecStimOnTime;
			vecStimOff = sAP.cellStim{intStimBlock}.structEP.vecStimOffTime;
		end
	else
		%cluster data requested
		varData = sAP.sCluster(intCluster).(strVar);
		vecStimOn = sAP.cellStim{intStimBlock}.structEP.vecStimOnTime;
		vecStimOff = sAP.cellStim{intStimBlock}.structEP.vecStimOffTime;
		%vecStimOn = sAP.cellStim{intStimBlock}.structEP.ActOnNI;
		%vecStimOff = sAP.cellStim{intStimBlock}.structEP.ActOffNI;
	end
	
	if nargout > 3
		%get stim type and data
		vecStimType = sAP.cellStim{intStimBlock}.structEP.ActStimType;
		sStimObject = sAP.cellStim{intStimBlock}.structEP.sStimObject;
	end
end

