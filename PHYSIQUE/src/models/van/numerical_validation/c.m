function c_val = c(psi)
%C Capillary capacity function c(psi) = dtheta/dpsi (simplified model).
%
%   c_val = C(psi) returns the capillary capacity defined as the derivative
%   of the (simplified) volumetric water content theta(psi):
%
%       theta(psi) = 1/(1-psi^ell)
%       c(psi)     = dtheta/dpsi = ell*psi^(ell-1)/(1-psi^ell)^2
%
%   Convention:
%      -Unsaturated: psi < 0  -> use the analytical expression above
%      -Saturated  : psi >= 0 -> apply a small regularization epsilon
%                                 (prevents singularities/zero Jacobian)
%
%   Input:
%       psi   : Pressure head (scalar or vector/array).
%
%   Output:
%       c_val : Capillary capacity c(psi) (column vector).
%
%   Note:
%       The saturated regularization value is a numerical choice meant to
%       stabilize Newton-type solvers.

% Ensure column vector
psi = psi(:);

% Fixed exponent
ell = 3;

% Initialize output
c_val = zeros(size(psi));

% Unsaturated region (psi < 0)
I  = (psi < 0);
ps = psi(I);

den = (1-ps.^ell).^2;

% Optional safeguard if needed:
% den = max(den, 1e-14);

c_val(I) = (ell.*ps.^(ell-1))./den;

% Saturated region: regularization (numerical choice)
c_val(~I) = 1e-8;

% Ensure column output
c_val = c_val(:);
