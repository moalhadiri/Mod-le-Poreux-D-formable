function cp_val = cp(psi)
% cp(psi) - dérivée de la capacité capillaire
% cp = d/dpsi ( c(psi) ) = theta''(psi)
%
% Entrées :
%   psi : potentiel matriciel
%   ell : exposant (>1)
%
% Sortie :
%   cp_val : dérivée de la capacité capillaire
% -------------------------------------------------------------------------
ell=3;
psi = psi(:);

% Initialisation
cp_val = zeros(size(psi));

% Cas non saturé
I = (psi < 0);

num = ell .* psi(I).^(ell-2) .* ( ...
        (ell-1).*(1 - psi(I).^ell) + 2*ell.*psi(I).^ell );

den = (1 - psi(I).^ell).^3;

cp_val(I) = num ./ den;

% Cas saturé : régularisation
cp_val(psi >= 0) = 1e-8;

cp_val = cp_val(:);
end
