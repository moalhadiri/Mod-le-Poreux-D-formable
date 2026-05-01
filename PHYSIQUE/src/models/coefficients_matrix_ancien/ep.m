function dep = ep(u, ell)
% ep(u,ell) - Dérivée de la fonction de retrait e(u)
%
% Définition :
%   q = 1 - 1/ell
%   Se(u) = 1 / (1 + (-u)^ell)^q      si u < 0
%   Se    = 1                         si u >= 0
%
%   e(Se) = exp(Se) - Se
%
% Chaîne :
%   de/du = (exp(Se) - 1) * dSe/du
% -------------------------------------------------------------------------

u = u(:);
dep = zeros(size(u));

q = 1 - 1/ell;

I  = (u < 0);
ps = u(I);

% ---------- Se(u)
A  = 1 + (-ps).^ell;
Se = A.^(-q);

% Bornage physique
Se = max(0, min(1, Se));

% ---------- dSe/du
dSe = q*ell .* (-ps).^(ell-1) .* A.^(-q-1);

% ---------- de/du = (exp(Se) - 1) * dSe/du
dep(I) = (exp(Se) - 1) .* dSe;

% Saturé : dérivée nulle
dep(~I) = 0;

dep = dep(:);
end
