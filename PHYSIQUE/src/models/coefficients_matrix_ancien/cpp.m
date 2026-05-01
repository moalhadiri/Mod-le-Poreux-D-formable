function cpp_val = cpp(psi, ell)
% cpp(psi) - dérivée seconde de la capacité capillaire
% c(psi)   = ell*psi^(ell-1) / (1 - psi^ell)^2
% cpp(psi) = d^2/dpsi^2 c(psi)
%
% Entrées :
%   psi : potentiel matriciel (vecteur ou scalaire)
%   ell : exposant (>1)
%
% Sortie :
%   cpp_val : c''(psi)
% -------------------------------------------------------------------------

psi = psi(:);

% Initialisation
cpp_val = zeros(size(psi));

% Cas non saturé (psi < 0)
I = (psi < 0);
ps = psi(I);

den2 = (1 - ps.^ell).^2;
den3 = (1 - ps.^ell).^3;
den4 = (1 - ps.^ell).^4;

term1 = ell*(ell-1)*(ell-2) .* ps.^(ell-3)   ./ den2;
term2 = 2*ell^2*(3*ell-3)   .* ps.^(2*ell-3) ./ den3;   % = 6*ell^2*(ell-1)*ps^(2ell-3)/den3
term3 = 6*ell^3             .* ps.^(3*ell-3) ./ den4;

cpp_val(I) = term1 + term2 + term3;

% Cas saturé (psi >= 0) : régularisation (à adapter selon ton schéma)
cpp_val(psi >= 0) = 1e-8;

cpp_val = cpp_val(:);
end
