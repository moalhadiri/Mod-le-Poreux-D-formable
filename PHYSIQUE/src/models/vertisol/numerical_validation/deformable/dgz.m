function g = dgz(u)
%dgz Computes the derivative of the flow gravity function
%   g = dgz(u) evaluates the derivative g'(u) at point(s) u
%
%   Input:
%       u  - scalar or vector of points where to evaluate the derivative
%
%   Output:
%       g  - value(s) of the derivative g'(u)
%
%   Note:
%       eps1 - small regularization term to avoid division by zero

eps1 = 1e-8;
g = -((1).*wep(u))./(we(u)+eps1).^2;

