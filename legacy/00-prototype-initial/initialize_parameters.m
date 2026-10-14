function params = initialize_parameters()
    % 基础弹道参数
    params.n = 0.978;               % 压力指数
    params.m = 44.2;                % 弹丸质量 (kg)
    params.diameter = 0.152;        % 口径 (m)
    params.f = 931000;              % 火药力 (J/kg)
    params.omega = 3.23;            % 装药量 (kg)
    params.rho_p = 1600;            % 火药密度 (kg/m³)
    params.k = 1.2;                 % 比热比
    params.alpha = 0.001;           % 余容 (m³/kg)
    params.u1 = 4.558e-10;          % 烧速系数
    params.p0 = 3e7;                % 起动压力 (Pa)
    params.V0 = 0.0216;             % 药室容积 (m³)
    %params.c = 7.25e-3;             % 药粒半长 (m)
    params.c = 7.25;             % 药粒半长 (m)
    params.e1 = 0.000236/2;         % 药粒初始厚度 (m)
    params.lg = 8.59;               % 炮管长度 (m)
    
    % 几何燃烧参数计算
    d = params.e1;                  % 药粒半长
    d0 = params.e1;                 % 初始药粒厚度
    D0 = 11 * params.e1;            % 药粒外径
    pi1 = (D0 + d0 * 7) / (2*params.c);
    Q1 = (D0^2 - params.n*d0^2) / (4*params.c^2);
    beta = params.e1 / params.c;
    delta = params.omega / params.V0; %Δ装填密度 kg/m^(-3)
  
    psi0 = ((1/delta)-(1/params.rho_p))/((params.f/params.p0)+(params.alpha-(1/params.rho_p)));%已燃烧体积百分比ψ的初值计算
    eta=0;                                               %相对流量η的初值（η0为0，因为时间起点为0，积分也为0）
    % 燃烧系数计算
    params.chi = (Q1 + 2*pi1)/Q1 * beta;
    params.lambda = (params.n - 1 - 2*pi1)*beta/(Q1 + 2*pi1);
    params.mu = -6*beta^2/(Q1 + 2*pi1);
    
    % 其他衍生参数（补充原有计算）
    params.S = pi/4 * params.diameter^2;   %火炮炮膛横断面积m^2
    params.l0 = params.V0 / params.S;       %等效圆柱体的长度  
    params.phi = 1.06 + (1/3)*params.omega/params.m;  %次要功系数φ
    params.rho = 0.2956*(d/2 + params.e1); 
    params.ZK = (params.e1 + params.rho)/params.e1;
    params.lpsi = params.l0*(1-delta/params.rho_p-delta*(params.alpha-1/params.rho_p)*psi0+params.alpha*delta*eta);  %自由容积缩径长lψ的初值计算
end