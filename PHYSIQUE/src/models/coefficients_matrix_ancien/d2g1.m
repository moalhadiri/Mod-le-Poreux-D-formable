function g = d2g1(u)
% D2G1 Calcule la dérivée seconde de la fonction g1(u)
% Description:
%   Cette fonction calcule la dérivée seconde de g1(u) = we(u)/(c(u) + eps)
% Entrée:
%   u - Vecteur en entrée
% Sortie:
%   g - Vecteur colonne contenant la dérivée seconde d²g1/du²


% Assurer que u est un vecteur colonne

% Calcul de la dérivée seconde
% % Formule simplifiée pour d²g1/du²
% D2g/du2 = numerator ./ (c(u)+eps_num).^3

% Garantir que le résultat est un vecteur colonne
g = wepp(u); 
