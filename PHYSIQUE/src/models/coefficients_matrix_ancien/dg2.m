function g = dg2(u)
% DG2  Calcule la dérivée de g2(u)
% Entree :
%       u  - vecteur ou scalaire des points où évaluer la dérivée
% Sortie :
%       g  - valeur(s) de la dérivée g'(u)
g = dg1(u).*gz(u) + g1(u).*dgz(u);


