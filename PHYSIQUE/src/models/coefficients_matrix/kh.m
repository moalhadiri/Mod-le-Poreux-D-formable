function K = kh(u)
% K(h) - Conductivité hydraulique selon Van Genuchten–Mualem
% Entrée :
%   u : potentiel matriciel h (m ou cm)  — négatif en non saturé
% Sortie :
%   K : conductivité hydraulique correspondante
%
% Formule :
%   Se(h) = (1 + (alpha * |h|)^n)^(-m)          si h < 0
%   K = Ks * Se^L * (1 - (1 - Se^(1/m))^m )^2   si h < 0
%   K = Ks                                      si h >= 0
%
% -------------------------------------------------------------------------

% Chargement des paramètres du modèle
%[~,~,~,~,~,~,~,~,~,~,theta_r,theta_s,alpha,n,m,Ks] = parametre();
 [Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM, Theta_MS,e_MS, ...
           alpha,Kr,K0,theta_r,theta_s, n,m,Ks] = parametre();
% Exposant de Mualem
L = 0.5;

% Force la variable d'entrée en vecteur colonne
u = u(:);

% === Calcul de la saturation effective Se(h) ===
Se = ones(size(u));                  % valeur par défaut : saturé
I = (u < 0);                         % indices non saturés
Se(I) = (1 + (alpha * abs(u(I))).^n).^(-m);

% Bornage physique
Se = max(0, min(1, Se));

% Petite marge numérique
epsSe = 1e-8;
Se = min(max(Se, epsSe), 1 - epsSe);

% === Calcul de K(h) selon Van Genuchten–Mualem ===
K_unsat = Ks .* (Se).^L .* (1 - (1 - Se.^(1/m)).^m ).^2;

% === Gestion du cas h >= 0 (saturation complète) ===
K = K_unsat;
K(u >= 0) = Ks;

% Force le résultat en vecteur colonne
K = K(:);

end

