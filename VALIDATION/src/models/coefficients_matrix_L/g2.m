function g = g2(u)
%G2 Computes the product g1(u) * gz(u).
%   g = g2(u) evaluates the pointwise product
%
%       g2 = g1(u).*gz(u)
%
%   Input:
%       u : Input variable (scalar or vector)
%
%   Output:
%       g : Value(s) of the product g1(u).*gz(u)
%
%   Note:
%       This function assumes that g1 and gz are defined separately.

g = g1(u).*gz(u);


