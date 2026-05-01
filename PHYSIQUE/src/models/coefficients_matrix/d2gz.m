function g = d2gz(u)
% d2gz  Calcule la dérivée seconde de la gravitation de l'écoulement
% Entree :
%       u  - vecteur ou scalaire des points où évaluer la dérivée seconde
% Sortie :
%       g  - valeur(s) de la dérivée seconde :
%            g''(u) = -(1+er) * ( we(u).*epp(u) - 2*(ep(u)).^2 ) ./ (we(u).^3 + eps1)
%
% Remarque :
%       er   - coefficient constant (rapport d'entraînement)
%       eps1 - petit terme de régularisation pour éviter la division par zéro
er   = 0.32;
eps1 = 1e-8;
g = -(1+er).*(we(u).*wepp(u)-2*(wep(u)).^2 )./( we(u)+eps1).^3;
end
