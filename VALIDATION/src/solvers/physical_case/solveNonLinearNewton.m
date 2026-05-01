function [u, iterNL, kappa_hist, cond_diagnostic] = solveNonLinearNewton(lambda, p, t, dt, ibcd, inodes, eps1, time, up, test_id, test_cond)
% Solveur Newton avec GMRES/ILU pour le cas physique
% 
% INPUTS:
%   lambda      - damping parameter
%   p, t        - mesh nodes and elements
%   dt          - time step (inverse of k in original code)
%   ibcd, inodes- boundary and free nodes
%   eps1        - Newton tolerance
%   time        - current time
%   up          - previous time step solution
%   test_id     - test identifier
%   test_cond   - test condition
%
% OUTPUTS:
%   u           - solution
%   iterNL      - number of Newton iterations
%   kappa_hist  - conditioning history
%   cond_diagnostic - structure with convergence diagnostics

np = size(p,1);

% Initialisation
u0 = up;
u0(ibcd) = -5;  % Dirichlet condition
ubcd = u0;

err = 1;
iterNL = 0;
IterMaxNL = 200;
coef = 1;

% Mass matrix
M = kpde3dmass(p, t, 1);
w = zeros(np, 1);

% Historiques
kappa_hist = zeros(1000, 1);
newton_err_history = zeros(1000, 1);
cond_diagnostic = struct();
cap = numel(kappa_hist);

% Paramètres GMRES
tol_gmres = 1e-6;
restart_default = 50;
maxit_total = 500;

opts_ilu.type = 'ilutp';
opts_ilu.droptol = 1e-3;
opts_ilu.udiag = 1;

opts_ichol.type = 'ict';
opts_ichol.michol = 'on';
opts_ichol.droptol = 1e-3;
opts_ichol.diagcomp = 1e-3;

% Stats GMRES
gmres_iter_sum = 0;
gmres_calls = 0;
gmres_iter_history = {};
gmres_flag_history = {};
gmres_relres_history = {};

reuseEvery = 3;
perm = [];
Lpre = [];
Upre = [];

% Initialisation
u = up;
u(ibcd) = -5;
k = 1/dt;  % Pour compatibilité avec le code original

while (err > eps1 && iterNL < IterMaxNL)
    iterNL = iterNL + 1;
    
    newton_err_history(iterNL) = err;

    % Assemblage des matrices (identique au code original)
    Rp = kpde3drgd(p, t, coef.*tgam6(u, time), coef.*tgam6(u, time), coef.*gam6(u, time));
    nux = talpha2(u, p, t) + talpha3(u, p, t);
    nuz = alpha2(u, p, t) + alpha3(u, p, t);
    D = kpde3div(p, t, coef.*nux, coef.*nux, coef.*nuz);
    Ms = kpde3dmass(p, t, coef.*alpha0(u, p, t));

    fh = fex(p(:,1), p(:,2), p(:,3), time, test_id);
    b = kpde3drhs(p, t, coef.*fh);
    b1 = kpde3drhs(p, t, coef.*gam3(u, p, t));
    D0 = kpde3drhs(p, t, coef.*tgam4(u, p, t) + coef.*gam4(u, p, t));

    ru = cp(u).*(u - up);
    cofcondu = (c(u) + ru);
    MC = kpde3dmass(p, t, cofcondu);

    bC = c(u).*(u - up);
    b2 = kpde3drhs(p, t, bC);

    b = b + b1 - Rp*u - D0 - (1/k)*b2;

    % Système linéaire
    A = (1/k)*MC + Ms + Rp + D;

    % Conditions aux limites de Dirichlet
    b = b - A * ubcd;
    b(ibcd) = [];
    A(:, ibcd) = [];
    A(ibcd, :) = [];

    % Conditionnement
    kappa = condest(A);
    if iterNL > cap
        kappa_hist = [kappa_hist; zeros(cap, 1)];
        newton_err_history = [newton_err_history; zeros(cap, 1)];
        cap = numel(kappa_hist);
    end
    kappa_hist(iterNL) = kappa;

    % Solveur GMRES avec préconditionneur
    if isempty(perm) || mod(iterNL - 1, reuseEvery) == 0 || isempty(Lpre)
        perm = amd(A);
        Ap = A(perm, perm);
        bp = b(perm);

        Lpre = [];
        Upre = [];
        try
            [Lpre, Upre] = ilu(Ap, opts_ilu);
        catch
            try
                R = ichol(Ap, opts_ichol);
                Lpre = R;
                Upre = R';
            catch
                Lpre = [];
                Upre = [];
            end
        end
    else
        Ap = A(perm, perm);
        bp = b(perm);
    end

    nA = size(Ap, 1);
    restart = min(restart_default, nA);
    max_outer = ceil(maxit_total / max(1, restart));
    x0 = zeros(size(bp));

    if ~isempty(Lpre)
        [wip, flag, relres, itGM] = gmres(Ap, bp, restart, tol_gmres, max_outer, Lpre, Upre, x0);
    else
        [wip, flag, relres, itGM] = gmres(Ap, bp, restart, tol_gmres, max_outer, [], [], x0);
    end

    if numel(itGM) == 2
        itTotal = itGM(1) * restart + itGM(2);
    else
        itTotal = itGM;
    end

    % Stockage des stats GMRES
    gmres_iter_history{iterNL} = itTotal;
    gmres_flag_history{iterNL} = flag;
    gmres_relres_history{iterNL} = relres;
    gmres_calls = gmres_calls + 1;
    gmres_iter_sum = gmres_iter_sum + max(0, itTotal);

    % Dé-permutation
    if flag ~= 0
        wi = A \ b;
    else
        wi = zeros(size(b));
        wi(perm) = wip;
    end

    % Mise à jour de la solution avec damping
    w(inodes) = wi;
    u = u + lambda .* w;

    % Calcul de l'erreur
    err = sqrt((w' * M * w) / max((u' * M * u), eps));
    
    % Affichage
    fprintf('    Newton it %d: err=%.2e, kappa=%.2e, GMRES it=%d\n', ...
            iterNL, err, kappa, itTotal);
end

% Post-traitement
kappa_hist = kappa_hist(1:iterNL);
newton_err_history = newton_err_history(1:iterNL);

cond_diagnostic.final_kappa = kappa_hist(end);
cond_diagnostic.max_kappa = max(kappa_hist);
cond_diagnostic.mean_kappa = mean(kappa_hist);
cond_diagnostic.newton_err_history = newton_err_history;
cond_diagnostic.newton_iter_total = iterNL;
cond_diagnostic.gmres_calls = gmres_calls;
cond_diagnostic.gmres_it_avg = gmres_iter_sum / max(gmres_calls, 1);
cond_diagnostic.gmres_iter_history = gmres_iter_history;
cond_diagnostic.gmres_flag_history = gmres_flag_history;
cond_diagnostic.gmres_relres_history = gmres_relres_history;

if iterNL >= IterMaxNL
    warning('Non-convergence après %d itérations (err=%e)', IterMaxNL, err);
end

end