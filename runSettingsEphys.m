%% User Settings
%arduino = 1; %Arduino connected? Appears not to be used
Set.debug = 0; %Debug mode (i.e. Destkop computer)
Set.ephys = 1;
Set.dasno = 22; %Enables Ephys triggers
Set.cgscreen = 2;
Set.imaging = 0;
Set.optogenetics = 0;
Set.responsedelay = 500;
Set.TimeToLick = 2.5;
Set.cleanbaseline = 0;
Set.cleanbasetime = 2;
Set.OnlineFeedback = 0; %You want online motion feedback?
gammaconversion = 'gammaconEphys';

%% ScreenSettings
Set.Screenx = 1920;
Set.Screeny = 1080;
Set.Refresh = 60;
Set.DistanceToScreen = 15.5;

Set.Orientations = [0 90];
Set.ScreenWidth = 33;
Set.ScreenWidthD2 = Set.ScreenWidth/2;
Set.ScreenHeight = 25;
Set.zdistBottom = Set.DistanceToScreen;


%% Grating settings\
% TAKE CARE that mouse settings will overwrite these standard settings! 
Set.preforient = 0; %default 0?
%Set.prefsize = 50; %default 50? Appears to be unused
Set.prefsf = 0.075;
Set.prefspeed = 24; %deg/s
Set.Centerx = 30;
Set.Centery = 15;  %30

%% General Settings
Set.ITI = 8;  %warning('TESTMODE, ITI SET TO ZERO, fig contrast changed')
Set.ItiRandMin = 0;
Set.ItiRandMax = 2;
Set.StimDur = 1.5;

Set.screenAngle = 90;
Set.SpatFreq = 0.08;%0.05;
Set.HW = Set.Screenx./2; %get half width of the screen
Set.HH = Set.Screeny./2;
Set.PixPerDeg = Set.HW/atand(Set.ScreenWidthD2/Set.DistanceToScreen);
Set.DegPerPix = 1/Set.PixPerDeg;
Set.RadPerPix = Set.DegPerPix*pi/180;
Set.FigSize = 35;
Set.mouseposx = Set.ScreenWidth/2;
Set.mouseposy  = Set.ScreenHeight/2;
Set.zdistBottom = 13;

Set.ScreenAngle = 90;
Ang2Pix = Set.PixPerDeg;

%Set grey to be halfway between darkest and brightest luminace to acheive maxuimum possible contrast range
%gammacon converts between rgb and luminace given the known gamma curve of the montior
Set.maxbright = 0.6;
Set.minbright = 0;

%% Motor settings for different setups
Set.setup = 8;
Set.ephys = 1;
Set.LickPos = 60;    %motor
Set.BreakPos = 80;   %motor


%% for adaptation to performance
Set.PerformanceThreshold = 0.75;

%% Basic Settings
Set.drum = 0;
Set.ezmode = 0;
Set.semidrum = 0;

%msg
fprintf('Loaded default settings for ePhys and assigned them to Set\n');