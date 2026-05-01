function K = kh(u)
%kh Unsaturated hydraulic conductivity K(u) (van Genuchten–Mualem).
%
%   K = kh(u) evaluates the hydraulic conductivity as a function of the
%   pressure head u (h or psi),using the van Genuchten retention curve and
%   the Mualem conductivity model.
%
%   Effective saturation (van Genuchten):
%       Se(u) = (1+(alpha*|u|)^n)^(-m),  for u < 0
%       Se(u) = 1,                        for u >= 0
%
%   Conductivity (Mualem–van Genuchten):
%       K(Se) = Ks*Se^L*( 1-(1-Se^(1/m))^m)^2,  with L = 1/2
%
%   Input:
%       u : Pressure head (scalar or vector/array). Unsaturated if u < 0.
%
%   Output:
%       K : Hydraulic conductivity evaluated at u (column vector).
%
%   Notes:
%      -For u >= 0 (saturated),K is set to Ks.
%      -Se is clamped to (epsSe,1-epsSe) to avoid numerical issues with
%         fractional powers.

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

% Physical/numerical clamp
epsSe = 1e-8;
Se = min(max(Se,epsSe),1-epsSe);

% ---------------- Conductivity K(u) ----------------
K = Ks.*(Se.^L).*(1-(1-Se.^(1./m)).^m).^2;

% Enforce saturated branch explicitly
K(u >= 0) = Ks;

% Ensure column output
K = K(:);