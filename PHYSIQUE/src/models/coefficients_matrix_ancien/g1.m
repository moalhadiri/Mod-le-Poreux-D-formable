function g = g1(u)
% G1 Calcule la fonction g1(u) = we(psi)/(c(psi) + eps)
%
% Description:
%   Cette fonction calcule le rapport entre we(u) et c(u) avec une
%   régularisation pour éviter la division par zéro
%
% Entrée:
%   u - Vecteur (colonnes ou lignes) en entrée
%
% Sortie:
%   g - Vecteur colonne contenant g1(u) = we(u)./(c(u) + eps)

% Valeur de régularisation pour éviter la division par zéro
eps_num = 1e-8;

% Assurer que u est un vecteur colonne
u = u(:);

% Calcul de la fonction g1(u)
g = we(u);

% Garantir que le résultat est un vecteur colonne
g = g(:);
    
end

