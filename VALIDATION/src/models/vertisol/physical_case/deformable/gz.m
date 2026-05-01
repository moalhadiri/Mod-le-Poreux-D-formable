function g = gz(u)
%GZ Computes the flow gravity function
%   g = gz(u) evaluates the gravity function g(u) at point(s) u
%
%   Input:
%       u  - scalar or vector of points where to evaluate the function
%
%   Output:
%       g  - value(s) of the flow gravity g(u)
%
%   Note:
%       er - constant entrainment ratio

er = 0.32;
g = (1+er)./we(u);