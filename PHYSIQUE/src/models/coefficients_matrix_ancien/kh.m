function K = kh(u, ell)
% K(h) - Conductivité hydraulique (van Genuchten–Mualem modifiée)
% Entrée :
%   u   : potentiel matriciel psi (négatif en non saturé)
%   ell : paramètre (>1)
% Sortie :
%   K   : conductivité hydraulique correspondante
%
% Définition :
%   q = 1 - 1/ell
%   Se(psi) = 1 / (1 + (-psi)^ell)^q    si psi < 0
%   Se      = 1                         si psi >= 0
%
%   K(Theta) = sqrt(Theta) * (1 - (1 - Theta^(1/q))^q)^2
%   avec Theta = Se
% -------------------------------------------------------------------------

u = u(:);

q = 1 - 1/ell;

% Saturation effective Se
Se = ones(size(u));
I  = (u < 0);
Se(I) = 1 ./ (1 + (-u(I)).^ell).^q;

% Bornage physique
Se = max(0, min(1, Se));

% Conductivité K(Theta) avec Theta = Se
Theta = Se;

% Protection numérique pour éviter 0^(1/q) si Theta=0 et q<1, etc.
Theta_safe = max(Theta, 0);   % (tu peux mettre eps si tu veux éviter exactement 0)

K = sqrt(Theta_safe) .* ( 1 - (1 - Theta_safe.^(1/q)).^q ).^2;

% Saturé : K=1
K(u >= 0) = 1;

K = K(:);
end

