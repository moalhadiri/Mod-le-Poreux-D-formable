function ddK = khpp(u)
%KHPP Second derivative d²K/du² for the simplified K(Se(u)) model.
%
%   ddK = KHPP(u) computes the second derivative of the hydraulic
%   conductivity K with respect to the pressure head u (psi),for the
%   simplified effective saturation law:
%
%       q = 1-1/ell
%       Theta(u) = Se(u) = (1+(-u)^ell)^(-q),  for u <0
%       Theta(u) = 1,                           for u >=0
%
%   Conductivity model:
%       K(Theta) = sqrt(Theta)*( 1-(1-Theta^(1/q))^q )^2
%
%   Chain rule:
%       K'(u)  = K_Theta(Theta)*Theta'(u)
%       K''(u) = K_ThetaTheta(Theta)*(Theta'(u))^2+K_Theta(Theta)*Theta''(u)
%
%   Inputs:
%       u   : Pressure head (psi),scalar or vector/array.
%       ell : Model exponent (ell > 1),defines q = 1-1/ell.
%
%   Output:
%       ddK : Second derivative d²K/du² evaluated at u (column vector).
%
%   Notes:
%      -For u >= 0 (saturated region),Theta = 1 is constant,hence ddK = 0.
%      -Small safeguards (Theta_safe,U lower bounds) are used to avoid
%         numerical issues with fractional powers.

% Ensure column vector
u = u(:);
ell=3;
% Initialize output
ddK = zeros(size(u));

% Exponent mapping
q = 1-1/ell;

% Unsaturated mask
I = (u < 0);

% Work only on u<0
ps = u(I);      % psi < 0
x  = -ps;       % x = -psi > 0

% ---------------- Theta = Se(u) ----------------
A     = 1+x.^ell;        % A = 1+(-u)^ell
Theta = A.^(-q);

% Optional physical clamp
Theta = max(0,min(1,Theta));

% ---------------- Theta' and Theta'' ----------------
% Theta'  = q*ell*x^(ell-1)*A^(-q-1)
Theta_p  = q*ell.*x.^(ell-1).*A.^(-q-1);

% Theta'' = -q*ell*(ell-1)*x^(ell-2)*A^(-q-1)
%          +q*ell^2*(q+1)*x^(2ell-2)*A^(-q-2)
Theta_pp = -q*ell*(ell-1).*x.^(ell-2)  .*A.^(-q-1) ...
           +q*ell^2*(q+1).*x.^(2*ell-2).*A.^(-q-2);

% ---------------- K_Theta and K_ThetaTheta ----------------
% Notation:
%   B = Theta^(1/q)
%   U = 1-B
%   F = 1-U^q
%
% F'  = U^(q-1)*Theta^(1/q-1)
% F'' = -(q-1)/q*U^(q-2)*Theta^(1/q-2)

Theta_safe = max(Theta,1e-14);  % avoid Theta=0 in Theta^(-1/2),etc.
B          = Theta_safe.^(1/q);
U          = max(1-B,1e-14);  % avoid U=0 for powers q-1,q-2 (q<1)
F          = 1-U.^q;

Fp  = U.^(q-1).*Theta_safe.^(1/q-1);
Fpp = -(q-1)/q.*U.^(q-2).*Theta_safe.^(1/q-2);

% K_Theta = 1/2 Theta^(-1/2) F^2+2 Theta^(1/2) F F'
K_Theta = 0.5.*Theta_safe.^(-0.5).*(F.^2) ...
       +2.0.*Theta_safe.^( 0.5).*F.*Fp;

% K_ThetaTheta = -1/4 Theta^(-3/2) F^2+2 Theta^(-1/2) F F'
%               +2 Theta^(1/2) (F')^2+2 Theta^(1/2) F F''
K_ThetaTheta = -0.25.*Theta_safe.^(-1.5).*(F.^2) ...
               +2.0 .*Theta_safe.^(-0.5).*F.*Fp ...
               +2.0 .*Theta_safe.^( 0.5).*(Fp.^2) ...
               +2.0 .*Theta_safe.^( 0.5).*F.*Fpp;

% ---------------- K''(u) ----------------
ddK(I)  = K_ThetaTheta.*(Theta_p.^2)+K_Theta.*Theta_pp;

% Saturated region: ddK = 0 (already)
ddK(~I) = 0;

% Ensure column output
ddK = ddK(:);