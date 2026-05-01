function ddK = khpp(u, ell)
% khpp(u,ell) - Dérivée seconde d²K/dpsi² pour la loi K(Se(psi))
%
% q = 1 - 1/ell
% Theta(psi)=Se(psi)= (1 + (-psi)^ell)^(-q)      si psi<0 ; =1 si psi>=0
%
% K(Theta)= sqrt(Theta) * (1 - (1 - Theta^(1/q))^q)^2
%
% Chaîne :
%   K'(psi)  = K_Theta * Theta'
%   K''(psi) = K_ThetaTheta*(Theta')^2 + K_Theta*Theta''
% -------------------------------------------------------------------------

u   = u(:);
ddK = zeros(size(u));

q = 1 - 1/ell;

I  = (u < 0);
ps = u(I);                 % psi<0
x  = -ps;                  % x = -psi > 0

% ---------------- Theta = Se(psi) ----------------
A     = 1 + x.^ell;        % A = 1 + (-psi)^ell
Theta = A.^(-q);

% bornage physique (optionnel)
Theta = max(0, min(1, Theta));

% ---------------- Theta' et Theta'' ----------------
% Theta' = q*ell*x^(ell-1) * A^(-q-1)
Theta_p = q*ell .* x.^(ell-1) .* A.^(-q-1);

% Theta'' = -q*ell*(ell-1)*x^(ell-2)*A^(-q-1) + q*ell^2*(q+1)*x^(2ell-2)*A^(-q-2)
Theta_pp = -q*ell*(ell-1) .* x.^(ell-2)   .* A.^(-q-1) ...
           +q*ell^2*(q+1) .* x.^(2*ell-2) .* A.^(-q-2);

% ---------------- K_Theta et K_ThetaTheta ----------------
% Notations:
%   B = Theta^(1/q)
%   U = 1 - B
%   F = 1 - U^q
%
% F'  = U^(q-1) * Theta^(1/q - 1)
% F'' = -(q-1)/q * U^(q-2) * Theta^(1/q - 2)

Theta_safe = max(Theta, 1e-14);      % évite Theta=0 dans Theta^(-1/2), etc.
B          = Theta_safe.^(1/q);
U          = max(1 - B, 1e-14);      % évite U=0 avec puissances q-1, q-2 (q<1)
F          = 1 - U.^q;

Fp  = U.^(q-1) .* Theta_safe.^(1/q - 1);
Fpp = -(q-1)/q .* U.^(q-2) .* Theta_safe.^(1/q - 2);

% K_Theta = 1/2 Theta^(-1/2) F^2 + 2 Theta^(1/2) F F'
K_Theta = 0.5 .* Theta_safe.^(-0.5) .* (F.^2) ...
        + 2.0 .* Theta_safe.^(0.5)  .* F .* Fp;

% K_ThetaTheta = -1/4 Theta^(-3/2) F^2 + 2 Theta^(-1/2) F F'
%                + 2 Theta^(1/2) (F')^2 + 2 Theta^(1/2) F F''
K_ThetaTheta = -0.25 .* Theta_safe.^(-1.5) .* (F.^2) ...
               +2.0  .* Theta_safe.^(-0.5) .* F .* Fp ...
               +2.0  .* Theta_safe.^(0.5)  .* (Fp.^2) ...
               +2.0  .* Theta_safe.^(0.5)  .* F .* Fpp;

% ---------------- K''(psi) ----------------
ddK(I) = K_ThetaTheta .* (Theta_p.^2) + K_Theta .* Theta_pp;

% Saturé : K=1 => dérivées nulles
ddK(~I) = 0;

ddK = ddK(:);
end
