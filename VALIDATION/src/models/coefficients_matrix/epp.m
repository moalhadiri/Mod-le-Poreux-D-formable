function depp = epp(u, ell)
% epp(u,ell) - Dérivée seconde de la fonction de retrait e(u)
%
% Définition :
%   q = 1 - 1/ell
%   Se(u) = (1 + (-u)^ell)^(-q)        si u < 0
%   Se    = 1                          si u >= 0
%
%   e(Se) = exp(Se) - Se
%
% Chaîne :
%   e'(u)  = (exp(Se) - 1) * Se'
%   e''(u) = exp(Se) * (Se')^2 + (exp(Se) - 1) * Se''
% -------------------------------------------------------------------------

u = u(:);
depp = zeros(size(u));

q = 1 - 1/ell;

I  = (u < 0);
ps = u(I);
x  = -ps;                          % x = -u > 0

% ----- Se(u)
A  = 1 + x.^ell;                   % A = 1 + (-u)^ell
Se = A.^(-q);

% Bornage physique
Se = max(0, min(1, Se));

% ----- Se'(u)
Se_p = q*ell .* x.^(ell-1) .* A.^(-q-1);

% ----- Se''(u)
Se_pp = -q*ell*(ell-1) .* x.^(ell-2)   .* A.^(-q-1) ...
        +q*ell^2*(q+1) .* x.^(2*ell-2) .* A.^(-q-2);

% ----- e''(u)
depp(I) = exp(Se) .* (Se_p.^2) + (exp(Se) - 1) .* Se_pp;

% Saturé : dérivée nulle
depp(~I) = 0;

depp = depp(:);
end
