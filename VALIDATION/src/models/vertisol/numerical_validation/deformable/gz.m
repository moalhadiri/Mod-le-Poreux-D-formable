function g = gz(u)
%gz Computes the flow gravity (gravitation de l'écoulement)
%   g = gz(u) evaluates the gravity function at point(s) u
%
%   Input:
%       u  - scalar or vector of points where to evaluate the function
%
%   Output:
%       g  - value(s) of the flow gravity g(u)
%
%   Definition:
%       g(u) = 1/we(u)
%       where we(u)=1+e(u)

g = 1./we(u);
