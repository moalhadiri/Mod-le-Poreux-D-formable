function D = kpde3div(p,t,nu1,nu2,nu3)
% KPDE3DIV  Assemble the 3D advection (convection) matrix for P1 FEM.
%
% This routine builds the sparse matrix D with element contributions:
%   D_ij = integral_T ( (nu dot grad(phi_j)) * phi_i ) dx
% where nu is the velocity field and phi_i are P1 basis functions on
% tetrahedral elements.
%
% INPUTS
%   p    : np x 3 array,node coordinates
%   t    : nt x 4 array,tetrahedral connectivity (vertex indices)
%   nu1  : x-component of velocity (scalar,np x 1,or nt x 1)
%   nu2  : y-component of velocity (scalar,np x 1,or nt x 1)
%   nu3  : z-component of velocity (scalar,np x 1,or nt x 1)
%
% OUTPUT
%   D    : sparse np x np advection matrix
%
% NOTES
%   - If nu is given at nodes,it is converted to elementwise constants by
%     averaging the four nodal values in each tetrahedron.
%   - P1 basis gradients are constant per tetrahedron and are obtained from
%     kpde3dgphi.
%   - The P1 mass matrix constants on tetrahedra are:
%       integral_T phi_i * phi_j dx = V/20 for i ~= j,and V/10 for i == j.
%
% -------------------------------------------------------------------------

np = size(p,1); nt = size(t,1);

% 1) Elementwise velocity coefficients (constant per tetrahedron)
if size(nu1,1) == 1 || size(nu1,1) == nt
    c1 = nu1;
else
    c1 = (nu1(t(:,1))+nu1(t(:,2))+nu1(t(:,3))+nu1(t(:,4)))/4;
end

if size(nu2,1) == 1 || size(nu2,1) == nt
    c2 = nu2;
else
    c2 = (nu2(t(:,1))+nu2(t(:,2))+nu2(t(:,3))+nu2(t(:,4)))/4;
end

if size(nu3,1) == 1 || size(nu3,1) == nt
    c3 = nu3;
else
    c3 = (nu3(t(:,1))+nu3(t(:,2))+nu3(t(:,3))+nu3(t(:,4)))/4;
end

% 2) Tetra volumes and P1 basis function gradients
[vol,g1,g2,g3,g4] = kpde3dgphi(p,t);
g = {g1,g2,g3,g4};

% 3) Off-diagonal mass weight (V/20)
coef = vol/20;

% 4) Assembly
D = sparse(np,np);
for i = 1:4
    for j = 1:4

        % nu dot grad(phi_j) (constant within each tetrahedron)
        vdotgrad = c1.*g{j}(:,1)+c2.*g{j}(:,2)+c3.*g{j}(:,3);

        % Use P1 mass matrix constants: V/10 on diagonal,V/20 off-diagonal
        if i == j
            weight = vol/10;
        else
            weight = coef;
        end

        D = D+sparse(t(:,i),t(:,j),weight.*vdotgrad,np,np);
    end
end