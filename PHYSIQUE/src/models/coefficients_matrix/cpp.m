function dc2 = cpp(psi)
% Pour psi < 0 :
% c''(psi) = alpha^3*m*n*(θs-θr)*|alpha*psi|^(n-3)/(1+|alpha*psi|^n)^(m+3)*
%            [ (n-2)((n-1)-(nm+1)|alpha*psi|^n)(1+|alpha*psi|^n)
%              + n*|alpha*psi|^n*((nm+1)(nm+2)|alpha*psi|^n-(2n-1)) ]
%
% Pour psi > 0 : c''(psi) = 0


% --- Paramètres 
[~,~,~,~,~,~,~,~, alpha,~,~,theta_r,theta_s, n,m,~] = parametre();
% vecteur colonne
psi = psi(:);

% Initialisation
dc2 = zeros(size(psi));

% Cas psi < 0
mask = (psi < 0);
psineg = psi(mask);

% variable u = |alpha*psi| (= -alpha*psi pour ψ<0 et α>0)
u = abs(alpha.*psineg);

% Plancher numérique pour éviter 0^(n-3) si psi=0 est passé
u = max(u,1e-20);

% Coefficient global
A=alpha.^3.*m.*n.*(theta_s-theta_r);

% Termes du crochet
term1 = (n-2).* ((n-1)-(n*m+1).*u.^n).*(1+u.^n);
term2 = n.*u.^n.*((n*m+1).*(n*m+2).*u.^n-(2*n - 1));

% Seconde dérivée
dc2(mask) = A.*u.^(n-3).*(term1+term2)./(1+u.^n).^(m+3);

% vecteur colonne
dc2 = dc2(:);
