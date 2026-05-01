function g=gam6(u,t)
g0=ell(u).*g2(u);
g=(g0(t(:,1))+g0(t(:,2))+g0(t(:,3))+g0(t(:,4)))./4;