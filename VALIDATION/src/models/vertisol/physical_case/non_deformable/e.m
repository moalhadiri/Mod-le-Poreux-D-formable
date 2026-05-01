function eb = e(u)
%E Dummy function for void ratio (extraction function)
%   eb = e(u) returns a constant value regardless of input
%
%   Input:
%       u  - input variable (scalar or vector, ignored)
%
%   Output:
%       eb - constant void ratio value (0.32 for clay, rigid soil)
%
%   Note:
%       0.32 is the void ratio for clay (rigid soil case)
%       This is a simplified placeholder function that returns
%       a constant value independent of u.
%       u.^0 = 1 for all u (including u=0)

eb = 0.32.*u.^0;  % u.^0 = 1 for all values of u