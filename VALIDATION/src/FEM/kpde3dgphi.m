function [vol,g1,g2,g3,g4,dphidz] = kpde3dgphi(p,t)
% KPDE3DGPHI  Compute tetrahedron volumes and gradients of P1 basis functions.
%
% This routine evaluates:
%  -The volume of each tetrahedral element.
%  -The gradients of the four local P1 basis functions.
%
% INPUTS
%   p : np x 3 array, node coordinates.
%   t : nt x 4 array, tetrahedral connectivity (vertex indices).
%
% OUTPUTS
%   vol     : nt x 1 array, element volumes.
%   g1-g4   : nt x 3 arrays, gradients of the four P1 basis functions.
%              The gradients are constant within each tetrahedron.
%   dphidz  : Partial derivatives of basis functions with respect to z.
%
% METHOD
%   The gradients are obtained using the inverse of the element Jacobian.
%   For linear tetrahedral elements (P1), basis functions are affine,
%   hence their gradients are constant inside each element.
%

it1 = t(:,1); it2 = t(:,2); it3 = t(:,3); it4 = t(:,4);

x1 = p(it1,1); x2 = p(it2,1); x3 = p(it3,1); x4 = p(it4,1);
y1 = p(it1,2); y2 = p(it2,2); y3 = p(it3,2); y4 = p(it4,2);
z1 = p(it1,3); z2 = p(it2,3); z3 = p(it3,3); z4 = p(it4,3);

% 3x3 Jacobian matrix entries
J11 = x2-x1; J12 = y2-y1; J13 = z2-z1;
J21 = x3-x1; J22 = y3-y1; J23 = z3-z1;
J31 = x4-x1; J32 = y4-y1; J33 = z4-z1;

% Determinant of the Jacobian
det = J11.*(J22.*J33-J32.*J23) ...
   +J12.*(J31.*J23-J21.*J33) ...
   +J13.*(J21.*J32-J31.*J22);

% Element volume
vol = abs(det)/6;

if (nargout == 1), return; end

% Inverse Jacobian matrix coefficients
C11 = (J22.*J33-J32.*J23)./det;
C12 = (J13.*J32-J12.*J33)./det;
C13 = (J12.*J23-J13.*J22)./det;

C21 = (J31.*J23-J21.*J33)./det;
C22 = (J11.*J33-J13.*J31)./det;
C23 = (J21.*J13-J23.*J11)./det;

C31 = (J21.*J32-J31.*J22)./det;
C32 = (J12.*J31-J32.*J11)./det;
C33 = (J11.*J22-J12.*J21)./det;

% Gradients of P1 basis functions (constant per tetrahedron)
g2 = [C11 C21 C31];
g3 = [C12 C22 C32];
g4 = [C13 C23 C33];
g1 = -g2-g3-g4;

% Partial derivative with respect to z
dphidz = [C13; C23; C33; -(C13+C23+C33)];