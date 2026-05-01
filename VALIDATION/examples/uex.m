function [ue,duex_val,duey_val,duez_val]=uex(x,y,z,t,test_cond)
% test_id:
%   1 = x(1-x)^2 z(1-z)^2 (2y-6y^2+4y^3)
%   2 = x y z (x-1)(y-1)(z-1)
%   3 = ur+(us-ur)*S(r^2)*P(x,y,z) (champ lissé, pas de zones constantes)
if nargin<5, test_cond=1; end


switch test_cond
    case 1
        
        k = 3;      % mode in x
        l = 2;      % mode in y  
        m = 1;      % mode in z
        beta = 1/36;
        
        Cklm = (1 - cos(l*pi/2)) * (1 - cos(m*pi/2)) / (k*l*m);
        lambda = pi^2 * (k^2 + l^2 + m^2) * beta;
        
        time_factor = exp(-lambda * t);
        
        ue = -Cklm .* time_factor .* sin(k*pi*x) .* sin(l*pi*y) .* sin(m*pi*z);
        duex_val = -Cklm .* time_factor .* (k*pi*cos(k*pi*x)) .* sin(l*pi*y) .* sin(m*pi*z);
        duey_val = -Cklm .* time_factor .* sin(k*pi*x) .* (l*pi*cos(l*pi*y)) .* sin(m*pi*z);
        duez_val = -Cklm .* time_factor .* sin(k*pi*x) .* sin(l*pi*y) .* (m*pi*cos(m*pi*z));

    case 2
        ue=exp(-t).*x.*y.*z.*(x-1).*(y-1).*(z-1);
        duex_val=exp(-t).*(2*x-1).*y.*(y-1).*z.*(z-1);
        duey_val=exp(-t).*x.*(x-1).*(2*y-1).*z.*(z-1);
        duez_val=exp(-t).*x.*(x-1).*y.*(y-1).*(2*z-1);
    case 3
        % Case 3: prescribed localized smooth field (masked bubble)
        % No exact derivatives used here -> returned as zeros.
        ur = -5;

        R0sq = 0.1;  % Radius squared controlling the support size
        r2 = (x-0.5).^2+(y-0.5).^2+(z-0.5).^2;

        denom = 1-exp(-R0sq);
        S = (1-exp(r2-R0sq))./denom;

        % Geometric mask (localized “door-like” region)
        mask = ((abs(y-0.5) > 0.09) | (z > 0.5)) & (r2 <= R0sq);
        S = S.*mask;

        u_ext    = ur;
        u_centre = -1;
        ue = ur+(u_centre-u_ext)*S;

        % Derivatives not defined/used for this prescribed field
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
