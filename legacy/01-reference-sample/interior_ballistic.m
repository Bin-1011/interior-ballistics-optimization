%% 输入已知数据
clear;close all;%清屏并关闭窗口
h=0.0001; %输入最大步长
global n e1 m diameter f omega rho_p k alpha u1 p0 V0 c% 使e1成为全局变量
n=0.978;               %装药的压力指数n
m=44.2;                %弹丸质量  kg
diameter=152*10^(-3);  %火炮口径 m
f=931000;              %火药力 (J/kg)
omega=3.23;          %弹丸装药量kg
rho_p=1600;            %火药密度 kg/m^(-3)
k=1.2;                 %比热比κ
alpha=0.001;           %余容  m^(-3)/kg
u1=4.558*10^(-10);     %装药烧速系数
p0=3*10^7;             %弹丸起动压力  pa
V0=0.0216;             %药室容积  m^3
c=7.25;                %药粒的长度的一半
pm = [];               %初始化存储pm值的向量
e1 = 0.000236/2;        %设置e1的初始值
times=1;               %循环次数初始值
lg=8.59;
%% 常量计算
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
%% 经典内弹道初值计算
l_0=0;                                                               %炮弹的行程初值 
v_0=0;                                                               %炮弹的速度初值
psi0=((1/delta)-(1/rho_p))/((f/p0)+(alpha-(1/rho_p)));               %已燃烧体积百分比ψ的初值计算
omegaYR=omega*psi0;                                                  %计算启动时燃烧的质量
nu=(V0-(omega-omegaYR)/rho_p)/omegaYR;                               %比容的计算v
Z0=((1+4*lambda*psi0/chi)^0.5-1)/2/lambda;                           %相对已燃烧厚度Z0初值计算
%% 经典内弹道循环计算
options=odeset('maxstep',h,'stat','');                             %设置求解器的最大步长
t0=[0,0.1];                                                          %设置时间
y0=[psi0,Z0,l_0,v_0,p0];                                             %赋初值
[t1,y1]=ode45(@Runge_kutta_pre,t0,y0,options);
%% 寻找启动点
ni=1;
while y1(ni,3)<=lg
      ni=ni+1;
end
ni=ni-1;
lgi=ni;
disp(['行程长为',num2str(y1(lgi,3)) ,'m']);
disp(['炮口初速为',num2str(y1(lgi,4)) ,'m/s']);
ni=1;
while y1(ni,5)<=y1(ni+1,5)
    ni=ni+1;
end
disp(['最大的压力值为',num2str(y1(ni-1,5)/1000000),'MPa'])
%% 第一次绘图
subplot(2,2,1)%利用subplot功能划分四块区域进行绘图
plot(y1(1:lgi,3),y1(1:lgi,5)./1000000,'b');
hold on
legend( 'closed', 'Location', 'northeast' );%添加图例
title('预测的某152mm炮经典闭膛理 论p-l曲线');
xlabel('l/m');
ylabel('p/MPa');

subplot(2,2,2)
plot(t1(1:lgi,1).*1000, y1(1:lgi,5)./1000000,'b');
box on;
title('预测的某152mm炮经典闭膛理论p-t曲线');
legend(  'closed', 'Location', 'northeast' );%添加图例
xlabel('t/ms');
ylabel('p/MPa');

subplot(2,2,3)
plot(t1(1:lgi,1).*1000,y1(1:lgi,4),'b');
box on;
title('预测的某152mm炮经典闭膛理论v-t曲线');
legend( 'closed', 'Location', 'northeast' );%添加图例
xlabel('t/ms');
ylabel('v/m*s^-1')

subplot(2,2,4)
plot(y1(1:lgi,3),y1(1:lgi,4),'b')
title('预测的某152mm炮经典闭膛理论v-l曲线');
legend( 'closed', 'Location', 'northeast' );%添加图例
xlabel('l/m');
ylabel('v/m*s^-1');
