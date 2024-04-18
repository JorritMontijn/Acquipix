function sLaser = PP_GetLaserPulse(vecData,sMetaNI)
%process NI laser pulse channel
%
%NB, we only get the on and off samples here, stim times have to be
%computed during analysis with re-calibrated samp rates

%get laser on and off
[boolVecPulses,~] = DP_GetUpDown(vecData);
vecChangeLaser = diff(boolVecPulses);
vecLaserOnSamps = (find(vecChangeLaser == -1)+1); %because the signal is 'inverted'
vecLaserOffSamps = (find(vecChangeLaser == 1)+1);

%out
sLaser = struct;
sLaser.OnSamps = vecLaserOnSamps;
sLaser.OffSamps = vecLaserOffSamps;
