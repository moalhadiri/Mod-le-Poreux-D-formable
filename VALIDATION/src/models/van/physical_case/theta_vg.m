function theta = theta_vg(u)
%theta_vg Volumetric water content theta(u) using van Genuchten (1980).
%
%   theta = theta_vg(u) returns the volumetric water content theta as a
%   function of the pressure head u (often denoted psi),following the
%   van Genuchten soil-water retention curve.
%
%   Model (unsaturated,u < 0):
%       theta(u) = theta_r+(theta_s-theta_r)*(1+(alpha*|u|)^n)^(-m)
%
%   Saturated (u >= 0):
%       theta(u) = theta_s
%
%   Input:
%       u     : Pressure head (psi),scalar or array (same size as output).
%
%   Output:
%       theta : Volumetric water content (m^3/m^3),same size as u.
%
%   Notes:
%      -Parameters (alpha,n,m,theta_r,theta_s) are obtained from
%         the function PARAMETRE().
%      -Typically,n > 1 and m = 1-1/n.

[~,~,~,~,~,~,~,~,alpha,~,~,theta_r,theta_s,n,m,~] = parametre();

theta = zeros(size(u));  % initialize output (same shape as u)

% Unsaturated zone (u < 0)
mask = (u < 0);
if any(mask(:))
    theta(mask) = theta_r+(theta_s-theta_r) .* ...
        (1+(alpha .* abs(u(mask))).^n).^(-m);
end

% Saturated zone (u >= 0)
mask_sat = ~mask; % equivalent to (u >= 0)
theta(mask_sat) = theta_s;
