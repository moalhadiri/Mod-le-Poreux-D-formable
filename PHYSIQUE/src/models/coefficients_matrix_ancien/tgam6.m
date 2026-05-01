function g=tgam6(u,t)
g0=kh(u).*g1(u);
g=(g0(t(:,1))+g0(t(:,2))+g0(t(:,3))+g0(t(:,4)))./4;