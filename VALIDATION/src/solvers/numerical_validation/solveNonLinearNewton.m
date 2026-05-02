function [u, iterNL, kappa_hist, cond_diagnostic, err_hist] = solveNonLinearNewton( ...
    lam,p,t,k,ibcd,inodes,eps1,time,up,test_id,test_cond)
% SOLVENONLINEARNEWTON - Newton solver for Richards equation with GMRES
%   Solves the nonlinear Richards equation using Newton's method with
%   adaptive damping and GMRES linear solver with ILU preconditioning.
%
%   Inputs:
%       lam         - Newton damping parameter (0 < lam <= 1)
%       p           - Node coordinates matrix (np x 3)
%       t           - Tetrahedral connectivity matrix
%       k           - Time step coefficient (1/dt)
%       ibcd        - Dirichlet boundary condition nodes
%       inodes      - Free nodes (interior nodes)
%       eps1        - Nonlinear convergence tolerance
%       time        - Current simulation time
%       up          - Solution from previous time step
%       test_id     - Source term identifier
%       test_cond   - Boundary condition identifier
%
%   Outputs:
%       u               - Solution vector
%       iterNL          - Number of Newton iterations
%       kappa_hist      - Condition number history
%       cond_diagnostic - Structure with conditioning and GMRES diagnostics
%       err_hist        - Newton error history

np = size(p,1);

% Dirichlet boundary conditions: compute exact solution on boundary nodes
[ue,~,~,~] = uex(p(ibcd,1),p(ibcd,2),p(ibcd,3),time,test_cond);

% Initial guess and boundary conditions
u = up;
ubcd = zeros(np,1);
ubcd(ibcd) = ue;

% =============================
% SOLVER PARAMETERS
% =============================

IterMaxNL = 200;        % Maximum Newton iterations
coef = 1;               % Coefficient for nonlinear terms

% GMRES parameters
tol_gmres = 1e-6;       % GMRES tolerance
restart = 50;           % GMRES restart parameter
maxit = 500;            % Maximum GMRES iterations

% =============================
% MASS MATRIX
% =============================

M = kpde3dmass(p,t,1);

% =============================
% HISTORY ARRAYS
% =============================

err_hist = zeros(IterMaxNL,1);
kappa_hist = zeros(IterMaxNL,1);
cond_diagnostic = struct();

% =============================
% PRECONDITIONER SETUP
% =============================

ilu_done = false;
perm_done = false;

Lpre = [];
Upre = [];

% =============================
% NEWTON ITERATION LOOP
% =============================

err = 1;
iterNL = 0;

while(err > eps1 && iterNL < IterMaxNL)

    iterNL = iterNL + 1;

    % =============================
    % JACOBIAN AND RESIDUAL ASSEMBLY
    % =============================

    Rp = kpde3drgd(p,t,coef.*tgam6(u,t),coef.*tgam6(u,t),coef.*gam6(u,t));

    nux = talpha2(u,p,t) + talpha3(u,p,t);
    nuz = alpha2(u,p,t) + alpha3(u,p,t);

    D = kpde3div(p,t,coef.*nux,coef.*nux,coef.*nuz);

    Ms = kpde3dmass(p,t,coef.*alpha0(u,p,t));

    % Source term
    fh = fex(p(:,1),p(:,2),p(:,3),time,test_id);
    b = kpde3drhs(p,t,coef.*fh);

    % Nonlinear contributions
    b1 = kpde3drhs(p,t,coef.*gam3(u,p,t));
    D0 = kpde3drhs(p,t,coef.*tgam4(u,p,t)+coef.*gam4(u,p,t));

    ru = cp(u).*(u-up);
    cofcondu = (c(u)+ru);
    MC = kpde3dmass(p,t,cofcondu);

    bC = c(u).*(u-up);
    b2 = kpde3drhs(p,t,bC);

    % Complete right-hand side
    b = b + b1 - Rp*u - D0 - (1/k)*b2;

    % =============================
    % SYSTEM MATRIX
    % =============================

    A = (1/k)*MC + Ms + Rp + D;

    % =============================
    % DIRICHLET BOUNDARY CONDITIONS
    % =============================

    b = b - A*ubcd;
    b(ibcd) = [];
    A(:,ibcd) = [];
    A(ibcd,:) = [];

    % =============================
    % CONDITION NUMBER ESTIMATION
    % =============================

    if iterNL == 1
        kappa_hist(iterNL) = condest(A);
    else
        kappa_hist(iterNL) = kappa_hist(iterNL-1);
    end

    % =============================
    % MATRIX PERMUTATION (AMD)
    % =============================

    if ~perm_done
        perm = symamd(A);
        perm_done = true;
    end

    Aperm = A(perm,perm);
    bperm = b(perm);

    % =============================
    % ILU PRECONDITIONER
    % =============================

    if ~ilu_done
        setup.type = 'ilutp';
        setup.droptol = 1e-3;
        setup.udiag = 1;
        [Lpre,Upre] = ilu(Aperm,setup);
        ilu_done = true;
    end

    % =============================
    % GMRES LINEAR SOLVER
    % =============================

    [wperm,flag,relres,iter] = gmres(Aperm,bperm,restart,tol_gmres,maxit,Lpre,Upre);

    % Compute total iterations
    if numel(iter)==2
        itTotal = iter(1)*restart + iter(2);
    else
        itTotal = iter;
    end

    % =============================
    % SOLUTION RECONSTRUCTION
    % =============================

    wi = zeros(size(b));
    wi(perm) = wperm;

    % Fallback to direct solver if GMRES fails
    if flag ~= 0
        wi = A\b;
    end

    w = zeros(np,1);
    w(inodes) = wi;

    % =============================
    % NEWTON UPDATE (WITH DAMPING)
    % =============================

    u = u + lam*w;

    % =============================
    % ERROR COMPUTATION
    % =============================

    err = norm(w)/max(norm(u),1e-14);
    err_hist(iterNL) = err;

    % =============================
    % GMRES DIAGNOSTICS
    % =============================

    cond_diagnostic.gmres_flag_last = flag;
    cond_diagnostic.gmres_relres_last = relres;
    cond_diagnostic.gmres_it_last = itTotal;

end

% =============================
% POST-PROCESSING
% =============================

% Trim history arrays
err_hist = err_hist(1:iterNL);
kappa_hist = kappa_hist(1:iterNL);

% Conditioning diagnostics
cond_diagnostic.final_kappa = kappa_hist(end);
cond_diagnostic.max_kappa = max(kappa_hist);

% Convergence warning
if iterNL >= IterMaxNL
    warning('Newton did not converge after %d iterations (err=%e)', IterMaxNL, err);
end

end
