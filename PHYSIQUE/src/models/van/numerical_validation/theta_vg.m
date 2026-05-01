function theta = theta_vg(u)
%theta Simplified volumetric water content model.
%
%   theta = theta_vg(u) evaluates a simplified water content function
%   defined by
%
%       theta(u) = 1/(1-u^ell),   for u<0
%       theta(u) = 1,                for u>=0
%
%   where ell is a prescribed exponent.
%
%   Input:
%       u     : Pressure head (scalar or vector). Unsaturated if u<0.
%
%   Output:
%       theta : Volumetric water content (column vector).
%
%   Note:
%       The result is clamped to [0,1] for physical consistency.

% Ensure column vector
u = u(:);

% Exponent (model parameter)
ell = 3;

% Initialization (saturated by default)
theta = ones(size(u));

% Unsaturated region (u<0)
I = (u<0);
theta(I) = 1 ./ (1-u(I).^ell);

% Physical bounds
theta = min(max(theta, 0), 1);

% Ensure column output
theta = theta(:);
