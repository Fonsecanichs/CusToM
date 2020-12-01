function [R3cut,p3cut] = f3cut(in1,in2,in3)
%F3CUT
%    [R3CUT,P3CUT] = F3CUT(IN1,IN2,IN3)

%    This function was generated by the Symbolic Math Toolbox version 8.4.
%    24-Nov-2020 16:18:19

R2cut1_1 = in3(10);
R2cut1_2 = in3(13);
R2cut1_3 = in3(16);
R2cut2_1 = in3(11);
R2cut2_2 = in3(14);
R2cut2_3 = in3(17);
R2cut3_1 = in3(12);
R2cut3_2 = in3(15);
R2cut3_3 = in3(18);
p2cut1 = in2(4);
p2cut2 = in2(5);
p2cut3 = in2(6);
q7 = in1(7,:);
q14 = in1(14,:);
q15 = in1(15,:);
q16 = in1(16,:);
q17 = in1(17,:);
q18 = in1(18,:);
t2 = cos(q7);
t3 = cos(q14);
t4 = cos(q15);
t5 = cos(q16);
t6 = cos(q17);
t7 = cos(q18);
t8 = sin(q7);
t9 = sin(q14);
t10 = sin(q15);
t11 = sin(q16);
t12 = sin(q17);
t13 = sin(q18);
t14 = R2cut1_1.*t2;
t15 = R2cut1_3.*t2;
t16 = R2cut1_2.*t3;
t17 = R2cut2_1.*t2;
t18 = R2cut2_3.*t2;
t19 = R2cut2_2.*t3;
t20 = R2cut3_1.*t2;
t21 = R2cut3_3.*t2;
t22 = R2cut3_2.*t3;
t23 = R2cut1_1.*t8;
t24 = R2cut1_3.*t8;
t25 = R2cut1_2.*t9;
t26 = R2cut2_1.*t8;
t27 = R2cut2_3.*t8;
t28 = R2cut2_2.*t9;
t29 = R2cut3_1.*t8;
t30 = R2cut3_3.*t8;
t31 = R2cut3_2.*t9;
t32 = -t24;
t33 = -t27;
t34 = -t30;
t35 = t15+t23;
t36 = t18+t26;
t37 = t21+t29;
t38 = t14+t32;
t39 = t17+t33;
t40 = t20+t34;
t41 = t4.*t35;
t42 = t4.*t36;
t43 = t4.*t37;
t44 = t10.*t35;
t45 = t10.*t36;
t46 = t10.*t37;
t47 = t3.*t38;
t48 = t3.*t39;
t49 = t3.*t40;
t50 = t9.*t38;
t51 = t9.*t39;
t52 = t9.*t40;
t53 = -t50;
t54 = -t51;
t55 = -t52;
t56 = t25+t47;
t57 = t28+t48;
t58 = t31+t49;
t59 = t16+t53;
t60 = t19+t54;
t61 = t22+t55;
t62 = t5.*t56;
t63 = t5.*t57;
t64 = t5.*t58;
t65 = t11.*t56;
t66 = t11.*t57;
t67 = t11.*t58;
t68 = t4.*t59;
t69 = -t62;
t70 = t4.*t60;
t71 = -t63;
t72 = t4.*t61;
t73 = -t64;
t74 = t10.*t59;
t75 = t10.*t60;
t76 = t10.*t61;
t77 = -t74;
t78 = -t75;
t79 = -t76;
t80 = t44+t68;
t81 = t45+t70;
t82 = t46+t72;
t83 = t41+t77;
t84 = t42+t78;
t85 = t43+t79;
t86 = t6.*t80;
t87 = t6.*t81;
t88 = t6.*t82;
t89 = t5.*t83;
t90 = t5.*t84;
t91 = t5.*t85;
t92 = t11.*t83;
t93 = t11.*t84;
t94 = t11.*t85;
t95 = t65+t89;
t96 = t66+t90;
t97 = t67+t91;
t98 = t69+t92;
t99 = t71+t93;
t100 = t73+t94;
t101 = -t12.*(t62-t92);
t102 = -t12.*(t63-t93);
t103 = -t12.*(t64-t94);
t104 = t86+t101;
t105 = t87+t102;
t106 = t88+t103;
R3cut = reshape([t12.*t80+t6.*(t62-t92),t12.*t81+t6.*(t63-t93),t12.*t82+t6.*(t64-t94),t13.*t95+t7.*t104,t13.*t96+t7.*t105,t13.*t97+t7.*t106,t7.*t95-t13.*t104,t7.*t96-t13.*t105,t7.*t97-t13.*t106],[3,3]);
if nargout > 1
    p3cut = [R2cut1_2.*2.821e-1+p2cut1+t14.*4.03e-2-t15.*2.139e-2-t23.*2.139e-2-t24.*4.03e-2+t44.*2.091466666666667e-2-t62.*3.021466666666667e-2-t65.*1.407621558823529e-1+t68.*2.091466666666667e-2-t89.*1.407621558823529e-1+t92.*3.021466666666667e-2;R2cut2_2.*2.821e-1+p2cut2+t17.*4.03e-2-t18.*2.139e-2-t26.*2.139e-2-t27.*4.03e-2+t45.*2.091466666666667e-2-t63.*3.021466666666667e-2-t66.*1.407621558823529e-1+t70.*2.091466666666667e-2-t90.*1.407621558823529e-1+t93.*3.021466666666667e-2;R2cut3_2.*2.821e-1+p2cut3+t20.*4.03e-2-t21.*2.139e-2-t29.*2.139e-2-t30.*4.03e-2+t46.*2.091466666666667e-2-t64.*3.021466666666667e-2-t67.*1.407621558823529e-1+t72.*2.091466666666667e-2-t91.*1.407621558823529e-1+t94.*3.021466666666667e-2];
end