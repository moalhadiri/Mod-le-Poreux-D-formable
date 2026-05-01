function g = ellp2(u)
%ellp2 Second derivative of ell(u).
%
%   g = ellp2(u) computes the second derivative of the nonlinear function
%   ell(u), defined by
%
%   ell''(u) =
%       khpp(u).*gz(u).^2 ...
%     + 4*khp(u).*dgz(u).*gz(u) ...
%     + 2*kh(u).*d2gz(u).*gz(u) ...
%     + 2*kh(u).*dgz(u).^2
%
%   Input:
%       u : Input variable (scalar or vector)
%
%   Output:
%       g : Second derivative of ell evaluated at u (column vector)
%
%   Note:
%       All auxiliary functions (kh, khp, khpp, gz, dgz, d2gz)
%       must be defined separately.

% Ensure column vector
u = u(:);

% Second derivative of ell
g = khpp(u).*gz(u).^2 ...
  + 4*khp(u).*dgz(u).*gz(u) ...
  + 2*kh(u).*d2gz(u).*gz(u) ...
  + 2*kh(u).*dgz(u).^2;

% Ensure column output
g = g(:);
