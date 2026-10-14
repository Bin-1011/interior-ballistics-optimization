% =========================================================================
% solve_ballistic.m — 内弹道方程组求解器
%
% 输入：params — 由 ballistic_design.m 生成的结构体
% 输出：t      — 时间序列 (s)
%       y      — 状态量矩阵，各列为 [psi, Z, l, v, p]
%
% 初值：psi0 由挤进压力 p0 计算；Z0 由形状函数反解；
%       行程与速度初值为 0，压力初值取挤进压力 p0。
% 求解：ode45（变步长 Runge–Kutta 4(5)），t ∈ [0, 0.1] s，
%       MaxStep = 1e-4，RelTol = 1e-6，以限制压力峰值附近的步长。
% =========================================================================
function [t, y] = solve_ballistic(params)
    % 设置ODE初始条件
    h = 0.0001;   %步长
    l_0 = 0;                                                               %炮弹的行程初值 
    v_0 = 0; 
    t0 = [0,0.1];
    psi0 = (1 / params.delta - 1 / params.rho_p) / (params.f / params.p0 + (params.alpha - 1 / params.rho_p));
    Z0=((1+4*params.lambda*psi0/params.chi)^0.5-1)/2/params.lambda;  
    y0 = [psi0; Z0; l_0; v_0; params.p0];  % [ψ, Z, l, v, p]
    
    % 求解弹道微分方程
    options = odeset('MaxStep', h, 'RelTol', 1e-6); 
    [t, y] = ode45(@(t,y) ballistic_ode(t, y, params), t0, y0, options);
end