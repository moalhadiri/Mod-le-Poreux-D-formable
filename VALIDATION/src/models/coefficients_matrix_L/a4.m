function g = a4(u,p,t)
%a4 Assemble regularized nonlinear coupling term.
%   g = a4(u,p,t) computes the finite element contribution of
%   kh(u) * (gz(u)^2) * dg2(u) * (u_z+epsilon).
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

g00 = kh(u).*(gz(u).^2).*dg2(u); % Evaluate nodal values
c   = (g00(t(:,1))+g00(t(:,2))+...
      g00(t(:,3))+g00(t(:,4)))/4; % Average nodal values per tetrahedron

g = c.*(dzu+eps1);              % Regularized RHS contribution
