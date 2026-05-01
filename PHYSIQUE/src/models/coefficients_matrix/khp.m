function Kp = khp(u)
% kh_prime(u) - dérivée dK/du (ici u = h, charge matricielle)
% Modèle Mualem–van Genuchten :
%   Se(h) = (1 + (alpha*|h|)^n)^(-m)  pour h<0 ;  Se=1 pour h>=0
%   K(h)  = Ks * Se^L * ( 1 - (1 - Se^(1/m))^m )^2
%   K'(h) = Ks * dSe/dh * [ L*Se^(L-1)*s^2 + 2*Se^L*s*(1 - Se^(1/m))^(m-1)*Se^(1/m - 1) ]
%           avec s = 1 - (1 - Se^(1/m))^m
%
% Paramètres (adapter à ta fonction parametre())
[Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM, Theta_MS,e_MS, ...
           alpha,Kr,K0,theta_r,theta_s, n,m,Ks] = parametre();

% Exposant de Mualem
L = 0.5;

% Vecteur colonne
u = u(:);

% === Saturation effective Se(h) ===
Se = ones(size(u));                 % par défaut saturé (h>=0)
I  = (u < 0);                       % zone non saturée

Se(I) = (1 + (alpha*abs(u(I))).^n).^(-m);

% Bornage + marge numérique
epsSe = 1e-8;
Se = min(max(Se, epsSe), 1 - epsSe);

% === dSe/dh ===
dSe_du = zeros(size(u));
% Pour h<0 : dSe/dh = m*n*alpha^n*|h|^(n-1) * (1 + (alpha|h|)^n)^(-m-1)
if any(I)
    absuI   = abs(u(I));
    X       = (alpha*absuI).^n;
    dSe_du(I) = m.*n.*(alpha.^n) .* (absuI.^(n-1)) .* (1 + X).^(-m-1);
end
% Pour h>=0 : dSe/dh = 0 (Se = 1 constant)

% === Termes auxiliaires ===
Se_pow         = Se.^(1./m);           % Se^{1/m}
one_minus_Sep  = 1 - Se_pow;           % 1 - Se^{1/m}
r              = one_minus_Sep.^m;     % r(Se) = (1 - Se^{1/m})^m
s              = 1 - r;                % s(Se)
r_pow_m1       = one_minus_Sep.^(m-1); % (1 - Se^{1/m})^{m-1}

% === dK/dh = Ks * dSe/dh * d/dSe[Se^L * s^2] ===
term1  = L .* Se.^(L-1) .* (s.^2);
term2  = 2 .* Se.^L .* s .* r_pow_m1 .* Se.^(1./m - 1);
bracket = term1 + term2;

Kp = Ks .* dSe_du .* bracket;

% Vecteur colonne
Kp = Kp(:);

end
% % 
% % 
% % function Kp = khp(u)
% % % kh_prime(u) - dérivée dK/du de la loi van Genuchten
% % % K(theta) = Ks * Se^L * ( 1 - (1 - Se^(1/m))^m )^2,  Se in [0,1]
% % % Ici u = theta, Se = (u - theta_r)/(theta_s - theta_r), bornée.
% % % La dérivée dSe/du = 1/(theta_s - theta_r) sur (theta_r, theta_s),
% % % et 0 en dehors (sinon = zeros). On ajoute une marge numérique epsSe.
% % % Paramètres 
% % [~,~,~,~,~,~, ~,~, ~,~,~,theta_r,theta_s, ~,m,Ks] = parametre();
% % % vecteur colonne
% % u = u(:);
% % % Saturation effective brute (non bornée)
% % Se_raw = (u - theta_r) ./ (theta_s - theta_r);
% % % Clamp physique Se in [0,1]
% % Se = max(0, min(1, Se_raw));
% % % Marge numérique pour éviter puissances singulières en 0/1
% % epsSe = 1e-8;  % 
% % Se = min(max(Se,epsSe),1-epsSe);
% % % Masque "actif" : là où Se_raw est STRICTEMENT dans (0,1),
% % % on garde la vraie dérivée dSe/du ; sinon dérivée nulle.
% % active = (Se_raw>0)&(Se_raw<1);
% % % dSe/du (élémentaire) avec la logique "sinon = zeros"
% % dSe_du = zeros(size(u));
% % dSe_du(active) = 1./(theta_s-theta_r);
% % % r = (1 - Se^(1/m))^m, s = 1 - r
% % Se_pow = Se.^(1/m);                    % Se^{1/m}
% % one_minus_Se_pow = 1 - Se_pow;         % 1 - Se^{1/m}
% % r = one_minus_Se_pow.^m;               % r(Se)
% % s = 1-r;                             % s(Se)
% % % Terme r^{(m-1)/m} (toujours bien défini grâce au clamp epsSe)
% % r_pow = r.^((m-1)/m);
% % % kappa'(u) = Ks * dSe/du * [ 0.5 * Se^{-1/2} * s^2 + 2 * s * r^{(m-1)/m} * Se^{1/m - 1/2} ]
% % term1 = 0.5.*Se.^(-1/2).*(s.^2);
% % term2 = 2.*s.*r_pow.* (Se.^(1/m - 1/2));
% % bracket = term1 + term2;
% % Kp = Ks.*dSe_du.*bracket;
% % % vecteur colonne
% % Kp = Kp(:);
