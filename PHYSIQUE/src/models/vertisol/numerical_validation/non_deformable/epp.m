function epp_val = epp(u)
%epp Dummy function for second derivative of extraction function
%   epp_val = epp(u) returns a small constant value regardless of input
%
%   Input:
%       u  - input variable (scalar or vector, ignored)
%
%   Output:
%       epp_val - constant small value (1e-8) for numerical regularization
%
%   Note:
%       This is a placeholder/dummy function that returns a constant
%       to avoid numerical issues (division by zero, etc.)

epp_val = 1e-8.*u;
