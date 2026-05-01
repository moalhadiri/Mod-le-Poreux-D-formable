function g = wep(Theta)
%   wep  derivative of we = 1 + e(u)
%   we represents a base function, and wep is its derivative
%
%   Input:
%       Theta : Input variable (scalar or vector)
%
%   Output:
%       g     : Result of wep evaluated at Theta (derivative of we)

g = ep(Theta);  % Computes the derivative of e(u) (which is also the derivative of we)
% Note: we(Theta) = 1 + e(Theta), so wep(Theta) = ep(Theta)
