function eb = e(u)
%e Computes the void ratio (extraction function) based on Se(psi)
%   eb = e(u) evaluates the void ratio at potential u
%
%   Input:
%       u   : matrix potential psi (negative in unsaturated zone)
%       (ell is internally set to 3)
%
%   Output:
%       eb  : void ratio
%
%   Effective saturation (new formulation):
%       q = 1-1/ell
%       Se(u) = 1/(1+(-u)^ell)^q    for u < 0
%       Se = 1                           for u >= 0
%
%   Extraction law (unchanged):
%       e(Se) = exp(Se)-Se
% -------------------------------------------------------------------------
ell = 3;
u = u(:);

q = 1-1/ell;

% Compute Se(u)
Se = ones(size(u));
I = (u < 0);
Se(I) = 1./(1+(-u(I)).^ell).^q;

% Physical bounding (saturation)
Se = max(0,min(1, Se));

% Compute e(Se)
eb = exp(Se)-Se;

eb = eb(:);