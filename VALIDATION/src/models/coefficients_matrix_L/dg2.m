function g = dg2(u)
%dg2 First derivative of g2(u).
%   g = dg2(u) computes the derivative of the nonlinear function
%
%       g2(u) = g1(u).*gz(u)
%
%   using the product rule:
%
%       g2'(u) = dg1(u).*gz(u)+g1(u).*dgz(u)
%
%   Input:
%       u : Input variable (scalar or vector)
%
%   Output:
%       g : First derivative of g2 evaluated at u (column vector)
%
%   Note:
%       Auxiliary functions g1, dg1, gz, and dgz must be defined separately.

% Ensure column vector
u = u(:);

% First derivative of g2(u)
g = dg1(u).*gz(u)+g1(u).*dgz(u);

% Ensure column output
g = g(:);



