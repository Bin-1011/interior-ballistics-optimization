function params = update_geometric_params(params)
    % 重新计算几何参数（当e1改变时调用）
    d = params.e1;                 
    d0 = params.e1;                
    D0 = 11 * params.e1;            
    pi1 = (D0 + d0 * 7) / (2*params.c);
    Q1 = (D0^2 - params.n*d0^2) / (4*params.c^2);
    beta = params.e1 / params.c;
    delta = params.omega / params.V0; %Δ装填密度 kg/m^(-3)
    psi0 = ((1/delta)-(1/params.rho_p))/((params.f/params.p0)+(params.alpha-(1/params.rho_p)));%已燃烧体积百分比ψ的初值计算
    eta=0;                                               %相对流量η的初值（η0为0，因为时间起点为0，积分也为0）
    % 更新燃烧系数
    params.chi = (Q1 + 2*pi1)/Q1 * beta;
    params.lambda = (params.n - 1 - 2*pi1)*beta/(Q1 + 2*pi1);
    params.mu = -6*beta^2/(Q1 + 2*pi1);
    
    % 更新其他依赖参数
    params.S = pi/4 * params.diameter^2;   %火炮炮膛横断面积m^2
    params.l0 = params.V0 / params.S;       %等效圆柱体的长度  
    params.phi = 1.06 + (1/3)*params.omega/params.m;  %次要功系数φ
    params.rho = 0.2956*(d/2 + params.e1); 
    params.ZK = (params.e1 + params.rho)/params.e1;
    params.lpsi = params.l0*(1-delta/params.rho_p-delta*(params.alpha-1/params.rho_p)*psi0+params.alpha*delta*eta);  %自由容积缩径长lψ的初值计算
end