function Kpp = khpp(u)
% khpp(u) - dérivée seconde dK/du pour la loi Van Genuchten–Mualem
% Ici u = h (potentiel/charge matricielle)
%
% Modèle :
%   Se(h) = (1 + (alpha*|h|)^n)^(-m)   pour h<0 ;   Se = 1 pour h>=0
%   K(Se) = Ks * Se^L * ( 1 - (1 - Se^(1/m))^m )^2,  L=1/2
%   K''(h) = Ks * [ Se''(h)*A(Se) + (Se'(h))^2 * A_Theta(Se) ]
%
% Paramètres (adapter à ta fonction parametre())
[Theta_SL,e_SL,Theta_AE,e_AE,Theta_LM,e_LM, Theta_MS,e_MS, ...
           alpha,Kr,K0,theta_r,theta_s, n,m,Ks] = parametre();

% Exposant de Mualem
L = 0.5;

% vecteur colonne
u = u(:);

% ---------- Saturation effective ----------
Se = ones(size(u));       % saturé par défaut (h>=0)
I  = (u < 0);             % non saturé

if any(I)
    absu = abs(u(I));
    X    = (alpha*absu).^n;            % (alpha|h|)^n
    Se(I)= (1 + X).^(-m);              % Se(h)
end

% Clamp physique + marge numérique
epsSe = 1e-8;
Se = max(0,min(1,Se));
Se = min(max(Se,epsSe),1-epsSe);

% ---------- dSe/dh ----------
dSe_du = zeros(size(u));
if any(I)
    absu = abs(u(I));
    X    = (alpha*absu).^n;
    % dSe/dh = m n alpha^n |h|^(n-1) (1 + (alpha|h|)^n)^(-m-1), h<0
    dSe_du(I) = m.*n.*(alpha.^n) .* (absu.^(n-1)) .* (1 + X).^(-m-1);
end
% h>=0 -> dSe/dh = 0

% ---------- d2Se/dh2 ----------
d2Se_du2 = zeros(size(u));
if any(I)
    absu = abs(u(I));
    X    = (alpha*absu).^n;
    C    = m.*n.*(alpha.^n);
    % d2Se/dh2 = -C*(n-1)|h|^(n-2)(1+X)^(-m-1) + C*(m+1)*n*alpha^n |h|^(2n-2)(1+X)^(-m-2)
    term1 = -(C).*(n-1).* (absu.^(n-2)) .* (1 + X).^(-m-1);
    term2 =  (C).*(m+1).*n.*(alpha.^n) .* (absu.^(2*n-2)) .* (1 + X).^(-m-2);
    d2Se_du2(I) = term1 + term2;
end
% h>=0 -> d2Se/dh2 = 0

% ---------- Notations auxiliaires ----------
Theta = Se;
T     = Theta.^(1/m);         % Se^{1/m}
omT   = 1 - T;                % 1 - Se^{1/m}
S     = 1 - omT.^m;           % s(Se) = 1 - (1 - Se^{1/m})^m
B     = omT.^(m-1);           % (1 - Se^{1/m})^{m-1}

% ---------- A(Theta) et A_Theta(Theta) pour L=1/2 ----------
A = 0.5.*Theta.^(-1/2).*(S.^2) ...
  + 2.*S.*B.*Theta.^(1/m - 1/2);

omT_pow_m_2 = omT.^(m-2);
A_Theta = (-0.25).*Theta.^(-3/2).*(S.^2) ...
        + (2/m).*S.*B.*Theta.^(1/m - 3/2) ...
        + 2.*(B.^2).*Theta.^(2/m - 3/2) ...
        - 2.*((m-1)/m).*S.*omT_pow_m_2.*Theta.^(2/m - 3/2);

% ---------- Dérivée seconde de K ----------
Kpp = Ks .* ( d2Se_du2 .* A + (dSe_du.^2) .* A_Theta );

% vecteur colonne
Kpp = Kpp(:);
end


% function Kpp=khpp(u)
% % ellp(u) - dérivée seconde dK/du (loi Van Genuchten)
% % K(Se) = Ks * Se^L * ( 1 - (1 - Se^(1/m))^m )^2,  Se in [0,1]
% % Ici u = theta, Se = (u - theta_r)/(theta_s - theta_r)
% % Formule: kappa''(u) = Ks * [Theta''(u)*A(Theta) + (Theta'(u))^2 * A_Theta(Theta)]
% % Paramètres
% [~,~,~,~,~,~, ~,~, ~,~,~,theta_r,theta_s, ~,m,Ks] = parametre();
% % vecteur colonne
% u = u(:);
% % Saturation effective
% Se_raw = (u-theta_r)./ (theta_s-theta_r);
% % Clamp physique Se in [0,1] avec marge numérique
% epsSe = 1e-8;
% Se = max(0,min(1,Se_raw));
% Se = min(max(Se,epsSe),1-epsSe);
% % Masque "actif" : là où Se_raw est dans (0,1)
% active = (Se_raw>0)&(Se_raw<1);
% % Dérivées de Theta = Se (fonction affine)
% dSe_du=zeros(size(u));
% dSe_du(active)=1 /(theta_s-theta_r);
% d2Se_du2=zeros(size(u)); % Nul pour fonction affine
% % Notations : T=Theta^(1/m), S=1-(1-T)^m, B=(1-T)^(m-1)
% Theta=Se;
% T=Theta.^(1/m);
% omT=1-T;
% S = 1 - omT.^m;
% B = omT.^(m-1);
% % A(Theta)
% A = 0.5.*Theta.^(-1/2).*(S.^2) ...
%   + 2.*S.*B.*Theta.^(1/m-1/2);
% % A_Theta (forme simplifiée)
% omT_pow_m_2=omT.^(m-2);
% A_Theta=(-0.25).*Theta.^(-3/2).*(S.^2) ...
%         + (2/m).*S.* B.*Theta.^(1/m-3/2) ...
%         + 2.*(B.^2).*Theta.^(2/m-3/2) ...
%         - 2*((m-1)/m).*S.*omT_pow_m_2.*Theta.^(2/m-3/2);
% % Dérivée seconde
% Kpp = Ks.*(d2Se_du2.*A+(dSe_du.^2).*A_Theta);
% % vecteur colonne
% Kpp = Kpp(:);