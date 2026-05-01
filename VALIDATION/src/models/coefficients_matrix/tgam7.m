function g=tgam7(u,p,t)
[dxu,dyu,~]=edp3dgrad(p,t,u);
dzu=(dxu+dyu+eps).^2;
g00=kh(u).*d2g1(u);
c=(g00(t(:,1))+g00(t(:,2))+g00(t(:,3))+g00(t(:,4)))/4;
g=c.*dzu;