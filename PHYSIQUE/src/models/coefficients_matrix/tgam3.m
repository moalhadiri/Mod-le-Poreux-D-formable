function g=tgam3(u,p,t)
[dxu,dyu,~]=edp3dgrad(p,t,u);
g00=khp(u).*g1(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3))+g00(t(:,4)))./4;
g=c.*(dxu+dyu+eps);
