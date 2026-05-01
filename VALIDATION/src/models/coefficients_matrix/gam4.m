function g=gam4(u,p,t)
eps=1e-8;
[~,~,dzu]=edp3dgrad(p,t,u);
g00=ell(u).*dg2(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3))+g00(t(:,4)))./4;
g=c.*(dzu+eps);
