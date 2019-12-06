function [vecData,vecStimOn,vecStimOff,vecStimType,sStimObject] = getDataAP(sAP,intNeuron,varargin)
	%getDataAP Retrieves ephys data from sAP structure
	%   Detailed explanation goes here
	
	%% set possible inputs
	cellAssignInputTo = {'stimblock','intStimBlock';...
		'test','intTest'};
	
	%% parse inputs
	%check if pupil
	if ischar(intNeuron) && contains(intNeuron,'Pupil')
		strVar = strrep(varargin{1},'vecPupil','');
		strVar = strrep(strVar,'Pupil','');
		strVar = strcat('vecPupil',strVar);
	elseif ~isnumeric(intNeuron)
		error([mfilename ':ParseError'],sprintf('Parse error; neuron # is not numeric'));
	end
	
	%parse optional inputs
	cellInputs = varargin;
	intInputCounter = 0;
	while intInputCounter < numel(cellInputs)
		intInputCounter = intInputCounter + 1;
		strParam = cellInputs{intInputCounter};
		if ischar(strParam)
			%get variable
			intVar = find(contains(cellAssignInputTo(:,1),strParam));
			if numel(intVar) > 1
				error([mfilename ':ParseError'],sprintf('Parse error; ambiguous parameter %d: %s',intInputCounter,strParam));
			elseif numel(intVar) == 0
				error([mfilename ':ParseError'],sprintf('Parse error; unknown parameter %d: %s',intInputCounter,strParam));
			end
			%get value
			intInputCounter = intInputCounter + 1;
			varVal = cellInputs{intInputCounter}; %#ok<NASGU>
			eval(strcat(cellAssignInputTo{intVar,2},'=varVal;'));
		else
			disp(strParam);
			error([mfilename ':ParseError'],sprintf('Parse error; optional argument %d not recognized',intInputCounter));
		end
	end
	
	%% set defaults if none supplied
	if ~exist('intStimBlock','var') || isempty(intStimBlock),intStimBlock = 1;end %#ok<NODEF>
	
	%% retrieve data
	if ~isnumeric(intNeuron) 
		%pupil data requested
		vecData = sAP.sPupil.(strVar);
		vecStimOn = sAP.cellStim{intStimBlock}.structEP.vecPupilStimOnFrame;
		vecStimOff = sAP.cellStim{intStimBlock}.structEP.vecPupilStimOffFrame;
	else
		%spiking data requested
		vecData = sAP.SU_st{intNeuron};
		vecStimOn = sAP.cellStim{intStimBlock}.structEP.vecStimOnTime;
		vecStimOff = sAP.cellStim{intStimBlock}.structEP.vecStimOffTime;
	end
	
	if nargout > 3
		%get stim type and data
		vecStimType = sAP.cellStim{intStimBlock}.structEP.ActStimType;
		sStimObject = sAP.cellStim{intStimBlock}.structEP.sStimObject;
	end
end

