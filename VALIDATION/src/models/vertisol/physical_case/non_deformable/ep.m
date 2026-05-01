function eb = ep(u)
%ep Dummy function for derivative of extraction function
%   eb = ep(u) returns a small constant value regardless of input
%
%   Input:
%       u  - input variable (scalar or vector, ignored)
%
%   Output:
%       eb - constant value (1e-8) for numerical regularization
%
%   Note:
%       This is a placeholder/dummy function that returns a constant
%       to avoid numerical issues (division by zero, etc.)

eb = 1e-8.*u;