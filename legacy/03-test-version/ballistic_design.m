function params = ballistic_design(e1, eta)
%起始参量的确定

    params.diameter = 152e-3;   %口径
    params.m = 44.2;        %弹丸质量
    params.v_g = 650 ;       %弹丸设计初速Vg
    params.P_mT = 220;      %最大压力
    params.chi_k = 1.19;         %药室扩大系数
    params.delta = 0.55e3;       %装填密度
    params.lambda_g = 7;     %弹丸相对行程长
    params.phi1 = 1.03;    %阻力系数
    params.eta = eta;    %装药利用系数

    
    params.omega = (params.m * params.v_g ^ 2) / ( 2e3 * params.eta);%装药质量
    params.lambda1 = 1 / 2 * (1/params.chi_k + params.lambda_g) / (1 + params.lambda_g); %λ1
    params.lambda2 = 1 / 3 * (1/params.chi_k + params.lambda_g) / (1 + params.lambda_g); %λ2
    params.phi = params.phi1 + params.lambda2 * params.omega / params.m;  %次要功计算系数
    params.p_m = 1.065 * params.phi * params.P_mT / (1 + params.lambda1 * params.omega / params.m) * 1e6; %弹道设计压力（平均压力）

%选定火药性质、形状
    params.n = 7; %孔数
    params.f = 931000; %火药力
    params.k = 1.2; %比热比
    params.alpha =  0.001; %余容
    params.rho_p = 1600; %火药密度
    params.u1 = 4.558e-9; %燃速系数 
    params.n1 = 0.89; %燃速指数
    params.c = 14.5e-3/2; %药粒半长
    params.eta_s = 0.82; %膛线深度特征量 

    params.V0 = params.omega / params.delta; %药室容积
    params.S = params.eta_s * params.diameter ^ 2; %身管截面积
    params.p0 = 3e7;  %挤进压力
    params.l0 = params.V0 / params.S; %等效圆柱体的长度 
    params.l_v0 = params.l0 / params.chi_k;

%火药弧厚的确定
    params.e1 = e1;  %火药弧厚
    
%火药其他参数计算    
    d0 = 0.4e-3; %内孔直径
    D0 = 8 * params.e1 + 3 * d0; %药粒外径
    beta = params.e1 / params.c;   %β
    r = d0/2; %内孔半径
    Pi1 = (D0 + d0 * 7) / (2*params.c); %Π1
    Q1 = (D0^2 - params.n*d0^2) / (4*params.c^2);
    
    params.mu = -(params.n - 1)*beta^2/(Q1 + 2*Pi1); %火药形状特征量
    params.lambda = (params.n - 1 - 2*Pi1)*beta/(Q1 + 2*Pi1); %火药形状特征量
    params.chi = (Q1 + 2*Pi1)/Q1 * beta; %火药形状特征量
    params.rho = 0.2956*(r + params.e1);  %与碎粒断面相当的内切圆半径
    
    params.psi_S = params.chi * (1 + params.mu + params.lambda);
    params.Zb = (params.e1 + params.rho) / params.e1;
    params.chi_S = (1 - params.psi_S * params.Zb ^ 2) / (params.Zb - params.Zb ^ 2);
    params.lambda_S = params.psi_S / params.chi_S - 1;
end