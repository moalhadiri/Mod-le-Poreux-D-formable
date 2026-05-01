function [ue,duex_val,duey_val,duez_val]=uex(x,y,z,t,test_cond)
% test_id:
%   1 = x(1-x)^2 z(1-z)^2 (2y-6y^2+4y^3)
%   2 = x y z (x-1)(y-1)(z-1)
%   3 = ur+(us-ur)*S(r^2)*P(x,y,z) (champ lissé, pas de zones constantes)
if nargin<5, test_cond=1; end


switch test_cond
    case 1
        
       % ue=-0.4*(z.*(1-z)).^2.*exp(-t./500);
        %ue=-z.*exp(-t./10);
       %  ue = -(1-t)*x.*(1-x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
       time_factor=(1-t);
        duex_val = -time_factor .* (1-2*x) .* y.^2.*(1-y).^2 .* z.^2.*(1-z).^2;
        duey_val = -time_factor .* x.*(1-x) .* 2.*y.*(1-y).*(1-2*y) .* z.^2.*(1-z).^2;
        duez_val = -time_factor .* x.*(1-x) .* y.^2.*(1-y).^2 .* 2.*z.*(1-z).*(1-2*z);
    case 2
        ue=(1-t)*x.*y.*z.*(x-1).*(y-1).*(z-1);
        duex_val=(1-t)*(2*x-1).*y.*(y-1).*z.*(z-1);
        duey_val=(1-t)*x.*(x-1).*(2*y-1).*z.*(z-1);
        duez_val=(1-t)*x.*(x-1).*y.*(y-1).*(2*z-1);
    case 3
        % psi_ext    = -10;        % fond du profil (sol assez sec)
        % psi_centre = -2;         % zone un peu plus humide au centre
        % r2   = (y-0.5).^2 + (z-0.5).^2;
        % R0sq = 0.1^2;
        % 
        % S = exp(-r2./R0sq);      % gaussienne 2D
        % ue = psi_ext + (psi_centre - psi_ext).*S; 
        ur =-5;

        R0sq = 0.1;  % Rayon plus grand
        r2 = (x-0.5).^2 + (y-0.5).^2 + (z-0.5).^2;

        denom = 1 - exp(-R0sq);
        S = (1 - exp(r2 - R0sq)) ./ denom;
        

        mask = ((abs(y - 0.5) > 0.09) | (z > 0.5)) & (r2 <= R0sq);
       % mask = (r2 <= R0sq);  % Simple sphère
        S = S .* mask;

        u_ext = ur;
        u_centre =-1;  % Commencer à -1 comme vous voulez
        ue = ur + (u_centre - u_ext) * S;

        % Pas de dérivées exactes connues → mises à zéro
        duex_val = zeros(size(ue));
        duey_val = zeros(size(ue));
        duez_val = zeros(size(ue));
    case 4
        cx = 0.4; cy = 0.4; cz = 0.4;

            % Paramètres physiques
            us = 1.26;          % valeur intérieure (centre)
            ur = 0.0000;        % valeur extérieure (fond)
            R2 = 0.09;          % rayon^2 => rayon = 0.3

            % Coordonnées relatives au centre
            dx = x - cx;  
            dy = y - cy;  
            dz = z - cz;

            % Distance radiale
            r2 = dx.^2 + dy.^2 + dz.^2;
            r = sqrt(r2);

            % ---- Condition spatiale (type "porte") inspirée de c0(x,y,z) ----
            % r <= 0.3 -> sphère de rayon 0.3 centrée en (0.5,0.5,0.5)
            % abs(x-0.5)>0.05 ou y>0.7 -> filtre géométrique
            mask = ((abs(x - cx) > 0.09) | (y > 0.5)) & (r <= 0.2);
          % mask = (r <= 0.4);

            % ---- Fonction bulle lisse ----
            denom = 1 - exp(-R2);
            inside = (r2 < R2) & mask;   % seulement à l'intérieur ET dans la zone "porte"

            % Valeur
            ue = ur .* ones(size(r2));
            ue(inside) = (us - ur) .* (0.5 - exp(r2(inside) - R2) ./ denom) + ur;

            % ---- Gradient (seulement à l'intérieur et dans la zone valide) ----
            duex_val = zeros(size(r2));
            duey_val = zeros(size(r2));
            duez_val = zeros(size(r2));

            coef = -(us - ur) .* exp(r2(inside) - R2) ./ denom;   % dU/dr2
            duex_val(inside) = 2 .* coef .* dx(inside);
            duey_val(inside) = 2 .* coef .* dy(inside);
            duez_val(inside) = 2 .* coef .* dz(inside);

    otherwise
        error('uex: test_id inconnu (%d). Utilise 1, 2, 3 ou 4.',test_cond);
end
ue=ue(:);
duex_val=duex_val(:);
duey_val=duey_val(:);
duez_val=duez_val(:);
end

