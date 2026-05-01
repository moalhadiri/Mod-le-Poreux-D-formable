function dc = cp(psi)
% dc(psi) - Dérivée de c(psi) selon van Genuchten
% dc/d psi = -alpha²*m*n*(θs-θr)*|alpha*psi|^(n-2)*[(n-1)-(nm+1)|alpha*psi|^n ]/[1+|alpha*psi|^n]^(m+2)
% pour psi < 0, sinon 0
% --- Paramètres 
[~,~,~,~,~,~,~,~, alpha,~,~,theta_r,theta_s, n,m,~]=parametre();
% vecteur colonne
psi = psi(:);

% Initialisation
dc = zeros(size(psi));

% Cas psi < 0
mask=(psi< 0);
psineg=psi(mask);
u=abs(alpha.*psineg);
dc(mask)=-alpha.^2.*m.*n.*(theta_s-theta_r)...
    .* u.^(n-2).*((n - 1)-(n*m + 1).*u.^n)./(1+u.^n).^(m + 2);
