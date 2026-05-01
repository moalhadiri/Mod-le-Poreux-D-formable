function g=gam3(u,p,t)
[~,~,dzu]=edp3dgrad(p,t,u);
g00=ellp(u).*g2(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3))+g00(t(:,4)))./4;
g=c.*(dzu+eps);