function fval  =fex(x,y,z,t,test_id)
% f =ft -(fxy + fz1 + fz2)
% test_id: 1 = x(1-x)^2 z(1-z)^2 (2y - 6y^2 + 4y^3)
%          2 = x y z (x-1)(y-1)(z-1)
%          3 = second membre constant f = 1.0e-4 ou f=0.0

if nargin < 5, test_id = 1; end

switch test_id
    case 1
        % ----- TEST 1 -----
         k = 3;      % mode in x
        l = 2;      % mode in y  
        m = 1;      % mode in z
        beta = 1/36;
        
        Cklm = (1 - cos(l*pi/2)) * (1 - cos(m*pi/2)) / (k*l*m);
        lambda = pi^2 * (k^2 + l^2 + m^2) * beta;
        
        % Facteur temporel et sa dérivée temporelle
        A = exp(-lambda * t);
        dAdt = -lambda * A;  % dérivée de exp(-lambda*t)
        
        % Fonctions spatiales
        Sx = sin(k*pi*x);
        Sy = sin(l*pi*y);
        Sz = sin(m*pi*z);
        
        Cx = cos(k*pi*x);
        Cy = cos(l*pi*y);
        Cz = cos(m*pi*z);
        
        % Solution et ses dérivées
        u = -Cklm .* A .* Sx .* Sy .* Sz;
        
        % Dérivée temporelle
        dut = -Cklm .* dAdt .* Sx .* Sy .* Sz;
        
        % Dérivées spatiales premières
        duex_val = -Cklm .* A .* (k*pi*Cx) .* Sy .* Sz;
        duey_val = -Cklm .* A .* Sx .* (l*pi*Cy) .* Sz;
        duez_val = -Cklm .* A .* Sx .* Sy .* (m*pi*Cz);
        
        % Dérivées spatiales secondes (Laplacien)
        dfxx = -Cklm .* A .* (-k^2*pi^2*Sx) .* Sy .* Sz;  % dérivée seconde en x
        dfyy = -Cklm .* A .* Sx .* (-l^2*pi^2*Sy) .* Sz;  % dérivée seconde en y
        dfzz = -Cklm .* A .* Sx .* Sy .* (-m^2*pi^2*Sz);  % dérivée seconde en z
        % format colonne
        u = u(:); dut=dut(:); duex_val = duex_val(:); duey_val = duey_val(:);
        duez_val = duez_val(:); dfxx = dfxx(:); dfyy = dfyy(:); dfzz = dfzz(:);

        % second membre
        fxyval = g1(u).*(kh(u).*(dfxx+dfyy)+khp(u).*(duex_val.^2+duey_val.^2));
        fz1val = g2(u).*( ell(u).*dfzz+ ellp(u).*(duez_val.^2));
        fz2val = g2(u).*ellp(u).* duez_val;
        fval =(c(u).*dut-(fxyval + fz1val + fz2val));

    case 2
        % ----- TEST 2 -----
        u =exp(-t).*x.*y.*z.*(x-1.0).*(y-1.0).*(z-1.0);
        dut=-exp(-t).*x.*y.*z.*(x-1.0).*(y-1.0).*(z-1.0);
        duex_val =exp(-t).*(2*x-1.0).*y.*(y-1.0).*z.*(z-1.0);
        duey_val =exp(-t).*x.*(x-1.0).*(2*y-1.0).*z.*(z-1.0);
        duez_val =exp(-t).*x.* (x-1.0) .* y.* (y-1.0).* (2*z-1.0);

        dfxx=exp(-t).*2.*y.*z.*(y-1).*(z-1);
        dfyy=exp(-t).*2.*x.*z.*(x-1).*(z-1);
        dfzz=exp(-t).*2.*x.*y.*(x-1).*(y-1);

        % format colonne
        u = u(:); dut=dut(:); duex_val = duex_val(:); duey_val = duey_val(:); duez_val = duez_val(:);
        dfxx=dfxx(:); dfyy=dfyy(:); dfzz=dfzz(:);

        % second membre
        % second membre
        fxyval = g1(u).*(kh(u).*(dfxx+dfyy)+khp(u).*(duex_val.^2+duey_val.^2));
        fz1val = g2(u).*( ell(u).*dfzz+ ellp(u).*(duez_val.^2));
        fz2val = g2(u).*ellp(u).* duez_val;
        fval =(c(u).*dut-(fxyval + fz1val + fz2val));

    case 3
       %  % ----- TEST 3 -----
       %  % second membre constant (vectorisé)
       % % fval = 1.0e-4 + 0.*x + 0.*y + 0.*z + 0.*t;
         fval =0;% zeros(size(x));     % même taille que x
    
    otherwise
        error('fex: test_id inconnu (%d). Utilise 1, 2 ou 3.', test_id);
end
