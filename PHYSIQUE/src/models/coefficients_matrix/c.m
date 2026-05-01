function c_val = c(psi)
% c(psi) - Capacité spécifique en eau (van Genuchten)
% C(psi) = (theta_s - theta_r) * m * n * alpha * (-alpha*psi)^(n-1) / [1 + (-alpha*psi)^n]^(m+1)
% pour psi <= 0 ; sinon C(psi) = 0
% On impose un plancher numérique à 1e-8 pour éviter les valeurs trop petites.

[~,~,~,~,~,~, ~,~, alpha,~,~, theta_r, theta_s, n, m, ~] = parametre();

% vecteur colonne
psi = psi(:);

% Initialisation
c_val = zeros(size(psi));

% Masque psi <= 0
mask = (psi <= 0);
psineg = psi(mask);

% x = (-alpha*psi) >= 0 pour psi <= 0
x = max(0, -alpha .* psineg);

% Capacité spécifique (formule de Van Genuchten)
num = (theta_s - theta_r).*m.*n.*alpha.*x.^(n-1);
den = (1 + x.^n).^(m+1);
c_val(mask) = num ./ den;

% ⚙️ Planche minimale pour stabilité numérique
c_val(c_val < 1e-8) = 1e-8;

end

