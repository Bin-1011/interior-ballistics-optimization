function dy=ndd_fun(t,y,C)
chi=C(1);
lambda=C(2);
lambda_s=C(3);
chi_s=C(4);
Z_s=C(5);
mu=C(12);
theta=C(6);
B=C(7);
V=C(8);
Delta=C(9);
delta=C(10);%rhop
alpha=C(11);

Z=y(1);l=y(2);v=y(3);
psi=(Z>=0&Z<1).*(chi*Z.*(1+lambda*Z+mu*Z^2))+...
    (Z>=1&Z<Z_s).*(chi_s.*(1+lambda_s*Z))+...
    (Z>=Z_s)*1;
l_psi=1-(Delta/delta)*(1-psi)-alpha*Delta*psi;
p=(psi-v*v)/(1+l_psi);
dy(1)=sqrt((theta/(2*B))*(p^V)*(Z>=0&Z<=Z_s));
dy(2)=v;
dy(3)=theta*p/2;
dy=[dy(1);dy(2);dy(3)];
end