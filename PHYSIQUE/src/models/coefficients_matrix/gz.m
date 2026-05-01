function g = gz(u)
% gz  Calcule la gravitation de l'écoulement
% Entree :
%       u  - vecteur ou scalaire des points où évaluer la fonction
% Sortie :
%       g  - valeur(s) de la gravitation de l'écoulement g(u))

er = 0.32;
g = (1+er)./we(u);

