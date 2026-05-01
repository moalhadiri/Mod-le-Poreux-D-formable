function g = a0(u,t)
%a0 Assemble nonlinear diffusion coefficient average.
%   g = a0(u,t) computes the element-wise average of
%   kh(u) * g1(u) over each tetrahedron.
%
%   Input:
%       u : solution vector (nodal values)
%       t : tetrahedron connectivity matrix
%
%   Output:
%       g : average value per tetrahedron (column vector)

g0 = kh(u).*g1(u);                % Evaluate nodal values
g   = (g0(t(:,1))+g0(t(:,2))+...
       g0(t(:,3))+g0(t(:,4)))./ 4; % Average nodal values per tetrahedron