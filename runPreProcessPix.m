%% recordings
clear all;close all;
%sites
strDataRoot = '\\vs02.herseninstituut.knaw.nl\csf\Montijn\DataNeuropixels';
%strDataRoot = 'P:\Montijn\DataNeuropixels'; %does not work, 2019b problem?
cellRecSub{1}{1} = '\Exp2019-11-20\20191120_MP2_RunDriftingGratingsR01_g0';
cellRecSub{1}{2} = '\Exp2019-11-21\20191121_MP2_RunDriftingGratingsR01_g0';
cellRecSub{1}{3} = '\Exp2019-11-22\20191122_MP2_RunDriftingGratingsR01_g0';
cellRecSub{1}{4} = '\Exp2019-11-22\20191122_MP2_R02_RunDriftingGratingsR01_g0';
cellRecSub{2}{1} = '\Exp2019-12-10\20191210_MP3_RunDriftingGratingsR01_g0';
cellRecSub{2}{2} = '\Exp2019-12-11\20191211_MP3_RunDriftingGratingsR01_g0';
cellRecSub{2}{3} = '\Exp2019-12-12\20191212_MP3_RunNaturalMovieR01_g0';
cellRecSub{2}{4} = '\Exp2019-12-13\20191213_MP3_RunDriftingGratingsR01_g0';
cellRecSub{2}{5} = '\Exp2019-12-16\20191216_MP3_RunNaturalMovieR01_g0';
cellRecSub{2}{6} = '\Exp2019-12-17\20191217_MP3_RunDriftingGratingsR01_g0';
cellRecSub{3}{1} = '\Exp2020-01-15\20200115_MP4_RunDriftingGratingsR01_g0';
cellRecSub{3}{2} = '\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR01_g0';
cellRecSub{3}{3} = '\Exp2020-01-16\20200116_MP4_RunDriftingGratingsR02_g0';
cellRecSub{4}{1} = '\Exp2020-12-04\20201204_MA4_RunDriftingGratingsR01_g0';
cellRecSub{5}{1} = '\Exp2020-12-09\20201209_MA3_RunReceptiveFieldMappingR01_g0';
cellRecSub{5}{2} = '\Exp2020-12-10\20201210_MA3_RunDriftingGratingsR01_g0';
cellRecSub{5}{3} = '\Exp2020-12-11\20201211_MA3_RunDriftingGratingsR01_g0';
cellRecSub{5}{4} = '\Exp2020-12-14\20201214_MA3_RunDriftingGratingsR01_g0';

cellRec = cellfun(@strcat,cellfill(strDataRoot,size(cellRecSub)),cellRecSub,'uniformoutput',false);

matRunPre = [4 1;...
	5 1;...
	5 2;...
	5 3;...
	5 4];

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
runPreProModuleNpx;