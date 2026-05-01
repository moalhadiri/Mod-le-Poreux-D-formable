function Kp = khp(u)
%KHP First derivative dK/du for the van Genuchten–Mualem conductivity model.
%
%   Kp = KHP(u) computes the derivative of the unsaturated hydraulic
%   conductivity K(u) with respect to the pressure head u (h or psi).
%
%   Effective saturation (van Genuchten,for u < 0):
%       Se(u) = (1+(alpha*|u|)^n)^(-m),   Se(u) = 1 for u >= 0
%
%   Mualem conductivity:
%       K(Se) = Ks*Se^L*(1-(1-Se^(1/m))^m )^2,   with L = 1/2
%
%   By the chain rule:
%       K'(u) = Ks*Se'(u)*d/dSe [ Se^L*s(Se)^2 ]
%   where
%       s(Se) = 1-(1-Se^(1/m))^m.
%
%   Input:
%       u  : Pressure head (scalar or vector/array). Unsaturated if u < 0.
%
%   Output:
%       Kp : First derivative dK/du evaluated at u (column vector).
%
%   Notes:
%      -For u >= 0 (saturated),Se is constant (=1),hence Kp = 0.
%      -Se is clamped to (epsSe,1-epsSe) to avoid singularities in powers.

% --- Parameters (adapt to your parametre() output order) ---
[~,~,~,~,~,~,~,~,alpha,~,~,~,~,n,m,Ks] = parametre();

% Mualem pore-connectivity parameter
L = 0.5;

% Ensure column vector
u = u(:);

% ---------------- Effective saturation Se(u) ----------------
Se = ones(size(u));       % saturated by default (u >= 0)
I  = (u < 0);             % unsaturated mask

if any(I)
    absu = abs(u(I));
    X    = (alpha.*absu).^n;
    Se(I)= (1+X).^(-m);
end

% Clamp to avoid 0/1 exactly (fractional powers)
epsSe = 1e-8;
Se = min(max(Se,epsSe),1-epsSe);

% ---------------- First derivative Se'(u) ----------------
dSe_du = zeros(size(u));
if any(I)
    absu = abs(u(I));
    absu = max(absu,1e-14);  % protect |u|^(n-1) near 0
    X    = (alpha.*absu).^n;

    % For u<0: dSe/du = m*n*alpha.^n*|u|.^(n-1)*(1+X)^(-m-1)
    dSe_du(I) = m.*n.*(alpha.^n).*(absu.^(n-1)).*(1+X).^(-m-1);
end
% For u>=0: dSe/du = 0

% ---------------- Auxiliary terms ----------------
Se_pow = Se.^(1/m);       % Se^(1/m)
omT    = 1-Se_pow;      % 1-Se^(1/m)
s      = 1-omT.^m;      % s(Se) = 1-(1-Se^(1/m))^m
B      = omT.^(m-1);      % (1-Se^(1/m))^(m-1)

% d/dSe [ Se^L*s(Se)^2 ] = L*Se^(L-1)*s^2+2*Se^L*s*s'(Se)
% with s'(Se) = B*Se^(1/m-1)
term1   = L.*Se.^(L-1).*(s.^2);
term2   = 2.*Se.^L.*s.*B.*Se.^(1/m-1);
bracket = term1+term2;

% ---------------- Final: K'(u) ----------------
Kp = Ks.*dSe_du.*bracket;

% Ensure column output
Kp = Kp(:);
