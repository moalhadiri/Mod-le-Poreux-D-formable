function K = kh(u)
%kh Hydraulic conductivity K(u) for the simplified van Genuchten–Mualem model.
%
%   K = kh(u) evaluates the hydraulic conductivity as a function of the
%   pressure head u (psi),using the simplified effective saturation law:
%
%       ell = 3 (fixed here)
%       q = 1-1/ell
%
%       Theta(u) = Se(u) = (1+(-u)^ell)^(-q),  for u < 0
%       Theta(u) = 1,                           for u >= 0
%
%   Conductivity model:
%       K(Theta) = sqrt(Theta) * ( 1-(1-Theta^(1/q))^q )^2
%
%   Input:
%       u : Pressure head (psi),scalar or vector/array.
%
%   Output:
%       K : Hydraulic conductivity evaluated at u (column vector).
%
%   Notes:
%      -For u >= 0 (saturated region),K is set to 1.
%      -Small numerical safeguards are applied to avoid issues with
%         fractional powers.

% Fixed exponent
ell = 3;
q   = 1-1/ell;

% Ensure column vector
u = u(:);

% ---------------- Effective saturation Theta = Se(u) ----------------
Theta = ones(size(u));        % saturated by default
I = (u < 0);                 % unsaturated mask

Theta(I) = 1./(1+(-u(I)).^ell).^q;

% Physical clamp
Theta = max(0,min(1,Theta));

% Numerical safeguard
Theta_safe = max(Theta,1e-14);

% ---------------- Conductivity K(u) ----------------
K = sqrt(Theta_safe).*( 1-(1-Theta_safe.^(1/q)).^q ).^2;

% Saturated region: K = 1
K(u >= 0) = 1;

% Ensure column output
K = K(:);