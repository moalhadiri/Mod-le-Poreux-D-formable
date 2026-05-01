function g = a2(u,p,t)
%a2 Assemble regularized nonlinear diffusion term (xy-plane).
%   g = a2(u,p,t) computes the finite element contribution of
%   kh(u)*dg1(u)*(u_x+u_y+epsilon).
%
%   Input:
%       u : solution vector (nodal values)
%       p : mesh node coordinates [x y z]
%       t : tetrahedron connectivity matrix
%
%   Output:
%       g : assembled RHS contribution (column vector)

eps1 = 1e-8;                         % Small regularization parameter

[dxu,dyu,~] = edp3dgrad(p,t,u);     % Compute x,y-derivatives at tetrahedron centers

g00 = kh(u).*dg1(u);              % Evaluate nodal values
c   = (g00(t(:,1))+g00(t(:,2))+...
      g00(t(:,3))+g00(t(:,4)))/4; % Average nodal values per tetrahedron

g = c.*(dxu+dyu+eps1);        % Regularized RHS contribution
