function g=bb(u,p,t)
[~,~,dzu]=edp3dgrad(p,t,u);
g1=g2(u).*ellp2(u);
c=(g1(t(:,1))+g1(t(:,2))+g1(t(:,3))+g1(t(:,4)))./4;
g=c.*(dzu+eps);
end