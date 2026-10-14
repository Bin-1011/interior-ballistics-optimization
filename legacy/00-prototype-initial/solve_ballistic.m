function [t, y] = solve_ballistic(params)
    % 设置ODE初始条件
    h = 0.0001;   %步长
    t0 = [0,0.1];
    delta = params.omega / params.V0;
    psi0 = (1/delta - 1/params.rho_p) / (params.f/params.p0 + (params.alpha - 1/params.rho_p));
    Z0=((1+4*params.lambda*psi0/params.chi)^0.5-1)/2/params.lambda;  
    y0 = [psi0; Z0; 0; 0; params.p0];  % [ψ, Z, l, v, p]
    
    % 求解弹道微分方程
    options = odeset('MaxStep', h, 'RelTol', 1e-6);
    %options = odeset('maxstep',h,'stat',''); 
    [t, y] = ode45(@(t,y) ballistic_ode(t, y, params), t0, y0, options);
end