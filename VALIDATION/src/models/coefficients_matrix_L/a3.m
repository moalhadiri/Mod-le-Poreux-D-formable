function g = a3(u,t)
%a3 Assemble nonlinear coefficient average over tetrahedron.
%   g = a3(u,t) computes the element-wise average of
%   kh(u) * (gz(u)^2) * g2(u) over each tetrahedron.
%
%   Input:
%       u : solution vector (nodal values)
%       t : tetrahedron connectivity matrix
%
%   Output:
%       g : average value per tetrahedron (column vector)

g00 = kh(u).*(gz(u).^2).*g2(u); % Evaluate nodal values
g   = (g00(t(:,1))+g00(t(:,2))+...
       g00(t(:,3))+g00(t(:,4)))/4; % Average nodal values per tetrahedron