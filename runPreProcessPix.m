%% recordings
clear all;close all;
%sites
cellRec{1}{1} = 'P:\Montijn\DataNeuropixels\Exp2019-11-20\20191120_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{2} = 'P:\Montijn\DataNeuropixels\Exp2019-11-21\20191121_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{3} = 'P:\Montijn\DataNeuropixels\Exp2019-11-22\20191122_MP2_RunDriftingGratingsR01_g0';
cellRec{1}{4} = 'P:\Montijn\DataNeuropixels\Exp2019-11-22\20191122_MP2_R02_RunDriftingGratingsR01_g0';
cellRec{2}{1} = 'P:\Montijn\DataNeuropixels\Exp2019-12-10\20191210_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{2} = 'P:\Montijn\DataNeuropixels\Exp2019-12-11\20191211_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{3} = 'P:\Montijn\DataNeuropixels\Exp2019-12-12\20191212_MP3_RunNaturalMovieR01_g0';
cellRec{2}{4} = 'P:\Montijn\DataNeuropixels\Exp2019-12-13\20191213_MP3_RunDriftingGratingsR01_g0';
cellRec{2}{5} = 'P:\Montijn\DataNeuropixels\Exp2019-12-16\20191216_MP3_RunNaturalMovieR01_g0';
cellRec{2}{6} = 'P:\Montijn\DataNeuropixels\Exp2019-12-17\20191217_MP3_RunDriftingGratingsR01_g0';
cellRec{3}{1} = 'P:\Montijn\DataNeuropixels\Exp2020-01-15\20200115_MP4_RunDriftingGratingsR01_g0';
cellRec{3}{2} = 'P:\Montijn\DataNeuropixels\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR01_g0';
cellRec{3}{3} = 'P:\Montijn\DataNeuropixels\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR02_g0';
cellRec{4}{1} = 'P:\Montijn\DataNeuropixels\Nora\Exp2020-09-17\20200917_NPX2_RunOptoNoraR02_g0';

matRunPre = [...
	1 3;...
	2 2;...
	2 5;...
	3 1;...
	3 2;...
	3 3;...
	1 4;...
	2 1;...
	2 3;...
	2 4;...
	2 6;...
	];
matRunPre = [4 1];

%											0=none, 1=KS, 2=eye,3=post,4=area+depth
%Rec	Mouse	Date		Quality	V+good	Processed	CORT		SUBCORT	Comments
%01:1-1	MP2		2019-11-20	Good	115/298	4			PM			LP		SUBCORT, some CORT, nice responses
%02:1-2	MP2		2019-11-21	Good	 72/285	4			V1			LP		SUBCORT, some CORT, nice responses	
%03:1-3	MP2		2019-11-22a	Fair	 54/571	4			PM			NOT		a few very nice responses, B2 only good up to T=2500
%04:1-4	MP2		2019-11-22b					2								<<RE-ANALYZE! CHECK ORIGINAL FILES>>					
%05:2-1	MP3		2019-12-10	Good	 53/283	4			PM			NOT		Some nice responses				
%06:2-2	MP3		2019-12-11	Great	182/417	4			PM			SC		Many nice cells					
%07:2-3	MP3		2019-12-12	Good	120/388	4			AM			APN		Many nice cells, mostly subcortical; Subcort vis?					
%08:2-4	MP3		2019-12-13	Great	196/512	4			PM			NOT/APN	Great recording, Eye-tracking possibly weird.. Subcort vis?					
%09:2-5	MP3		2019-12-16	Great!	232/621	4			V1			LGN		Eye-tr is ~ & missing stim1
%10:2-6	MP3		2019-12-17	Good	 72/407	4			AM			-/(LP)	Cort{PPC}, few subcort										
%11:3-1	MP4		2020-01-15	Good	133/398 4			RS/AM		NOT/APN	Eye-tr bad after t=2500s, Subcort vis, Possibly NOT: SUBCORT (+some CORT) very nice responses					
%12:3-2	MP4		2020-01-16a	Poor	 47/325	4			AM			LP		CORT{AM} (+some SUBCORT{LP}~2500)					
%13:3-3	MP4		2020-01-16b	Good	 51/216	4			RS			NOT		Subcort vis, Possibly NOT: SUBCORT, but very nice cells					

%% run actual script
runPreProModuleNpx