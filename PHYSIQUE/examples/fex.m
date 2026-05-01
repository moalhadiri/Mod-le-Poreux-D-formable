function fval  = fex(x,y,z,t,test_id)
    if nargin < 5, test_id = 1; end

    switch test_id
        case 1
            % ----- TEST 1 -----
        u = -(1-t)*x.*(1-x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        dut= x.*(1-x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        duex_val = -(1-t).* (1-2.*x).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        duey_val = -(1-t).* x.*(1-x).*2.*y.*(1-y).*(1-2.*y).*z.^2.*(1-z).^2;
        duez_val = -(1-t).* x.*(1-x).*y.^2.*(1-y).^2.*2.*z.*(1-z).*(1-2.*z);

        dfxx    = -(1-t) .* (-2).*y.^2.*(1-y).^2.*z.^2.*(1-z).^2;
        d2y     = 2.*(1-y).^2 - 8.*y.*(1-y) + 2.*y.^2;
        dfyy    = -(1-t) .* x.*(1-x).*d2y.*z.^2.*(1-z).^2;
        d2z     = 2.*(1-z).^2 - 8.*z.*(1-z) + 2.*z.^2;
        dfzz    = -(1-t) .* x.*(1-x).*y.^2.*(1-y).^2.*d2z;

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
        u =(1-t)*x.*y.*z.*(x-1.0).*(y-1.0).*(z-1.0);
        dut=-1*x.*y.*z.*(x-1.0).*(y-1.0).*(z-1.0);
        duex_val =(1-t)*(2*x-1.0).*y.*(y-1.0).*z.*(z-1.0);
        duey_val =(1-t)*x.*(x-1.0).*(2*y-1.0).*z.*(z-1.0);
        duez_val =(1-t)*x.* (x-1.0) .* y.* (y-1.0).* (2*z-1.0);

        dfxx=(1-t)*2.*y.*z.*(y-1).*(z-1);
        dfyy=(1-t)*2.*x.*z.*(x-1).*(z-1);
        dfzz=(1-t)*2.*x.*y.*(x-1).*(y-1);

        % format colonne
        u = u(:); dut=dut(:); duex_val = duex_val(:); duey_val = duey_val(:); duez_val = duez_val(:);
        dfxx=dfxx(:); dfyy=dfyy(:); dfzz=dfzz(:);

        % second membre
        fxyval =g1(u).*(kh(u).*(dfxx+dfyy)+khp(u).*(duex_val.^2+duey_val.^2));
        fz1val = g2(u).*(ell(u).*dfzz+ellp(u).*(duez_val.^2));
        fz2val = g2(u).*ellp(u).* duez_val;
      %  fval =dut-(fxyval + fz1val + fz2val);
        fval =(c(u).*dut-(fxyval + fz1val + fz2val));

        case 3
            % Cas physique simple : PAS DE SOURCE VOLUMIQUE
            % => pure relaxation / drainage interne
           % fval =0.01.*t;%  0.001 * ones(size(x,1),1);
              
        fval  = 0.0;

        otherwise
            error('fex: test_id inconnu (%d). Utilise 1, 2 ou 3.', test_id);
    end
end

