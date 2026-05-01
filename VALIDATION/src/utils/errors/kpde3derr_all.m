function [eL2, eH1, eL1, eLinf] = kpde3derr_all(p,t,u,time,test_cond)
%KPDE3DERR_ALL  Compute L2, H1, L1 and Linf errors for a 3D P1 FEM solution.
%
% This routine evaluates classical error norms between the numerical FEM
% solution u and the exact solution provided by uex, using high-order
% Gauss quadrature on tetrahedral elements.
%
% INPUT:
%   p         : Node coordinates (np by 3)
%   t         : Tetrahedral connectivity (nt by 4)
%   u         : Numerical solution at nodes
%   time      : Evaluation time
%   test_cond : Identifier for the exact solution case
%
% OUTPUT:
%   eL2   : L2 error norm
%   eH1   : H1 error norm (solution error plus gradient error)
%   eL1   : L1 error norm
%   eLinf : Linf error norm evaluated at Gauss points
%
% NOTES:
% - Errors are evaluated using an 11-point Gauss quadrature rule on each
%   tetrahedron.
% - Gradients of the P1 FEM solution are constant per element.
% - Exact solution and derivatives are provided by uex.
% - Shape function gradients are obtained from kpde3dgphi.
%
% -------------------------------------------------------------------------

    % -------------------------------------------------------------
    % 11-point Gauss quadrature rule in reference tetrahedron
    % -------------------------------------------------------------
    a = (1+sqrt(5/14))/4; 
    b = (1-sqrt(5/14));

    xg = [1/4; 11/14; 1/14; 1/14; 1/14; a; a; a; b; b; b];
    yg = [1/4; 1/14; 11/14; 1/14; 1/14; a; b; b; a; a; b];
    zg = [1/4; 1/14; 1/14; 11/14; 1/14; b; a; b; a; b; a];

    wg = [-74/5625; 343/45000; 343/45000; 343/45000; 343/45000; ...
           56/2250; 56/2250; 56/2250; 56/2250; 56/2250; 56/2250];

    nt = size(t,1);

    % Node indices of tetrahedra
    it1=t(:,1); it2=t(:,2); it3=t(:,3); it4=t(:,4);

    % Nodal values per element
    ut1=u(it1); ut2=u(it2); ut3=u(it3); ut4=u(it4);

    % -------------------------------------------------------------
    % Element volumes and constant P1 shape-function gradients
    % -------------------------------------------------------------
    [vol,g1,g2,g3,g4]=kpde3dgphi(p,t);

    % FEM solution gradients (constant per tetrahedron)
    dxuh=ut1.*g1(:,1)+ut2.*g2(:,1)+ut3.*g3(:,1)+ ut4.*g4(:,1);
    dyuh=ut1.*g1(:,2)+ut2.*g2(:,2)+ut3.*g3(:,2)+ut4.*g4(:,2);
    dzuh=ut1.*g1(:,3)+ ut2.*g2(:,3)+ut3.*g3(:,3)+ut4.*g4(:,3);

    % Initialize error accumulators
    errL2=0; 
    errH1=0; 
    errL1=0; 
    Linf=0;

    % -------------------------------------------------------------
    % Loop over tetrahedra
    % -------------------------------------------------------------
    for i=1:nt

        % Element nodes and coordinates
        it=t(i,1:4);  
        xt=p(it,1); yt=p(it,2); zt=p(it,3);
        ut=u(it);

        % P1 shape functions at Gauss points
        N1=(1-xg-yg-zg); 
        N2=xg; 
        N3=yg; 
        N4=zg;

        % FEM solution at Gauss points
        uh = N1.*ut(1) + N2.*ut(2) + N3.*ut(3) + N4.*ut(4);

        % Physical coordinates of Gauss points
        x  = N1.*xt(1) + N2.*xt(2) + N3.*xt(3) + N4.*xt(4);
        y  = N1.*yt(1) + N2.*yt(2) + N3.*yt(3) + N4.*yt(4);
        z  = N1.*zt(1) + N2.*zt(2) + N3.*zt(3) + N4.*zt(4);

        % Exact solution and gradients at Gauss points
        [ue, dxue, dyue, dzue]=uex(x,y,z,time,test_cond);

        % Solution error
        e=uh-ue;

        % Gradient error (FEM gradient minus exact gradient)
        gx=dxuh(i)-dxue;
        gy=dyuh(i)-dyue;
        gz=dzuh(i)-dzue;

        % L2 and H1 contributions
        errL2=errL2+vol(i)*sum(wg.* (e.^2));
        errH1=errH1+vol(i)*sum(wg.*(e.^2+gx.^2+gy.^2+gz.^2));

        % L1 contribution
        errL1=errL1+vol(i)*sum(wg.*abs(e));

        % Linf evaluated at Gauss points
        Linf=max(Linf,max(abs(e)));

    end

    % Final norms
    eL2=sqrt(errL2);
    eH1=sqrt(errH1);
    eL1=errL1;
    eLinf=Linf;
