function dtheta = dtheta_vg(u)
%DTHETA_VG First derivative of the simplified water content theta(u).
%
%   dtheta = DTHETA_VG(u) computes the derivative of the simplified
%   volumetric water content defined by
%
%       theta(u) = 1/(1-u^ell),   for u < 0
%       theta(u) = 1,                for u >= 0
%
%   with ell = 3.
%
%   Hence, for u < 0:
%
%       dtheta/du = ell*u^(ell-1)/(1-u^ell)^2
%
%   Input:
%       u      : Pressure head (scalar or vector).
%
%   Output:
%       dtheta : First derivative dtheta/du (column vector).
%
%   Note:
%       A small value is imposed in the saturated region (u >= 0)
%       to avoid a zero Jacobian in Newton-type solvers.

% Ensure column vector
u = u(:);

% Fixed exponent
ell = 3;

% Initialize
dtheta = zeros(size(u));

% Unsaturated region (u < 0)
I = (u < 0);
dtheta(I) = (ell .* u(I).^(ell-1))./( (1-u(I).^ell).^2 );

% Saturated region (regularized)
dtheta(u >= 0) = 1e-8;

% Ensure column output
dtheta = dtheta(:);