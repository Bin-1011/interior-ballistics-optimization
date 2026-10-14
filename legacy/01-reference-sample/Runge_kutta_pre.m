function dy=Runge_kutta_pre(t,y)
%% 输入已知数据
global n e1 m diameter f omega rho_p k alpha u1 p0 V0 c% 声明e1为全局变量
phi=1.06+1/3*omega/m;            %次要功系数φ
d=e1;
d0=e1;
D0=11*e1;
pi1=(D0+d0*7)/2/c;
Q1=(D0*D0-n*d0*d0)/4/c/c;
beta=e1/c;
chi=(Q1+2*pi1)/Q1*beta;
lambda=(n-1-2*pi1)*beta/(Q1+2*pi1);
mu=-6*beta*beta/(Q1+2*pi1);
psi_s=chi*(1+lambda+mu);
theta=k-1;                                                           %θ=κ-1
delta=omega/V0;                                                      %Δ装填密度 kg/m^(-3)   
S=3.1415926/4*diameter^2;                                            %火炮炮膛横断面积m^2
l0=V0/S;                                                             %等效圆柱体的长度  
rho=0.2956*(d/2+e1);
ZK=(e1+rho)/e1;
chi_s=(1-psi_s*ZK*ZK)/(ZK-ZK*ZK);
lambda_s=psi_s/chi_s-1;
%% 初值计算
psi0=((1/delta)-(1/rho_p))/((f/p0)+(alpha-(1/rho_p)));%已燃烧体积百分比ψ的初值计算
eta0=0;                                               %相对流量η的初值（η0为0，因为时间起点为0，积分也为0）
lpsi=lphi(eta0,psi0);                                 %自由容积缩径长lψ的初值计算
%% 微分方程
dy(2)=(u1/e1*(y(5)^n))*(y(2)<ZK);%Z的微分方程
dy(1)=(chi+2*lambda*chi*y(2)+3*mu*chi*y(2)^2)*dy(2)*(y(2)<1)+(chi_s/ZK*(1+2*lambda_s/ZK*y(2)))*dy(2)*(y(2)>=1 && y(2)<ZK);%psi的微分方程
dy(3)=y(4);%即l的微分方程
dy(4)=(S*y(5))/(phi*m);%速度v的微分方程
dy(5)=1/(S*(y(3)+lpsi))*(f*omega*dy(1)-theta*phi*m*y(3)*dy(4)-S*y(5)*dy(3));%pressure的微分方程
dy=dy(:);%列向量的形式
end