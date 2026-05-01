function M = kpde3dmass(p,t,alfa)
% KPDE3DMASS  Assemble the 3D P1 finite element mass matrix.
%
% This routine builds the consistent mass matrix associated with
% linear (P1) tetrahedral finite elements.
%
% INPUTS
%   p     : np x 3 array,node coordinates.
%   t     : nt x 4 array,tetrahedral connectivity (vertex indices).
%   alfa  : scalar or column vector defining the coefficient.
%           If length(alfa) = np,alfa is defined at nodes.
%           If length(alfa) = nt,alfa is defined per tetrahedron.
%
% OUTPUT
%   M     : sparse np x np symmetric positive definite mass matrix.
%
% METHOD
%   The coefficient alfa is converted to an elementwise constant value.
%   For P1 tetrahedral elements,the local mass matrix entries are:
%       integral_T phi_i * phi_j dx = V/20 for i ~= j
%       integral_T phi_i * phi_i dx = V/10
%   The global matrix is assembled element by element.
%

np = size(p,1);
nt = size(t,1);
[m1,~] = size(alfa);

% Convert coefficient to elementwise constant value
if (m1 == 1 || m1 == nt)
    c = alfa;
else
    c = (alfa(t(:,1))+alfa(t(:,2))+alfa(t(:,3))+alfa(t(:,4)))/4;
end

% Element volumes
vol = kpde3dgphi(p,t);

% Scale by local mass matrix factor
c = c.*vol/20;

M = sparse(np,np);

% Off-diagonal contributions
for i = 1:4
    for j = 1:i-1
        M = M+sparse(t(:,i),t(:,j),c,np,np);
    end
end

% Enforce symmetry
M = M+M.';

% Diagonal contributions
for i = 1:4
    M = M+sparse(t(:,i),t(:,i),2*c,np,np);
end