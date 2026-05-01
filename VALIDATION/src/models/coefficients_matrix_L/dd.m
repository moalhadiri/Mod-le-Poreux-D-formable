function g = dd(u,p,t)
%dd Assemble discrete diffusion operator contribution.
%   g = dd(u,p,t) computes the finite element approximation of
%   the nonlinear diffusion term involving dg2(u)*ell'(u)*u_z.
%
%   Input:
%       u : solution vector (nodal values)
%       p : mesh node coordinates [x y z]
%       t : tetrahedron connectivity matrix
%
%   Output:
%       g : assembled RHS contribution (column vector)

[~,~,dzu] = edp3dgrad(p,t,u);   % Compute z-derivative at tetrahedron centers

g1 = dg2(u).*ellp(u);          % Evaluate dg2(u)*ell'(u) at nodes
c  = (g1(t(:,1))+g1(t(:,2))+...
      g1(t(:,3))+g1(t(:,4)))./ 4;   % Average nodal values per tetrahedron

g = c.*dzu;                    % Multiply by z-derivative (RHS contribution)