%% MATPOWER Case Format : Version 2
function mpc = epri21
mpc.version = '2';


%%-----  Power Flow Data  -----%%

%% system MVA base
mpc.baseMVA = 100;


%% bus data
%    bus_i    type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	  3	0	    0	    0	  0	       1	1.100000	-0.000000	22	1	1.3	0.7
	2	  1	0	    0	    0	  0	       1	1.100000	-0.000000	345	1	1.3	0.7
	3	  1	0	    0	    0	  0	       1	1.100000	-0.000000	345	1	1.3	0.7
	4	  1	1500	600	  0	  546.62	 1	1.100000	-0.000000	500	1	1.3	0.7
	5	  1	1200	350	  0	  0	       1	1.100000	-0.000000	500	1	1.3	0.7
	6	  1	300	  150	  0	  0	       1	1.100000	-0.000000	500	1	1.3	0.7
	7	  2	      0	    0	  0	0	     1	1.100000	-0.000000	18	1	1.3	0.7
	8	  2	      0	    0	  0	0	     1	1.100000	-0.000000	22	1	1.3	0.7
	11	1	      0  	  0	  0	0	     1	1.100000	-0.000000	500	1	1.3	0.7
	12	1	      0	    0	  0	0	     1	1.100000	-0.000000	500	1	1.3	0.7
	13	2	      0	    0	  0	0   	 1	1.100000	-0.000000	22	1	1.3	0.7
	14	2	      0	    0	  0	0	     1	1.100000	-0.000000	22	1	1.3	0.7
	15	1	      1200	500	0	0	     1	1.100000	-0.000000	500	1	1.3	0.7
	16	1	      500	  200	0	212.53 1	1.100000	-0.000000	345	1	1.3	0.7
	17	1	      0	    0	  0	0	     1	1.100000	-0.000000	345	1	1.3	0.7
	18	2	      0	    0	  0	0	     1	1.100000	-0.000000	22	1	1.3	0.7
	19	2	      0	    0	  0	0	     1	1.100000	-0.000000	22	1	1.3	0.7
	20	1	      0	    0	  0	0	     1	1.100000	-0.000000	345	1	1.3	0.7
	21	1	      0	    0	  0	0	     1	1.100000	-0.000000	500	1	1.3	0.7
];


%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	1	777.32	56.57	61.57	51.57000000000001	1.1	100.0	1	782.32	772.32	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	-1000.0	0.0
	7	900.0	-51.56	-46.56	-56.56	1.1	100.0	1	905.0000000000001	894.9999999999999	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	-1000.0	0.0
	8	900.0	-51.56	-46.56	-56.56	1.1	100.0	1	905.0000000000001	894.9999999999999	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	-1000.0	0.0
	13	500.0	-5.61	-0.6100000000000003	-10.61	1.1	100.0	1	505.0	495.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	-1000.0	0.0
	14	500.0	-5.61	-0.6100000000000003	-10.61	1.1	100.0	1	505.0	495.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	-1000.0	0.0
	18	600.0	23.78	28.78	18.78	1.1	100.0	1	605.0	595.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	-1000.0	0.0
	19	600.0	23.78	28.78	18.78	1.1	100.0	1	605.0	595.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	-1000.0	0.0
];


%% branch data
%    fbus    tbus     r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	2	3	    0.00295	0.0315	  0.539	2100.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	4	5	    0.00094	0.01545	  0.0	  2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	4	5	    0.00094	0.01545	  1.65	2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	4	6	    0.00187	0.03075	  3.28	2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	5	6	    0.00119	0.0178	  2.464	2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	6	11	  0.00058	0.00961	  1.017	2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	11 12	  0.00093	0.0163	  1.63	1200.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	15 4	  0.00079	0.0138	  1.4	  2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	15 6	  0.00117	0.0192	  2.05	2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	15 6	  0.00117	0.0192	  2.05	2000.0	0.0	0.0	1.0	0.0	1	-30.0	30.0
	16 20	  0.0034	0.0348	  0.623	2120	0.0	0.0	1.0	0.0	1	-30.0	30.0
	16 17	  0.00392	0.0382	  0.714	2120	0.0	0.0	1.0	0.0	1	-30.0	30.0
	17 20	  0.00583	0.0542	  1.064	2120	0.0	0.0	1.0	0.0	1	-30.0	30.0
	17 2	  0.00296	0.031	    0.54	2120	0.0	0.0	1.0	0.0	1	-30.0	30.0
	21 11	  0.0014	0.02325	  2.472	2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	5	 21	  0.0	    -0.01061	0.0	  2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	1	 2	  0.00017	0.014	    0.0	  1644.5	0.0	0.0	1.0	0.0	1	-30.0	30.0
	3	 4	  0.00016	0.025	    0.0	  2000	0.0	0.0	1.0	-0.0	1	-30.0	30.0
	3	 4	  0.00016	0.025	    0.0	  2000	0.0	0.0	1.0	-0.0	1	-30.0	30.0
	3	 4	  7.0e-5	0.025	    0.0	  2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	3	 4	  7.0e-5	0.025	    0.0	  2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	5	 20	  7.0e-5	0.025	    0.0	  2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	5	 20	  7.0e-5	0.025	    0.0	  2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	6	 7	  0.00012	0.011	    0.0	  1200	0.0	0.0	1.0	0.0	1	-30.0	30.0
	6	 8	  0.00012	0.011	    0.0	  1200	0.0	0.0	1.0	0.0	1	-30.0	30.0
	12 13	  8.0e-5	0.015	    0.0	  750	  0.0	0.0	1.0	0.0	1	-30.0	30.0
	12 14	  8.0e-5	0.015	    0.0	  750  	0.0	0.0	1.0	0.0	1	-30.0	30.0
	16 15  	7.0e-5	0.025	    0.0	  2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	16 15	  7.0e-5	0.025	    0.0	  2000	0.0	0.0	1.0	0.0	1	-30.0	30.0
	17 18	  0.00017	0.012	    0.0	  1644.5	0.0	0.0	1.0	0.0	1	-30.0	30.0
	17 19	  0.00017	0.013	    0.0	  1644.5	0.0	0.0	1.0	0.0	1	-30.0	30.0
];


%%-----  OPF Data  -----%%

%% generator cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0	0	3	0.11	5.0	0.0
	2	0	0	3	0.11	5.0	0.0
	2	0	0	3	0.11	5.0	0.0
	2	0	0	3	0.11	5.0	0.0
	2	0	0	3	0.11	5.0	0.0
	2	0	0	3	0.11	5.0	0.0
	2	0	0	3	0.11	5.0	0.0
];


%%-----  GMD - Thermal Data  -----%%

%% gmd_bus data
%column_names% parent_index status g_gnd name
mpc.gmd_bus = {
	1	  1	5.0	              'dc_sub1'
	2	  1	5.0	              'dc_sub2'
	3	  1	5.0	              'dc_sub3'
	4	  1	1.0	              'dc_sub4'
	5	  1	10.0	            'dc_sub5'
	6	  1	10.0	            'dc_sub6'
	7	  1	4.621712806766188	'dc_sub7'
	8	  1	10.0	            'dc_sub8'
	1	  1	0.0	              'dc_bus1'
	2	  1	0.0	              'dc_bus2'
	3	  1	0.0	              'dc_bus3'
	4	  1	0.0	              'dc_bus4'
	5	  1	0.0	              'dc_bus5'
	6	  1	0.0	              'dc_bus6'
	7	  1	0.0	              'dc_bus7'
	8	  1	0.0	              'dc_bus8'
	11	1	0.0 	            'dc_bus11'
	12	1	0.0	              'dc_bus12'
	13	1	0.0	              'dc_bus13'
	14	1	0.0	              'dc_bus14'
	15	1	0.0	              'dc_bus15'
	16	1	0.0	              'dc_bus16'
	17	1	0.0	              'dc_bus17'
	18	1	0.0	              'dc_bus18'
	19	1	0.0	              'dc_bus19'
	20	1	0.0	              'dc_bus20'
	21	1	0.0	              'dc_bus21'
};

%% gmd_branch data
%column_names% f_bus t_bus parent_index br_status br_r br_v len_km name
mpc.gmd_branch = {
	10	11	1	  1	1.1704125	           120.0              	 120.81939273462899	  'dc_br1'
	12	13	2	  1	0.7833333333333333	 116.0              	 161.49436872495582	  'dc_br2'
	12	13	3	  1	0.7833333333333333	 116.0               	 161.49436872495582	  'dc_br3'
	12	14	4	  1	1.5583333333333333	 160.5               	 321.81790843092256	  'dc_br4'
	13	14	5	  1	0.9916666666666667	 321.0               	 205.02104684716693	  'dc_br5'
	14	17	6  	1	0.48333333333333334	 -20.0                 99.11107851638545	  'dc_br6'
	17	18	7	  1	0.775	               160.0              	 160.29318090362787	  'dc_br7'
	21	12	8	  1	0.6583333333333333	 -129.0                136.9370288107594	  'dc_br8'
	21	14	9	  1	0.9750000000000001	 191.0              	 201.56362020739277	  'dc_br9'
	21	14	10	1	0.9750000000000001	 191.0              	 201.56362020739277	  'dc_br10'
	22	26	11	1	1.34895	             1.0                	 138.6435468799988	  'dc_br11'
	22	23	12	1	1.5552599999999999	 -155.0                160.47336211212942	  'dc_br12'
	23	26	13	1	2.3130525	           158.0               	 238.16588676612818	  'dc_br13'
	23	10	14	1	1.17438	             -93.0                 121.05590409010416	  'dc_br14'
	27	17	15	1	1.1666666666666667	 169.0              	 241.42124977424734	  'dc_br15'
	12	4	  18	1	0.06666666666666667	 0.0	                 0.0	                'dc_xf2_hi'
	11	4	  18	1	0.03333333333333333	 0.0	                 0.0	                'dc_xf2_lo'
	12	4	  19	1	0.06666666666666667	 0.0	                 0.0	                'dc_xf3_hi'
	11	4	  19	1	0.03333333333333333	 0.0	                 0.0	                'dc_xf3_lo'
	12	11	20	1	0.02	               0.0	                 0.0	                'dc_xf4_series'
	11	4	  20	1	0.013333333333333334 0.0	                 0.0	                'dc_xf4_common'
	12	11	21	1	0.02	               0.0	                 0.0	                'dc_xf5_series'
	11	4	  21	1	0.013333333333333334 0.0	                 0.0	                'dc_xf5_common'
	13	5	  22	1	0.013333333333333334 0.0	                 0.0	                'dc_xf6_hi'
	26	5	  22	1	0.02	               0.0	                 0.0	                'dc_xf6_lo'
	13	5	  23	1	0.013333333333333334 0.0	                 0.0	                'dc_xf7_hi'
	26	5	  23	1	0.02	               0.0	                 0.0	                'dc_xf7_lo'
	14	6	  24	1	0.049999999999999996 0.0	                 0.0	                'dc_xf8_hi'
	14	6	  25	1	0.049999999999999996 0.0	                 0.0	                'dc_xf9_hi'
	18	8	  26	1	0.03333333333333333	 0.0	                 0.0	                'dc_xf10_hi'
	18	8	  27	1	0.03333333333333333	 0.0	                 0.0	                'dc_xf11_hi'
	21	22	28	1	0.02	               0.0	                 0.0	                'dc_xf12_series'
	22	3	  28	1	0.013333333333333334 0.0	                 0.0	                'dc_xf12_common'
	21	22	29	1	0.02	               0.0	                 0.0	                'dc_xf13_series'
	22	3	  29	1	0.013333333333333334 0.0	                 0.0	                'dc_xf13_common'
	23	2	  30	1	0.03333333333333333	 0.0	                 0.0	                'dc_xf14_hi'
	23	2	  31	1	0.03333333333333333	 0.0	                 0.0	                'dc_xf15_hi'
};


%% branch_gmd data
%column_names% hi_bus lo_bus gmd_br_hi gmd_br_lo gmd_k gmd_br_series gmd_br_common baseMVA type config
mpc.branch_gmd = {
	2	3	-1	-1	-1	-1	-1	100	'line'	'none'
	4	5	-1	-1	-1	-1	-1	100	'line'	'none'
	4	5	-1	-1	-1	-1	-1	100	'line'	'none'
	4	6	-1	-1	-1	-1	-1	100	'line'	'none'
	5	6	-1	-1	-1	-1	-1	100	'line'	'none'
	6	11	-1	-1	-1	-1	-1	100	'line'	'none'
	11	12	-1	-1	-1	-1	-1	100	'line'	'none'
	15	4	-1	-1	-1	-1	-1	100	'line'	'none'
	15	6	-1	-1	-1	-1	-1	100	'line'	'none'
	15	6	-1	-1	-1	-1	-1	100	'line'	'none'
	16	20	-1	-1	-1	-1	-1	100	'line'	'none'
	16	17	-1	-1	-1	-1	-1	100	'line'	'none'
	17	20	-1	-1	-1	-1	-1	100	'line'	'none'
	17	2	-1	-1	-1	-1	-1	100	'line'	'none'
	21	11	-1	-1	-1	-1	-1	100	'line'	'none'
	5	21	-1	-1	-1	-1	-1	100	'series_cap'	'none'
	1	2	-1	-1	1.2	-1	-1	100	'xfmr'	'wye-delta'
	4	3	16	17	1.6	-1	-1	100	'xfmr'	'gwye-gwye'
	4	3	18	19	1.6	-1	-1	100	'xfmr'	'gwye-gwye'
	4	3	-1	-1	1.6	20	21	100	'xfmr'	'gwye-gwye-auto'
	4	3	-1	-1	1.6	22	23	100	'xfmr'	'gwye-gwye-auto'
	5	20	24	25	1.6	-1	-1	100	'xfmr'	'gwye-gwye'
	5	20	26	27	1.6	-1	-1	100	'xfmr'	'gwye-gwye'
	6	7	28	-1	0.8	-1	-1	100	'xfmr'	'gwye-delta'
	6	8	29	-1	0.8	-1	-1	100	'xfmr'	'gwye-delta'
	12	13	30	-1	0.8	-1	-1	100	'xfmr'	'gwye-delta'
	12	14	31	-1	0.8	-1	-1	100	'xfmr'	'gwye-delta'
	15	16	-1	-1	1.1	32	33	100	'xfmr'	'gwye-gwye-auto'
	15	16	-1	-1	1.1	34	35	100	'xfmr'	'gwye-gwye-auto'
	17	18	36	-1	1.2	-1	-1	100	'xfmr'	'gwye-delta'
	17	19	37	-1	1.2	-1	-1	100	'xfmr'	'gwye-delta'
};


%% branch_thermal data
%column_names% xfmr temperature_ambient hotspot_instant_limit hotspot_avg_limit hotspot_rated topoil_time_const topoil_rated topoil_init topoil_initialized hotspot_coeff
mpc.branch_thermal = {
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	0	-1	-1	-1	-1	-1	-1	-1	-1	-1
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
	1	25	280	240	150	71	75	0	1	0.63
};


%% bus_gmd data
%column_names% lat lon
mpc.bus_gmd = {
	33.6135	-87.37367
	33.6135	-87.37367
	33.54789	-86.07461
	33.54789	-86.07461
	32.70509	-84.6634
	33.3773	-82.6188
	33.3773	-82.6188
	33.3773	-82.6188
	34.2522	-82.8363
	34.1956	-81.098
	34.1956	-81.098
	34.1956	-81.098
	33.95506	-84.67935
	33.95506	-84.67935
	34.31044	-86.36576
	34.31044	-86.36576
	34.31044	-86.36576
	32.70509	-84.6634
	32.70509	-84.6634
};


%% time_elapsed
%column_names% seconds
mpc.time_elapsed = 10.0;


%% thermal caps
% thermal_cap_x0 ([per unit])
%column_names% A B C D E F G H I J K
mpc.thermal_cap_x0 = [
	0.23033 0.25000 0.26438 0.27960 0.30000 0.31967 0.33942 0.36153 0.38444 0.40000 0.43894
];
% thermal_cap_y0 ([percent per unit])
%column_names% A B C D E F G H I J K
mpc.thermal_cap_y0 = [
	100.0 93.94 90.0 85.42 80.0 74.73 70.0 64.94 59.97 56.92 50.0
];
% Values are from Fig.2. of https://arxiv.org/pdf/1701.01469.pdf paper


%%-----  SourceID Data  -----%%

%% bus_sourceid data
%column_names% bus_sid
mpc.bus_sourceid = [
	'1 ';
	'2 ';
	'3 ';
	'4 ';
	'5 ';
	'6 ';
	'7 ';
	'8 ';
	'9 ';
	'10 ';
	'11 ';
	'12 ';
	'13 ';
	'14 ';
	'15 ';
	'16 ';
	'17 ';
	'18 ';
	'19 ';
];


%% gen_sourceid data
%column_names% bus_i gen_sid
mpc.gen_sourceid = [
	1 '1 ';
	7 '1 ';
	8 '1 ';
	13 '1 ';
	14 '1 ';
	18 '1 ';
	19 '1 ';
];


%% branch_sourceid data
%column_names% fbus tbus branch_sid
mpc.branch_sourceid = [
2 3 '1 ';
4 5 '1 ';
4 5 '2 ';
4 6 '1 ';
5 6 '1 ';
6 11 '1 ';
11 12 '1 ';
15 4 '1 ';
15 6 '1 ';
15 6 '2 ';
16 20 '1 ';
16 17 '1 ';
17 20 '1 ';
17 2 '1 ';
21 11 '1 ';
5 21 '1 ';
2 1 '1 ';
4 3 '1 ';
4 3 '2 ';
4 3 '3 ';
4 3 '4 ';
5 20 '1 ';
5 20 '2 ';
6 7 '1 ';
6 8 '1 ';
12 13 '1 ';
12 14 '1 ';
15 16 '1 ';
15 16 '2 ';
17 18 '1 ';
17 19 '1 ';
];

%% gmd_blocker data
%column_names% gmd_bus status construction_cost
mpc.gmd_ne_blocker = {
	1	  0 1.0
	2	  1	1.0
	3	  0	1.0
	4	  1	1.0
	5	  0	1.0
	6	  1	1.0
	7	  0	1.0
	8	  1	1.0
};

mpc.load_served_ratio = 1.0
