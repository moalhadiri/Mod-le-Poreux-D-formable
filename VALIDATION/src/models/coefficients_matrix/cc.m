function g=cc(u,t)
g0=g2(u).*ellp(u);
g=(g0(t(:,1))+g0(t(:,2))+g0(t(:,3))+g0(t(:,4)))./4;