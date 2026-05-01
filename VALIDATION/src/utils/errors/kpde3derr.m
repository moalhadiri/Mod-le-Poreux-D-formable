function [eL2,eH1] = kpde3derr(p,t,u,time)
%KPDE3DERR  Compute L2 and H1 errors for a 3D P1 FEM solution on tetrahedra.
%
% This function compares the numerical FEM solution u with the exact
% solution provided by uex at time "time", using an 11-point Gauss
% quadrature rule on each tetrahedral element.
%
% INPUT:
%   p    : Node coordinates (np by 3)
%   t    : Tetrahedral connectivity (nt by 4)
%   u    : Numerical solution at mesh nodes (np by 1)
%   time : Evaluation time
%
% OUTPUT:
%   eL2  : L2 error norm
%   eH1  : H1 error norm (includes both solution error and gradient error)
%
% NOTES:
% - Gradients of a P1 FEM solution are constant per tetrahedron.
% - Exact solution and derivatives are evaluated at Gauss points via uex.
% - Element volumes and shape-function gradients are given by kpde3dgphi.
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
    it1 = t(:,1); it2 = t(:,2); it3 = t(:,3); it4 = t(:,4);

    % Nodal values per element
    ut1 = u(it1); ut2 = u(it2); ut3 = u(it3); ut4 = u(it4);

    % -------------------------------------------------------------
    % Element volumes and constant P1 shape-function gradients
    % -------------------------------------------------------------
    [vol,g1,g2,g3,g4] = kpde3dgphi(p,t);

    % FEM solution gradients (constant per tetrahedron)
    dxuh = ut1.*g1(:,1) + ut2.*g2(:,1) + ut3.*g3(:,1) + ut4.*g4(:,1);
    dyuh = ut1.*g1(:,2) + ut2.*g2(:,2) + ut3.*g3(:,2) + ut4.*g4(:,2);
    dzuh = ut1.*g1(:,3) + ut2.*g2(:,3) + ut3.*g3(:,3) + ut4.*g4(:,3);

    % -------------------------------------------------------------
    % Gauss loop: accumulate element-wise contributions
    % -------------------------------------------------------------
    errl = 0; 
    errh = 0;

    for i = 1:nt

        % Element nodes and coordinates
        it = t(i,1:4); 
        ut = u(it); 
        xt = p(it,1); 
        yt = p(it,2); 
        zt = p(it,3);

        % FEM solution evaluated at Gauss points
        uh = (1-xg-yg-zg).*ut(1) + xg.*ut(2) + yg.*ut(3) + zg.*ut(4);

        % Map Gauss points from reference tetrahedron to physical tetrahedron
        x  = (1-xg-yg-zg).*xt(1) + xg.*xt(2) + yg.*xt(3) + zg.*xt(4);
        y  = (1-xg-yg-zg).*yt(1) + xg.*yt(2) + yg.*yt(3) + zg.*yt(4);
        z  = (1-xg-yg-zg).*zt(1) + xg.*zt(2) + yg.*zt(3) + zg.*zt(4);

        % Exact solution and exact derivatives at Gauss points
        [ue,dxue,dyue,dzue] = uex(x, y, z, time);

        % Element contribution to L2 error (integrated squared solution error)
        ee1 = vol(i)*wg.*(uh-ue).^2;

        % Element contribution to gradient part (integrated squared gradient error)
        ee2 = vol(i)*wg.*(dxuh(i)-dxue).^2 + ...
              vol(i)*wg.*(dyuh(i)-dyue).^2 + ...
              vol(i)*wg.*(dzuh(i)-dzue).^2;

        % Accumulate global errors
        errl = errl + sum(ee1);
        errh = errh + (sum(ee1) + sum(ee2));

    end

    % Final norms
    eL2 = sqrt(errl);
    eH1 = sqrt(errh);