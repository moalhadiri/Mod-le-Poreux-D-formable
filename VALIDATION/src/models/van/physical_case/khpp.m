function Kpp = khpp(u)
%khpp Second derivative d^2K/du^2 for the van Genuchten–Mualem model.
%
%   Kpp = khpp(u) computes the second derivative of the unsaturated hydraulic
%   conductivity K(u) with respect to the pressure head u (often denoted h or psi).
%
%   Effective saturation (van Genuchten,for u < 0):
%       Se(u) = (1+(alpha*|u|)^n)^(-m),   Se(u) = 1 for u >= 0
%
%   Mualem conductivity:
%       K(Se) = Ks*Se^L*(1-(1-Se^(1/m))^m )^2,   with L = 1/2
%
%   Using the chain rule:
%       K''(u) = Ks*[ Se''(u)*A(Se)+(Se'(u))^2*A_Se(Se) ]
%   where A(Se) = dK/dSe / Ks and A_Se(Se) = d^2K/dSe^2 / Ks.
%
%   Input:
%       u   : Pressure head (scalar or vector/array). Convention: unsaturated if u<0.
%
%   Output:
%       Kpp : Second derivative d^2K/du^2 evaluated at u (column vector).
%
%   Notes:
%      -For u >= 0 (saturated),Se is constant (=1),hence Se'(u)=Se''(u)=0
%         and Kpp = 0.
%      -A small clamp is applied to Se to avoid singularities in fractional powers.

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
    X    = (alpha*absu).^n;      % (alpha|u|)^n
    Se(I)= (1+X).^(-m);
end

% Physical/numerical clamp (avoid 0 or 1 exactly -> fractional power issues)
epsSe = 1e-8;
Se = min(max(Se,epsSe),1-epsSe);

% ---------------- First derivative dSe/du ----------------
dSe_du = zeros(size(u));
if any(I)
    absu = abs(u(I));
    absu = max(absu,1e-14);        % protect absu^(n-1) near 0
    X    = (alpha*absu).^n;

    % For u<0: dSe/du = m*n*alpha^n*|u|^(n-1)*(1+X)^(-m-1)  (positive because d|u|/du=-1)
    dSe_du(I) = m*n*(alpha.^n).*(absu.^(n-1)).*(1+X).^(-m-1);
end
% For u>=0: dSe/du = 0

% ---------------- Second derivative d2Se/du2 ----------------
d2Se_du2 = zeros(size(u));
if any(I)
    absu = abs(u(I));
    absu = max(absu,1e-14);        % protect absu^(n-2) near 0
    X    = (alpha*absu).^n;
    C    = m*n*(alpha.^n);

    % For u<0:
    % d2Se/du2 = -C*(n-1)|u|^(n-2)(1+X)^(-m-1)+C*(m+1)*n*alpha^n*|u|^(2n-2)(1+X)^(-m-2)
    term1 = -(C)*(n-1)*(absu.^(n-2)).*(1+X).^(-m-1);
    term2 =  (C)*(m+1)*n*(alpha.^n).*(absu.^(2*n-2)).*(1+X).^(-m-2);

    d2Se_du2(I) = term1+term2;
end
% For u>=0: d2Se/du2 = 0

% ---------------- Auxiliary quantities (Se-based) ----------------
Theta = Se;                 % rename (legacy notation)
T     = Theta.^(1/m);       % Se^(1/m)
omT   = 1-T;              % 1-Se^(1/m)
S     = 1-omT.^m;         % 1-(1-Se^(1/m))^m
B     = omT.^(m-1);         % (1-Se^(1/m))^(m-1)

% ---------------- A(Se) and A_Se(Se) for L = 1/2 ----------------
% A(Theta) corresponds to d/dTheta [ Theta^L*S(Theta)^2 ] with L=1/2,divided by 1 (Ks factored later)
A = 0.5*Theta.^(-1/2).*(S.^2) ...
 +2.0.*S.*B.*Theta.^(1/m-1/2);

% Second derivative w.r.t. Theta
omT_pow_m_2 = omT.^(m-2);
A_Theta = (-0.25)*Theta.^(-3/2).*(S.^2) ...
       +(2/m).*S.*B.*Theta.^(1/m-3/2) ...
       +2.0.*(B.^2).*Theta.^(2/m-3/2) ...
       -2.0*((m-1)/m).*S.*omT_pow_m_2.*Theta.^(2/m-3/2);

% ---------------- Final: second derivative of K(u) ----------------
Kpp = Ks.*(d2Se_du2.*A+(dSe_du.^2).*A_Theta );

% Ensure column output
Kpp = Kpp(:);
