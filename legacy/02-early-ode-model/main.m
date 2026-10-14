%% 内弹道基础参数（火炮系统参数）
%59-130
A=1.394;
G=33.4; %质量
WO=18.56;
l_g=59.52;
P_0=30000;
fail=1.02;
K=1.03;
theta=0.2;
%% 燃烧过程参数
f=950000;
alpha=1;
delta=1.6;
%% 弹道运动参数
ome=12.9;
u1=5.0024*10^-5;
n1=0.82;
lambda=-0.0071;
lambda_s=0;
chi=1.00716;
chi_s=0;
mu=0;
etl=1.14*10^-2;
d1=2.5*10^-2;
Rol=0;
%% ------------------ 弹道方程中间量计算 ------------------
l_0=WO/A;
Delta=ome/WO;
phi=K+ome/(3*G);
v_j=196*f*ome/(phi*theta*G);
v_j=sqrt(v_j);
B=98*(etl*A)^2/(u1*u1*f*ome*phi*G);
B=B*(f*Delta)^(2-2*n1);
Z_s=1+Rol*(d1/2+etl)/etl;
p_0=P_0/(f*Delta);
psi_0=(1/Delta-1/delta)/(f/P_0+alpha-1/delta);
Z_0=(sqrt(1+4*psi_0*lambda/chi)-1)/(2*lambda);
%% 参数矩阵组装（传递给ODE求解器）
C=zeros(1,12);
C(1)=chi;C(2)=lambda;C(3)=lambda_s;C(4)=chi_s;C(5)=Z_s;
C(6)=theta;C(7)=B;C(8)=n1;C(9)=Delta;C(10)=delta;C(11)=alpha;C(12)=mu;
C;
%% 微分方程求解（弹道方程组）
y0=[Z_0;0;0;psi_0];
options=odeset('outputfcn','odeplot');
% 首次粗算确定临界时间点
[tt,y]=ode45(@ndd_fun,0:100,[Z_0;0;0],options,C);
l=y(:,2);
l=l*l_0;
f1=find(l>=l_g);
f1=min(f1);
% 精确求解至临界点
[tt,y]=ode45(@ndd_fun,0:0.005:f1,[Z_0;0;0],options,C);
%% 弹道参数后处理
Z=y(:,1);lx=y(:,2);vx=y(:,3);
% 燃烧百分比分段计算
psi=(Z>=0&Z<1).*(chi*Z.*(1+lambda*Z+mu*Z) )+...%%%%%%%%%
    (Z>=1&Z<Z_s).*(chi_s*Z.*(1+lambda_s*Z) )+...
    (Z>=Z_s)*1;
% 膨胀功计算
l_psi=1-(Delta/delta)*(1-psi)-alpha*Delta*psi;
% 压力转换计算
px=(psi-vx.*vx)./(lx+l_psi);
p=px*f*Delta/100;
v=vx*v_j/10;
l=lx*l_0;
t=tt*l_0*1000/v_j;
%% 数据截断（弹丸出膛处理）
f1=find(l>=l_g);
f1=min(f1)+1;
p(f1:end)=[];v(f1:end)=[];l(f1:end)=[];t(f1:end)=[];
%% 特征点计算
% 峰值压力计算
pd=px*f*Delta/100/(1+ome/3/fail/G);
pt=pd*(1+ome/2/fail/G);
aa=max(px);
M=find(px==aa);
% 关键节点数据提取
Pm=[tt(M)*l_0*1000/v_j lx(M)*l_0 vx(M)*v_j/10 px(M)*f*Delta/100 pt(M) pd(M) psi(M) Z(M)];
%ll=length(tt);
ran=find(Z>=1);
ran=min(ran);
Zf=[tt(ran)*l_0*1000/v_j lx(ran)*l_0 vx(ran)*v_j/10 px(ran)*f*Delta/100 pt(ran) pd(ran) psi(ran) Z(ran)];
jie=find(psi>=1);
jie=min(jie);
psij=[tt(jie)*l_0*1000/v_j lx(jie)*l_0 vx(jie)*v_j/10 px(jie)*f*Delta/100 pt(jie) pd(jie) psi(jie) Z(jie)];
pg=[tt(end)*l_0*1000/v_j lx(end)*l_0 vx(end)*v_j/10 px(end)*f*Delta/100 pt(end) pd(end) psi(end) Z(end)];
Ry1=[Zf;psij;pg;Pm];
Ry2=[tt*l_0*1000/v_j lx*l_0 vx*v_j/10 px*f*Delta/100 pt pd psi Z];
%% 结果可视化
subplot(2,2,1);
plot(t,p,'linewidth',2);
grid on;
xlabel('\fontsize{8}\bft (ms)');
ylabel('\fontsize{8}\bfp (kg/cm^{2})');
title('\fontsize{8}\bft-p曲线');
subplot(2,2,2)
plot(t,v,'linewidth',2);
grid on;
xlabel('\fontsize{8}\bft (ms)');
ylabel('\fontsize{8}\bfv (m/s)');
title('\fontsize{8}\bft-v曲线');
subplot(2,2,3)
plot(l,p,'linewidth',2);
grid on;
xlabel('\fontsize{8}\bfl (dm)');
ylabel('\fontsize{8}\bfp (kg/cm^{2})');
title('\fontsize{8}\bfl-p曲线');
subplot(2,2,4)
plot(l,v,'linewidth',2);
grid on;
xlabel('\fontsize{8}\bfl (dm)');
ylabel('\fontsize{8}\bfv (m/s)');
title('\fontsize{8}\bfl-v曲线');
tspan=length(t)/20;
tspan=1:ceil(tspan):length(t);
tspan=length(t);
fprintf(' t(ms) p(kg/cm^2) v(m/s) 1(dm)');
format short g;
Result=[t(tspan) p(tspan) v(tspan) l(tspan)]
format;
psij
pg
%%%%%%%%%%%
% function dy=ndd_fun(t,y,C)
% chi=C(1);lambda=C(2);lambda_s=C(3);chi_s=C(4);Z_s=C(5);mu=C(12);
% theta=C(6);B=C(7);V=C(8);Delta=C(9);delta=C(10);alpha=C(11);
% Z=y(1);l=y(2);v=y(3);
% psi=(Z>=0&Z<1).*(chi*Z.*(1+lambda*Z+mu*Z))+...
%     (Z>=1&Z<Z_s).*(chi_s*Z.*(1+lambda_s*Z))+...
%     (Z>=Z_s)*1;
% l_psi=1-(Delta/delta)*(1-psi)-alpha*Delta*psi;
% p=(psi-v*v)/(1+l_psi);
% dy(1)=sqrt(theta/(2*B))*(Z>=0&Z<=Z_s);
% dy(2)=v;
% dy(3)=theta*p/2;
% dy=[dy(1);dy(2);dy(3)];
% end
% end
