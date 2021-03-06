function out1 = LRAD_Position(in1,in2,in3)
%LRAD_POSITION
%    OUT1 = LRAD_POSITION(IN1,IN2,IN3)

%    This function was generated by the Symbolic Math Toolbox version 8.1.
%    25-Oct-2018 18:06:04

R5cut1_1 = in3(37);
R5cut1_2 = in3(40);
R5cut1_3 = in3(43);
R5cut2_1 = in3(38);
R5cut2_2 = in3(41);
R5cut2_3 = in3(44);
R5cut3_1 = in3(39);
R5cut3_2 = in3(42);
R5cut3_3 = in3(45);
p5cut1 = in2(13);
p5cut2 = in2(14);
p5cut3 = in2(15);
q38 = in1(38,:);
q39 = in1(39,:);
t2 = cos(q39);
t3 = cos(q38);
t4 = sin(q38);
t5 = sin(q39);
t6 = R5cut1_1.*t3;
t7 = t6-R5cut1_3.*t4;
t8 = R5cut2_1.*t3;
t9 = t8-R5cut2_3.*t4;
t10 = R5cut3_1.*t3;
t11 = t10-R5cut3_3.*t4;
out1 = [R5cut1_2.*(-3.320245815631739e-1)+p5cut1-R5cut1_2.*t2.*2.333676409286152e-2-R5cut1_1.*t4.*3.837229637945454e-2-R5cut1_3.*t3.*3.837229637945454e-2+R5cut1_2.*t5.*1.408883625203207e-2+t2.*t7.*1.408883625203207e-2+t5.*t7.*2.333676409286152e-2;R5cut2_2.*(-3.320245815631739e-1)+p5cut2-R5cut2_2.*t2.*2.333676409286152e-2-R5cut2_1.*t4.*3.837229637945454e-2-R5cut2_3.*t3.*3.837229637945454e-2+R5cut2_2.*t5.*1.408883625203207e-2+t2.*t9.*1.408883625203207e-2+t5.*t9.*2.333676409286152e-2;R5cut3_2.*(-3.320245815631739e-1)+p5cut3-R5cut3_2.*t2.*2.333676409286152e-2-R5cut3_1.*t4.*3.837229637945454e-2-R5cut3_3.*t3.*3.837229637945454e-2+R5cut3_2.*t5.*1.408883625203207e-2+t2.*t11.*1.408883625203207e-2+t5.*t11.*2.333676409286152e-2];
