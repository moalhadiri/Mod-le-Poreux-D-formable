function g = g1(u)
%g1 evaluates the function g1(u)=we(u).
%
%   g=g1(u) computes the function g1 at the input u, defined as
%
%       g1(u)=we(u)
%
%   Input:
%       u : Input variable (scalar or vector)
%
%   Output:
%       g : Column vector containing g1(u)
%
%   Note:
%       The input is reshaped to a column vector for consistency.

% Ensure u is a column vector
u = u(:);

% Evaluate g1(u)
g = we(u);

% Ensure output is a column vector
g = g(:);