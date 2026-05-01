function g = d2g2(u)
% Entree :
%       u  - vecteur ou scalaire des points où évaluer la dérivée seconde
% Sortie :
%       g  - valeur(s) de g''
g = d2g1(u).*gz(u) + 2*dg1(u).*dgz(u) + g1(u).*d2gz(u);