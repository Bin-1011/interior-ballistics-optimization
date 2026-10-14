% =========================================================================
% ballistic_ode.m — 内弹道微分方程组（论文式 2.1）
%
% 状态量：y = [psi; Z; l; v; p]
%   dZ/dt   — 燃速定律 u1/e1*p^n1，Z >= Zb 后燃烧结束（乘逻辑量置零）
%   dpsi/dt — 分段形状函数：主阶段 Z < 1 用 chi/lambda/mu，
%             碎粒阶段 1 <= Z < Zb 用 chi_S/lambda_S
%   dl/dt   — 弹丸行程
%   dv/dt   — 弹丸运动方程 S*p/(phi*m)
%   dp/dt   — 由能量守恒导出，theta = k - 1，lpsi 为药室自由容积缩径长
%
% 由 solve_ballistic.m 经 ode45 调用；params 由 ballistic_design.m 生成。
% 注：lpsi 在本实现中取初值 psi0 计算并视为常数，详见 docs/theory.md 第 8 节。
% =========================================================================
function dy = ballistic_ode(~, y, params)
%计算药室自由容积缩径长lψ

    psi0=((1/params.delta)-(1/params.rho_p))/((params.f/params.p0)+(params.alpha-(1/params.rho_p)));%已燃烧体积百分比ψ的初值计算
    eta0=0;                                               %相对流量η的初值
    lpsi=params.l0*(1-params.delta/params.rho_p-params.delta*(params.alpha-1/params.rho_p)*psi0+params.alpha*params.delta*eta0);
    theta=params.k-1;

    dy(2)=(params.u1/params.e1*((y(5))^params.n1))*(y(2)<params.Zb);%Z的微分方程
    dy(1)=(params.chi+2*params.lambda*params.chi*y(2)+3*params.mu*params.chi*y(2)^2)*dy(2)*(y(2)<1)+(params.chi_S/params.Zb*(1+2*params.lambda_S/params.Zb*y(2)))*dy(2)*(y(2)>=1 && y(2)<params.Zb);%psi的微分方程
    dy(3)=y(4);%即l的微分方程
    dy(4)=(params.S*y(5))/(params.phi*params.m);%速度v的微分方程
    dy(5)=1/(params.S*(y(3)+lpsi))*(params.f*params.omega*dy(1)-theta*params.phi*params.m*y(3)*dy(4)-params.S*y(5)*dy(3));%pressure的微分方程
    dy=dy(:);%列向量的形式


end