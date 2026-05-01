function [p,t,pbx,pby,pbz] = kpde3dumsh(ax,bx,ay,by,az,bz,nx,ny,nz)
% KPDE3DUMSH  Generate a uniform tetrahedral mesh of a rectangular box.
%
% This routine generates a structured grid of points on the box
% [ax,bx] x [ay,by] x [az,bz], then subdivides each hexahedral cell into
% 6 tetrahedra using a fixed connectivity pattern.
%
% INPUTS
%   ax,bx : x-interval bounds
%   ay,by : y-interval bounds
%   az,bz : z-interval bounds
%   nx    : number of grid points in x-direction
%   ny    : number of grid points in y-direction
%   nz    : number of grid points in z-direction
%
% OUTPUTS
%   p   : np x 3 array, node coordinates
%   t   : nt x 4 array, tetrahedral connectivity (vertex indices)
%   pbx : boundary node indices on x-faces (size nx*ny*nz by 2 in stacked form)
%         pbx(:,1) corresponds to x = ax, and pbx(:,2) corresponds to x = bx
%   pby : boundary node indices on y-faces
%         pby(:,1) corresponds to y = ay, and pby(:,2) corresponds to y = by
%   pbz : boundary node indices on z-faces
%         pbz(:,1) corresponds to z = az, and pbz(:,2) corresponds to z = bz
%
% NOTES
%   - The mesh is structured (tensor-product grid) but stored in an
%     unstructured FEM format (p,t).
%   - Each logical hexahedral cell is split into 6 tetrahedra.
%
% -------------------------------------------------------------------------


nq = (nx-1)*(ny-1)*(nz-1);
nt = 6*nq;

% Node coordinates
hx = (bx-ax)/(nx-1);
hy = (by-ay)/(ny-1);
hz = (bz-az)/(nz-1);

[x,y,z] = ndgrid(ax:hx:bx, ay:hy:by, az:hz:bz);
p = [x(:), y(:), z(:)];

% Global node indexing on the structured grid
ip  = (1:nx*ny*nz)';
ijk = reshape(ip,[nx,ny,nz]);

% Boundary nodes (six faces)
b1  = squeeze(ijk(:,1,:));   ib1 = b1(:);   % y = ay
b2  = squeeze(ijk(nx,:,:));  ib2 = b2(:);   % x = bx
b3  = squeeze(ijk(:,ny,:));  ib3 = b3(:);   % y = by
b4  = squeeze(ijk(1,:,:));   ib4 = b4(:);   % x = ax
b5  = squeeze(ijk(:,:,1));   ib5 = b5(:);   % z = az
b6  = squeeze(ijk(:,:,nz));  ib6 = b6(:);   % z = bz

% Interior nodes for each of the 8 corners of a hexahedral cell
ib236 = union(ib2,union(ib3,ib6)); ip1 = setdiff(ip,ib236);
ib346 = union(ib3,union(ib4,ib6)); ip2 = setdiff(ip,ib346);
ib345 = union(ib3,union(ib4,ib5)); ip3 = setdiff(ip,ib345);
ib235 = union(ib2,union(ib3,ib5)); ip4 = setdiff(ip,ib235);
ib126 = union(ib1,union(ib2,ib6)); ip5 = setdiff(ip,ib126);
ib146 = union(ib1,union(ib4,ib6)); ip6 = setdiff(ip,ib146);
ib145 = union(ib1,union(ib4,ib5)); ip7 = setdiff(ip,ib145);
ib125 = union(ib1,union(ib2,ib5)); ip8 = setdiff(ip,ib125);

% Tetrahedralization: split each logical cell into 6 tetrahedra
t = zeros(nt,4);
iq1 = 1:nq; iq2 = iq1+nq; iq3 = iq2+nq;
iq4 = iq3+nq; iq5 = iq4+nq; iq6 = iq5+nq;

t(iq1,1)=ip1; t(iq1,2)=ip2; t(iq1,3)=ip6; t(iq1,4)=ip7;
t(iq2,1)=ip1; t(iq2,2)=ip6; t(iq2,3)=ip5; t(iq2,4)=ip7;
t(iq3,1)=ip1; t(iq3,2)=ip2; t(iq3,3)=ip7; t(iq3,4)=ip3;
t(iq4,1)=ip1; t(iq4,2)=ip4; t(iq4,3)=ip3; t(iq4,4)=ip7;
t(iq5,1)=ip1; t(iq5,2)=ip5; t(iq5,3)=ip8; t(iq5,4)=ip7;
t(iq6,1)=ip1; t(iq6,2)=ip4; t(iq6,3)=ip7; t(iq6,4)=ip8;

% Boundary node lists returned as pairs of opposite faces
pbx = [ib4 ib2];  % x = ax and x = bx
pby = [ib1 ib3];  % y = ay and y = by
pbz = [ib5 ib6];  % z = az and z = bz