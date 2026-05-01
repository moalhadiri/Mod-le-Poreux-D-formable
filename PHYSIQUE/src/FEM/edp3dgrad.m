function [dxu,dyu,dzu] = edp3dgrad(p,t,u)
% edp3dgrad  Compute the gradient of a P1 finite element solution (3D).
%
% This function evaluates the spatial gradient nabla u_h inside each tetrahedral
% element of a 3D mesh, assuming a linear (P1) finite element approximation.
%
% INPUTS
%   p   : Node coordinates (Np × 3 array).
%   t   : Connectivity matrix (Nt × 4), each row contains the indices
%         of the four vertices of a tetrahedron.
%   u   : Nodal values of the finite element solution (Np × 1).
%
% OUTPUTS
%   dxu : du/dx evaluated element-wise (Nt x 1).
%   dyu : du/dy evaluated element-wise (Nt x 1).
%   dzu : du/dz evaluated element-wise (Nt x 1).
%
% METHOD
%   For P1 elements, the gradient is constant within each tetrahedron.
%   It is computed as:
%       grad(u_h) = sum_{i=1}^4 u_i * grad(phi_i)
%   where phi_i are the local basis functions and grad(phi_i)
%   are obtained from kpde3dgphi.
%
% -------------------------------------------------------------------------
% Extract local node indices of each tetrahedron
it1 = t(:,1);
it2 = t(:,2);
it3 = t(:,3);
it4 = t(:,4);

% Nodal values at tetrahedron vertices
ut1 = u(it1);
ut2 = u(it2);
ut3 = u(it3);
ut4 = u(it4);

% Gradients of local P1 basis functions
[~,g1,g2,g3,g4] = kpde3dgphi(p,t);

% Element-wise gradient (constant per tetrahedron)
dxu = ut1.*g1(:,1)+ut2.*g2(:,1)+ut3.*g3(:,1)+ut4.*g4(:,1);
dyu = ut1.*g1(:,2)+ut2.*g2(:,2)+ut3.*g3(:,2)+ut4.*g4(:,2);
dzu = ut1.*g1(:,3)+ut2.*g2(:,3)+ut3.*g3(:,3)+ut4.*g4(:,3);