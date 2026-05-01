function dK = khp(u, ell)
% khp(u,ell) - Dérivée dK/dpsi de la conductivité hydraulique
%
% Theta = Se(psi)
% q = 1 - 1/ell
%
% Se(psi) = 1/(1 + (-psi)^ell)^q    si psi < 0
% Se      = 1                       si psi >= 0
%
% K(Theta) = sqrt(Theta) * (1 - (1 - Theta^(1/q))^q)^2
%
% dK/dpsi = (dK/dTheta) * (dTheta/dpsi)
% -------------------------------------------------------------------------

u = u(:);
dK = zeros(size(u));

q = 1 - 1/ell;

I  = (u < 0);
ps = u(I);

% ---------- Theta = Se(psi)
A     = 1 + (-ps).^ell;        % A = 1 + (-psi)^ell
Theta = A.^(-q);               % Theta = Se

% Bornage physique
Theta = max(0, min(1, Theta));

% ---------- dTheta/dpsi
% dTheta/dpsi = q*ell*(-psi)^(ell-1) * (1+(-psi)^ell)^(-q-1)
dTheta = q*ell .* (-ps).^(ell-1) .* A.^(-q-1);

% ---------- dK/dTheta (dérivée détaillée vérifiée)
% K = Theta^(1/2) * F^2,  F = 1 - (1 - Theta^(1/q))^q
Theta_safe = max(Theta, 1e-14);     % évite Theta=0 dans Theta^(-1/2)

B = Theta_safe.^(1/q);              % B = Theta^(1/q)
oneMinusB = max(1 - B, 1e-14);      % évite (1-B)^(q-1) avec q-1<0
F = 1 - (oneMinusB).^q;             % F = 1 - (1 - B)^q  (version stable)

% dK/dTheta = (1/2)Theta^(-1/2)F^2 + 2 Theta^(1/q - 1/2) F (1-Theta^(1/q))^(q-1)
dKdTheta = 0.5 .* Theta_safe.^(-0.5) .* (F.^2) ...
        + 2.0 .* Theta_safe.^(1/q - 0.5) .* F .* (oneMinusB).^(q-1);

% ---------- dK/dpsi
dK(I) = dKdTheta .* dTheta;

% Saturé : K=1 => dérivée nulle
dK(~I) = 0;

dK = dK(:);
end
