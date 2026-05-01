function g = a5(u,p,t)
%a5 Assemble regularized nonlinear diffusion term.
%   g = a5(u,p,t) computes the finite element contribution of
%   g2(u)*ell'(u)*(u_z+epsilon), with small regularization.
%
%   Input:
%       u : solution vector (nodal values)
%       p : mesh node coordinates [x y z]
%       t : tetrahedron connectivity matrix
%
%   Output:
%       g : assembled RHS contribution (column vector)

eps1 = 1e-8;                         % Small regularization parameter

[~,~,dzu] = edp3dgrad(p,t,u);       % Compute z-derivative at tetrahedron centers

g00 = g2(u).*ellp(u);             % Evaluate g2(u)*ell'(u) at nodes
c    = (g00(t(:,1))+g00(t(:,2))+...
        g00(t(:,3))+g00(t(:,4)))/4;   % Average nodal values per tetrahedron

g = c.*(dzu+eps1);              % Regularized RHS contribution
