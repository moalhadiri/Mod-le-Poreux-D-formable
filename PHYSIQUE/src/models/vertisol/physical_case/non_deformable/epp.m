function epp_val = epp(u)
%epp Dummy function for second derivative of extraction function
%   epp_val = epp(u) returns a small constant times the input
%
%   Input:
%       u  - input variable (scalar or vector)
%
%   Output:
%       epp_val - value = 1e-8*u (small regularization term)
%
%   Note:
%       This is a placeholder/dummy function that returns a linear
%       function of u with a very small coefficient for numerical
%       regularization purposes.

epp_val = 1e-8.*u;
