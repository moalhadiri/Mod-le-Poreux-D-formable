function g0=tgam2(u,p,t)
g00=khp(u).*dg1(u);
[dxu,dyu,~]=edp3dgrad(p,t,u);
gg=dxu.^2 + dyu.^2+eps;  
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3))+g00(t(:,4)))/4;
g0=c.*(gg+eps);
