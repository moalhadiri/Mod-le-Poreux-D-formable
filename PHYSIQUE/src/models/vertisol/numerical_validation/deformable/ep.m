function dep = ep(u)
%ep Computes the derivative of the extraction function e(u)
%   dep = ep(u) evaluates the derivative de/du
%
% Definition:
%   q = 1-1/ell
%   Se(u) = 1 / (1+(-u)^ell)^q      if u < 0
%   Se    = 1                         if u >= 0
%
%   e(Se) = exp(Se)-Se
%
% Chain rule:
%   de/du = (exp(Se)-1)*dSe/du
% -------------------------------------------------------------------------
ell = 3;                    % Material parameter
u = u(:);                   % Ensure column vector
dep = zeros(size(u));       % Initialize output

q = 1-1/ell;              % Exponent parameter

I = (u < 0);                % Indices where u is negative
ps = u(I);                  % Negative values only

% ---------- Compute Se(u) for u < 0
A = 1+(-ps).^ell;         % Base term: 1+(-u)^ell
Se = A.^(-q);               % Se = A^(-q)

% Physical bounding (saturation)
Se = max(0,min(1,Se));

% ---------- Compute dSe/du for u < 0
dSe = q*ell.*(-ps).^(ell-1).*A.^(-q-1);

% ---------- Compute de/du = (exp(Se)-1)*dSe/du
dep(I) = (exp(Se)-1).*dSe;

% Saturated region: derivative is zero
dep(~I) = 0;

dep = dep(:);               % Ensure column vector output
