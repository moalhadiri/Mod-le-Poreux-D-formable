function g = dgz(u,ell)
% dgz  Calcule la dérivée de la gravitation de l'écoulement
% Entree :
%       u  - vecteur ou scalaire des points où évaluer la dérivée
% Sortie :
%       g  - valeur(s) de la dérivée g'(u)

% Remarque :
%       er   - coefficient constant (rapport d'entraînement)
%       eps1 - petit terme de régularisation pour éviter la division par zéro

eps1 = 1e-8;
   g = -((1).*wep(u,ell))./(we(u,ell)+eps1).^2;

