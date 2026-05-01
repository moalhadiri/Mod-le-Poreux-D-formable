function g=tgam4(u,p,t)
eps=1e-8;
[dxu,dyu,~]=edp3dgrad(p,t,u);
g00=kh(u).*dg1(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3))+g00(t(:,4)))/4;
g=c.*(dxu.^2+dyu.^2+eps);
