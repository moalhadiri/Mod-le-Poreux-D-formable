function eb = ep(u)
%ep Dummy function for derivative of extraction function
%   eb = ep(u) returns a small constant times the input
%
%   Input:
%       u  - input variable (scalar or vector)
%
%   Output:
%       eb - value = 1e-8*u (small regularization term)
%
%   Note:
%       This is a placeholder/dummy function that returns a linear
%       function of u with a very small coefficient for numerical
%       regularization purposes.

eb = 1e-8.*u;