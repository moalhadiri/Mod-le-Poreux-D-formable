 function g=ellp(u)
g=khp(u).*gz(u).*gz(u)  +2.*kh(u).*dgz(u).*gz(u);


























% % kh_prime(u) - dérivée dK/du de la loi Van Genuchten
% % K(theta) = Ks * Se^L * ( 1 - (1 - Se^(1/m))^m )^2,  Se in [0,1]
% % Ici u = theta, Se = (u - theta_r)/(theta_s - theta_r), bornée.
% % La dérivée dSe/du = 1/(theta_s - theta_r) sur (theta_r, theta_s),
% % et 0 en dehors (sinon = zeros). On ajoute une marge numérique epsSe.
% %
% % Paramètres (adapter si besoin)
% n        = 1.31;
% m        = 1 - 1/n;
% L        = 0.5;
% Ks       = 0.062;
% theta_s  = 0.410;
% theta_r  = 0.095;
% 
% % vecteur colonne
% u = u(:);
% 
% % Saturation effective brute (non bornée)
% Se_raw = (u - theta_r) ./ (theta_s - theta_r);
% 
% % Clamp physique Se in [0,1]
% Se = max(0, min(1, Se_raw));
% 
% % Marge numérique pour éviter puissances singulières en 0/1
% epsSe = 1e-8;  % <--- comme demandé
% Se = min(max(Se, epsSe), 1 - epsSe);
% 
% % Masque "actif" : là où Se_raw est STRICTEMENT dans (0,1),
% % on garde la vraie dérivée dSe/du ; sinon dérivée nulle.
% active = (Se_raw > 0) & (Se_raw < 1);
% 
% % dSe/du (élémentaire) avec la logique "sinon = zeros"
% dSe_du = zeros(size(u));
% dSe_du(active) = 1 ./ (theta_s - theta_r);
% 
% % r = (1 - Se^(1/m))^m, s = 1 - r
% Se_pow = Se.^(1/m);                    % Se^{1/m}
% one_minus_Se_pow = 1 - Se_pow;         % 1 - Se^{1/m}
% r = one_minus_Se_pow.^m;               % r(Se)
% s = 1 - r;                             % s(Se)
% 
% % Terme r^{(m-1)/m} (toujours bien défini grâce au clamp epsSe)
% r_pow = r.^((m-1)/m);
% 
% % Formule dérivée (chaîne + produit), factorisée par dSe/du
% % kappa'(u) = Ks * dSe/du * [ 0.5 * Se^{-1/2} * s^2
% %                           + 2 * s * r^{(m-1)/m} * Se^{1/m - 1/2} ]
% term1 = 0.5 .* Se.^(-1/2) .* (s.^2);
% term2 = 2   .* s .* r_pow .* (Se.^(1/m - 1/2));
% bracket = term1 + term2;
% 
% Kp = Ks .* dSe_du .* bracket;
% 
% % vecteur colonne
% Kp = Kp(:);
% end