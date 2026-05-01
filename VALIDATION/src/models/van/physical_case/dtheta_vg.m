function dtheta = dtheta_vg(u)
%dtheta_vg Derivative dtheta/du for the van Genuchten water retention model.
%
%   dtheta = dtheta_vg(u) computes the derivative of the volumetric water
%   content theta with respect to the pressure head u (psi).
%
%   Model:
%       theta(u) = theta_r+(theta_s-theta_r) * (1+(-alpha*u)^n)^(-m), for u <= 0
%       theta(u) = theta_s,                                               for u > 0
%
%   Exact derivative for u <= 0:
%
%       dtheta/du =
%       -(alpha*m*n*(-alpha*u)^(n-1)*(theta_r-theta_s)) ...
%        / ((-alpha*u)^n+1)^(m+1)
%
%   Input:
%       u      : Pressure head (psi),scalar or array.
%
%   Output:
%       dtheta : dtheta/du evaluated at u (same size as u).
%
%   Note:
%       For u > 0 (saturated zone),dtheta/du = 0.

[~,~,~,~,~,~,~,~,alpha,~,~,theta_r,theta_s,n,m,~] = parametre();

% Initialize output (same size as u)
dtheta = zeros(size(u));

% Unsaturated region (u <= 0)
mask = (u <= 0);
if any(mask(:))
    % Exact prescribed formula (vectorized)
    dtheta(mask) = -(alpha.*m.*n.*(-alpha.*u(mask)).^(n-1).*(theta_r-theta_s)) ...
                   ./ ((-alpha.*u(mask)).^n+1).^(m+1);
end

% For u > 0: dtheta = 0 (already initialized)