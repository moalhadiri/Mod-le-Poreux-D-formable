function R = kpde3drgd(p,t,nu1,nu2,nu3)
% KPDE3DRGD  Assemble the 3D stiffness (diffusion) matrix with anisotropic coefficients.
%
% This routine builds a sparse stiffness matrix for P1 tetrahedral finite
% elements with three (possibly different) diffusion coefficients along
% x-, y-, and z-directions. The element contribution corresponds to:
%   R_ij = integral_T [ nu1 * dphi_i/dx * dphi_j/dx
%                   +nu2 * dphi_i/dy * dphi_j/dy
%                   +nu3 * dphi_i/dz * dphi_j/dz ] dx
%
% INPUTS
%   p    : np x 3 array, node coordinates
%   t    : nt x 4 array, tetrahedral connectivity (vertex indices)
%   nu1  : diffusion coefficient in x-direction (scalar, np x 1, or nt x 1)
%   nu2  : diffusion coefficient in y-direction (scalar, np x 1, or nt x 1)
%   nu3  : diffusion coefficient in z-direction (scalar, np x 1, or nt x 1)
%
% OUTPUT
%   R    : sparse np x np stiffness matrix (symmetric positive semi-definite)
%
% NOTES
%   - If nu1/nu2/nu3 are given at nodes, they are converted to elementwise
%     constants by averaging the four nodal values in each tetrahedron.
%   - The gradients of P1 basis functions are constant within each element
%     and are obtained from kpde3dgphi.
%
% -------------------------------------------------------------------------

np = size(p,1);
nt = size(t,1);

% 1) Basic input size checks for nu1, nu2, nu3
[m1,m2] = size(nu1);
if (m2 > 1 || (m1 > 1 && m1 ~= nt && m1 ~= np))
    error('nu1 must be a column vector of length np or nt, or a scalar.')
end
[m1,m2] = size(nu2);
if (m2 > 1 || (m1 > 1 && m1 ~= nt && m1 ~= np))
    error('nu2 must be a column vector of length np or nt, or a scalar.')
end
[m1,m2] = size(nu3);
if (m2 > 1 || (m1 > 1 && m1 ~= nt && m1 ~= np))
    error('nu3 must be a column vector of length np or nt, or a scalar.')
end

% 2) Convert coefficients to elementwise constants (cell averages)
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

% 3) Element volumes and gradients of P1 basis functions
[vol,g1,g2,g3,g4] = kpde3dgphi(p,t);
g = {g1, g2, g3, g4};

% 4) Assemble lower-triangular contributions
R = sparse(np,np);
for i = 1:4
    for j = 1:i-1
        % Weighted dot product of gradients with directional coefficients
        grad_prod = c1.*g{i}(:,1).*g{j}(:,1)+...
                    c2.*g{i}(:,2).*g{j}(:,2)+...
                    c3.*g{i}(:,3).*g{j}(:,3);
        R = R+sparse(t(:,i), t(:,j), vol.*grad_prod, np, np);
    end
end

% 5) Enforce symmetry
R = R+R.';

% 6) Assemble diagonal contributions
for i = 1:4
    grad_sq = c1.*g{i}(:,1).^2+...
              c2.*g{i}(:,2).^2+...
              c3.*g{i}(:,3).^2;
    R = R+sparse(t(:,i), t(:,i), vol.*grad_sq, np, np);
end

end