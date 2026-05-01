function g0=gam2(u,p,t)
g00=ellp(u).*dg2(u);
[~,~,dzu]=edp3dgrad(p,t,u);
gg=(dzu+eps).^2;  
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3))+g00(t(:,4)))./4;
g0=c.*gg;