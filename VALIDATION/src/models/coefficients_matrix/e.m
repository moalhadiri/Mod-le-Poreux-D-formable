function eb = e(u, ell)
% e(u) - Fonction de retrait (indice des vides) basée sur Se(psi)
% Entrée :
%   u   : potentiel matriciel psi (négatif en non saturé)
%   ell : paramètre (>1)
% Sortie :
%   eb  : indice des vides
%
% Nouvelle saturation effective :
%   q = 1 - 1/ell
%   Se(u) = 1 / (1 + (-u)^ell)^q    pour u < 0
%   Se = 1                         pour u >= 0
%
% Loi de retrait (inchangée) :
%   e(Se) = exp(Se) - Se
% -------------------------------------------------------------------------

u = u(:);

q = 1 - 1/ell;

% Calcul de Se(u)
Se = ones(size(u));
I  = (u < 0);
Se(I) = 1 ./ (1 + (-u(I)).^ell).^q;

% Bornage physique
Se = max(0, min(1, Se));

% Calcul de e(Se)
eb = exp(Se) - Se;

eb = eb(:);
end
