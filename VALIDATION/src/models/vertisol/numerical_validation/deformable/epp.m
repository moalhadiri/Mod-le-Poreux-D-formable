function depp = epp(u)
%EPP Computes the second derivative of the extraction function e(u)
%   depp = epp(u) evaluates the second derivative d²e/du²
%
% Definition:
%   q = 1-1/ell
%   Se(u) = (1+(-u)^ell)^(-q)        if u < 0
%   Se    = 1                          if u >= 0
%
%   e(Se) = exp(Se) - Se
%
% Chain rule:
%   e'(u)  = (exp(Se)-1)*Se'
%   e''(u) = exp(Se)*(Se')^2+(exp(Se)-1)*Se''
% -------------------------------------------------------------------------
ell=3;
u = u(:);
depp = zeros(size(u));

q = 1-1/ell;

I = (u < 0);
ps = u(I);
x = -ps;                          % x = -u > 0

% ----- Se(u)
A = 1+x.^ell;                     % A = 1+(-u)^ell
Se = A.^(-q);

% Physical bounding (saturation)
Se = max(0,min(1,Se));

% ----- Se'(u) - first derivative
Se_p = q*ell.*x.^(ell-1).*A.^(-q-1);

% ----- Se''(u) - second derivative
Se_pp = -q*ell*(ell-1).*x.^(ell-2).*A.^(-q-1) ...
       +q*ell^2*(q+1).*x.^(2*ell-2).*A.^(-q-2);

% ----- e''(u) - second derivative of e
depp(I) = exp(Se).*(Se_p.^2)+(exp(Se)-1).*Se_pp;

% Saturated region: second derivative is zero
depp(~I) = 0;

depp = depp(:);
end