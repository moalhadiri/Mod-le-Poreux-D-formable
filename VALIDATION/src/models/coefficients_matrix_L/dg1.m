function g = dg1(u)
%dg1 First derivative of g1(u).
%
%   g = dg1(u) computes the derivative of
%
%       g1(u) = we(u)
%
%   hence
%
%       dg1(u) = wep(u)
%
%   Input:
%       u : Input variable (scalar or vector)
%
%   Output:
%       g : dg1/du evaluated at u (column vector)

% Ensure column vector
u = u(:);

% Derivative of g1(u)
g = wep(u);

% Ensure column output
g = g(:);

