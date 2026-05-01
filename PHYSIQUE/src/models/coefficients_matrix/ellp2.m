function g=ellp2(u)
g=khpp(u).*gz(u).^2 + khp(u).*(2*dgz(u).*gz(u)) +  2.*khp(u).*dgz(u).*gz(u)   +   2*kh(u).*d2gz(u).*gz(u)  +2*kh(u).*dgz(u).^2     ;
