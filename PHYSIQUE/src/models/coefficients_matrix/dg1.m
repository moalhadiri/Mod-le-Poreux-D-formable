function g = dg1(u)
% Entrée:
%   u - Vecteur en entrée
%
% Sortie:
%   g - Vecteur colonne contenant la dérivée dg1/du

% Valeur de régularisation pour éviter la division par zéro
eps_num = 1e-8;

% u est un vecteur colonne
u = u(:);

% Calcul de la dérivée selon la formule:
% dg1/du = (wep(u).*(c(u)+eps_num) - cp(u).*we(u))./(c(u)+eps_num).^2
g = wep(u);

% Garantir que le résultat est un vecteur colonne
g = g(:);
