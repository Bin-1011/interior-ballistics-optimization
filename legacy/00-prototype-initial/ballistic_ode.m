function dy = ballistic_ode(~, y, params)
    % % 解包变量
    % psi = y(1); Z = y(2); l = y(3); v = y(4); p = y(5);
    % 
    % % 燃烧阶段判断
    % if Z < 1
    %     dZdt = params.u1/params.e1 * p^params.n;
    %     dpsidt = (params.chi + 2*params.lambda*params.chi*Z + 3*params.mu*params.chi*Z^2) * dZdt;
    % else
    %     dZdt = 0;  % 燃烧结束
    %     dpsidt = 0;
    % end
    
    % 次要功系数更新
    phi = 1.06 + (1/3)*params.omega/params.m;
    psi_s=params.chi*(1+params.lambda+params.mu);
    chi_s=(1-psi_s*params.ZK*params.ZK)/(params.ZK-params.ZK*params.ZK);
    lambda_s=psi_s/chi_s-1;
    theta=params.k-1;

    dy(2)=(params.u1/params.e1*(y(5)^params.n))*(y(2)<params.ZK);%Z的微分方程
    dy(1)=(params.chi+2*params.lambda*params.chi*y(2)+3*params.mu*params.chi*y(2)^2)*dy(2)*(y(2)<1)+(chi_s/params.ZK*(1+2*lambda_s/params.ZK*y(2)))*dy(2)*(y(2)>=1 && y(2)<params.ZK);%psi的微分方程
    dy(3)=y(4);%即l的微分方程
    dy(4)=(params.S*y(5))/(phi*params.m);%速度v的微分方程
    dy(5)=1/(params.S*(y(3)+params.lpsi))*(params.f*params.omega*dy(1)-theta*phi*params.m*y(3)*dy(4)-params.S*y(5)*dy(3));%pressure的微分方程
    dy=dy(:);%列向量的形式


    % % 微分方程组
    % dy = zeros(5,1);
    % dy(1) = dpsidt;                % dψ/dt
    % dy(2) = dZdt;                  % dZ/dt
    % dy(3) = v;                     % dl/dt
    % dy(4) = (params.S * p) / (phi * params.m);  % dv/dt
    % dy(5) = (params.f*params.omega*dpsidt - ... 
    %         (params.k-1)*phi*params.m*l*dy(4) - ...
    %         params.S*p*v) / (params.S*(l + params.lpsi));  % dp/dt
end