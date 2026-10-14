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