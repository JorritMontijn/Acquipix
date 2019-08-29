function objP = doWord(intValue,intForceSwitch)
	%doWord Sends a uint16 integer to TDT system, using BitSwitch protocol
	%   objP = doWord(intValue)
	%
	%Inputs:
	% - intValue; integer (uint16; correct input class not required)
	% - [intForceSwitch]; integer to force behavior:
	%	 	- 0: Default, uses parallel thread if possible, otherwise serial
	%	 	- 1: Forces serial processing
	%	 	- 2: Forces parallel processing, ignoring 100 ms safety margin
	%
	%Output:
	% - objP; parallel.FevalFuture object that can be used to check whether
	%			the command has been completed, using fetchOutputs()
	%
	%Note 1:
	%This function is rather slow, as the transfer of a single word can
	%take between ~10 - ~100 ms. Its intended function is therefore as a
	%workaround for trigger boxes that do not support the "Word" function.
	%If a "Word" function is present, the native functionality should be
	%used instead.
	%
	%Note 2:
	%To mitigate the time a single word takes to be sent, this function
	%uses the parallel processing toolbox to send the word in an
	%asynchronous thread. However, this makes it possible to send
	%overlapping words, which would interfere with the transmission. A
	%standard 100 ms safety margin is therefore hardcoded to ignore any
	%requests that occur within this window. You can force a transmission
	%by setting intForceSwitch to 2. If you have used fetchOutputs() to
	%ensure the previous transmission has finished, it is safe to do this.
	%If you want to force the function to perform a serial transmission and
	%wait for its completion, you can set intForceSwitch to 1. 
	%
	%Summary of BitSwitch protocol:
	%This function communicates a value of 0-65535 to the TDT system,
	%assuming the correct circuit configuration is present. The BitSwitch
	%protocol uses a minimum of 3 ports; 1 as a gating switch (0=no word
	%being sent, 1=word being sent), 1 as a bit switch signal (pulse-based
	%counter to indicate the position of the bit being transferred), and 1+
	%value bits that transfer the actual binary code of the integer.
	%
	%Version History:
	%2019-04-30 Created doWord function and BitSwitch protocol [by Jorrit Montijn]
	
	%check optional input
	if ~exist('boolForceSerial','var')
		intForceSwitch = 0;
	end
	objP = [];
	
	%create pointer to parallel pool and check if we should use serial/parallel
	ptrPP = gcp('nocreate');
	if intForceSwitch == 2 || (intForceSwitch == 0 && ~isempty(ptrPP) && ptrPP.Connected)
		%check if the pipe is free
		global ptrLastWordTic %#ok<TLEV>
		if intForceSwitch == 2 || isempty(ptrLastWordTic) || toc(ptrLastWordTic) > 0.1
			%if parallel pool is present, use asynchronous thread
			objP = parfeval(ptrPP,@fSendWord,1,intValue);
		else
			warning([mfilename ':BusySending'],sprintf('Last word command too short ago; ignoring request'));
		end
	else
		%otherwise, run serially
		fSendWord(intValue);
	end
end
function intOut = fSendWord(intValue)
	%set port numbers
	intOut = 0;
	intPortDataSwitch = 4;
	intPortBitShifter = 5;
	vecPortDataBits = [6 7];
	intNumDataBits = numel(vecPortDataBits);
	dblWaitSecs = 0.0001;
	
	%transform to binary
	intValue = uint16(intValue);
	intMaxSize = 16;
	vecBinary = bitget(intValue,1:intMaxSize);
	intSwitchCounter = 1;
	boolComplete = false;
	
	%run
	dasbit(intPortDataSwitch,1);
	while ~boolComplete
		%check if complete
		if intSwitchCounter >= intMaxSize
			boolComplete = true;
			break;
		end
		%get remaining bits
		vecBitsLeft = vecBinary(intSwitchCounter:end);
		%check if complete
		if all(vecBitsLeft == false)
			boolComplete = true;
			break;
		end
		%send next bits, high
		for intDataBit=1:intNumDataBits
			intPort = vecPortDataBits(intDataBit);
			if vecBitsLeft(intDataBit) == true
				dasbit(intPort,1);
			end
		end
		%pause
		WaitSecs(dblWaitSecs);
		
		%send next bits, low
		for intDataBit=1:intNumDataBits
			intPort = vecPortDataBits(intDataBit);
			if vecBitsLeft(intDataBit) == true
				dasbit(intPort,0);
			end
		end
		
		%send bit shifter, high
		dasbit(intPortBitShifter,1);
		intSwitchCounter = intSwitchCounter + intNumDataBits;
		%pause
		WaitSecs(dblWaitSecs);
		%send bit shifter, low
		dasbit(intPortBitShifter,0);
	end
	%send end message
	dasbit(intPortDataSwitch,0);
	%set output switch
	intOut = 1;
end