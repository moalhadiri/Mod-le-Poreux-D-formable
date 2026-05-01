function d2theta = d2theta_vg(u)
%d2theta_vg Second derivative d²theta/du² for the van Genuchten model.
%
%   d2theta = d2theta_vg(u) computes the second derivative of the
%   volumetric water content theta with respect to the pressure head u (psi).
%
%   Exact prescribed formula for u <= 0:
%
%   d²theta/du² =
%     -(m*n*(-alpha*u)^n*(theta_r-theta_s) *
%       ((-alpha*u)^n-n+m*n*(-alpha*u)^n+1)) ...
%     / (u^2 * ((-alpha*u)^n+1)^(m+2))
%
%   Model:
%       theta(u) = theta_r+(theta_s-theta_r)*(1+(-alpha*u)^n)^(-m), for u <= 0
%       theta(u) = theta_s,                                              for u > 0
%
%   Input:
%       u        : Pressure head (psi),scalar or array.
%
%   Output:
%       d2theta  : Second derivative d²theta/du² evaluated at u
%                  (same size as u).
%
%   Note:
%       For u > 0 (saturated zone),d²theta/du² = 0.

[~,~,~,~,~,~,~,~,alpha,~,~,theta_r,theta_s,n,m,~] = parametre();

% Initialize output (same size as u)
d2theta = zeros(size(u));

% Unsaturated region (u <= 0)
mask = (u <= 0);
if any(mask(:))
    d2theta(mask) = -(m.*n.*(-alpha.*u(mask)).^n.*(theta_r-theta_s).*...
                       ((-alpha.*u(mask)).^n-n+m.*n.*(-alpha.*u(mask)).^n+1)) ...
                    ./((u(mask)).^2.*((-alpha.*u(mask)).^n+1).^(m+2));
end

% For u > 0: d2theta = 0 (already initialized)
