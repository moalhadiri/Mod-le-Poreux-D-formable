function g = ell(u)
%ell Nonlinear function ell(u).
%
%   g = ell(u) evaluates the nonlinear function
%
%       ell(u) = kh(u).*gz(u).^2
%
%   Input:
%       u : Input variable (scalar or vector)
%
%   Output:
%       g : Value of ell(u) evaluated at u (column vector)
%
%   Note:
%       Auxiliary functions kh and gz must be defined separately.

% Ensure column vector
u = u(:);

% Evaluate ell(u)
g = kh(u).*gz(u).^2;

% Ensure column output
g = g(:);