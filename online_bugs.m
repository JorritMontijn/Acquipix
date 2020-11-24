%{
RF when switching slection to best:
Reference to non-existent field 'vecSelectChans'.

Error in RM_redraw (line 50)
	vecSelectChans = sRM.vecSelectChans;

Error in runOnlineRF>ptrListSelectChannel_Callback (line 305)
	RM_redraw(1);

when setting channel range to 1-30
MATLAB:subsassigndimmismatch: Unable to perform assignment because the size of the left side is 266-by-1 and the size of the right side is 377-by-1.
RM_main: RM_main [Line 392]
timercb: timercb [Line 34]
timercb: timercb [Line 24]


OnlineOT: first repetition is deleted
- to do: change to also use other grating parameters
