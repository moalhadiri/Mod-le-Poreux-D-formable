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
%       er   - constant entrainment ratio
%       eps1 - small regularization term to avoid division by zero

er   = 0.32;
eps1 = 1e-8;
g = -((1+er).*wep(u))./(we(u)+eps1).^2;