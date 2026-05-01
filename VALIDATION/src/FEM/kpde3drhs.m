function b = kpde3drhs(p,t,f)
% KPDE3DRHS  Assemble the 3D P1 finite element right-hand side vector.
%
% This routine builds the load vector associated with a source term f
% using linear (P1) tetrahedral finite elements.
%
% INPUTS
%   p : np x 3 array,node coordinates.
%   t : nt x 4 array,tetrahedral connectivity (vertex indices).
%   f : source term,scalar or column vector.
%       If length(f) = np,f is defined at nodes.
%       If length(f) = nt,f is defined per tetrahedron.
%
% OUTPUT
%   b : np x 1 right-hand side vector.
%
% METHOD
%   The source term is converted to an elementwise constant value.
%   For P1 tetrahedral elements:
%       integral_T f * phi_i dx is approximated by f_T * V / 4
%   where V is the tetrahedron volume.


np = size(p,1);
nt = size(t,1);
[m1,~] = size(f);

% Convert source term to elementwise constant value
if (m1 == 1 || m1 == nt)
    ff = f;
else
    ff = (f(t(:,1))+f(t(:,2))+f(t(:,3))+f(t(:,4)))/4;
end

% Element volumes
vol = kpde3dgphi(p,t);

% Local contribution factor (V/4 for P1 elements)
ff = ff.*vol/4;

b = sparse(np,1);

% Assembly
for i = 1:4
    b = b+sparse(t(:,i),1,ff,np,1);
end

b = full(b);