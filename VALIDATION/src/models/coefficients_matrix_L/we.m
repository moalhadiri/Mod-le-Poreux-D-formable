function g = we(Theta)
%we Computes the function w_e based on Theta.
%   g = we(Theta) evaluates the expression
%
%       we =  1 + e(Theta)
%
%   Input:
%       Theta : Input variable (scalar or vector)
%
%   Output:
%       g     : Computed value of w_e at Theta
%
%   Note:
%       This function relies on the auxiliary function E(Theta).

g = 1 + e(Theta);  % we(Theta) = 1 + e(Theta)
