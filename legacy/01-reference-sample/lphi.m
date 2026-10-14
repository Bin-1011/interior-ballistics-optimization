function [lphi] = lphi(eta,psi)
%计算药室自由容积缩径长lψ
global diameter  omega rho_p alpha  V0  % 使e1成为全局变量
delta=omega/V0;             %Δ装填密度 kg/m^(-3)
S=3.1415926/4*diameter^2;   %火炮炮膛横断面积m^2
l0=V0/S;                    %等效圆柱体的长度  
lphi=l0*(1-delta/rho_p-delta*(alpha-1/rho_p)*psi+alpha*delta*eta);
end

