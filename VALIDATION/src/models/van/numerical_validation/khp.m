function dK = khp(u)
%KHP First derivative dK/du for the simplified K(Se(u)) model.
%
%   dK = KHP(u) computes the first derivative of the hydraulic conductivity
%   K with respect to the pressure head u (psi), using the simplified
%   effective saturation law:
%
%       ell = 3 (fixed here)
%       q = 1-1/ell
%
%       Theta(u) = Se(u) = (1+(-u)^ell)^(-q),   for u < 0
%       Theta(u) = 1,                            for u >= 0
%
%   Conductivity model:
%       K(Theta) = sqrt(Theta)*( 1-(1-Theta^(1/q))^q )^2
%
%   Chain rule:
%       dK/du = (dK/dTheta)*(dTheta/du)
%
%   Input:
%       u  : Pressure head (psi), scalar or vector/array.
%
%   Output:
%       dK : First derivative dK/du evaluated at u (column vector).
%
%   Notes:
%      -For u >= 0 (saturated region), Theta is constant (=1), hence dK = 0.
%      -Small safeguards are used to avoid numerical issues in fractional powers.

% Fixed exponent
ell = 3;
q   = 1-1/ell;

% Ensure column vector
u = u(:);

% Initialize output
dK = zeros(size(u));

% Unsaturated region
I  = (u < 0);
ps = u(I);  % psi < 0

% ---------------- Theta = Se(u) ----------------
A     = 1+(-ps).^ell;   % A = 1+(-u)^ell
Theta = A.^(-q);          % Theta = Se(u)

% Optional physical clamp
Theta = max(0, min(1, Theta));

% ---------------- dTheta/du ----------------
% dTheta/du = q*ell*(-u)^(ell-1)*(1+(-u)^ell)^(-q-1), for u<0
dTheta = q.*ell.*(-ps).^(ell-1).*A.^(-q-1);

% ---------------- dK/dTheta ----------------
% K(Theta) = Theta^(1/2)*F^2,
% F = 1-(1-Theta^(1/q))^q
Theta_safe = max(Theta, 1e-14);     % avoid Theta=0 in Theta^(-1/2)

B         = Theta_safe.^(1/q);      % B = Theta^(1/q)
oneMinusB = max(1-B, 1e-14);      % avoid (1-B)^(q-1) with q-1 < 0
F         = 1-(oneMinusB).^q;

% Exact formula used (as in your code):
% dK/dTheta = 1/2 Theta^(-1/2) F^2+2 Theta^(1/q-1/2) F (1-Theta^(1/q))^(q-1)
dKdTheta = 0.5.*Theta_safe.^(-0.5).*(F.^2) ...
       +2.0*Theta_safe.^(1/q-0.5).*F.*(oneMinusB).^(q-1);

% ---------------- dK/du ----------------
dK(I)  = dKdTheta.*dTheta;

% Saturated region: dK = 0 (already)
dK(~I) = 0;

% Ensure column output
dK = dK(:);