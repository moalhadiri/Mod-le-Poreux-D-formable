function [u, iterNL, kappa_hist, cond_diagnostic] = solveNonLinearStep(lambda,p,t,k,ibcd,inodes,eps1,time,up,test_id,test_cond)
% Version avec diagnostic du conditionnement simplifié
% MODIFICATION: Solveur linéaire GMRES avec ILU/ICHOL + stockage historique Newton

np = size(p,1);

% ========= Dirichlet comme dans le premier code : u = uex sur ibcd =========
u0 = up;
u0(ibcd) = -5;
ubcd = u0;

err = 1;
iterNL = 0;
IterMaxNL = 200;
coef = 1;

M = kpde3dmass(p,t,1);
w = zeros(np,1);

% Historiques
kappa_hist = zeros(1000,1);
newton_err_history = zeros(1000,1);  % AJOUT: historique des erreurs Newton
cond_diagnostic = struct();
cap = numel(kappa_hist);

% ============================================================
% AJOUT: Réglages GMRES + préconditionneurs
% ============================================================
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

% Point de départ pour Newton
u = up;
u(ibcd) = -5;

while (err > eps1 && iterNL < IterMaxNL)
    iterNL = iterNL + 1;
    
    % Stockage de l'erreur courante (AJOUT)
    newton_err_history(iterNL) = err;

    % Assemblage (IDENTIQUE)
    Rp = kpde3drgd(p,t,coef.*tgam6(u,t),coef.*tgam6(u,t),coef.*gam6(u,t));
    nux = talpha2(u,p,t) + talpha3(u,p,t);
    nuz = alpha2(u,p,t) + alpha3(u,p,t);
    D = kpde3div(p,t,coef.*nux,coef.*nux,coef.*nuz);
    Ms = kpde3dmass(p,t,coef.*alpha0(u,p,t));

    fh = fex(p(:,1),p(:,2),p(:,3),time,test_id);
    b = kpde3drhs(p,t,coef.*fh);
    b1 = kpde3drhs(p,t,coef.*gam3(u,p,t));
    D0 = kpde3drhs(p,t,coef.*tgam4(u,p,t) + coef.*gam4(u,p,t));

    ru = cp(u).*(u-up);
    cofcondu = (c(u)+ru);
    MC = kpde3dmass(p,t,cofcondu);

    bC = c(u).*(u-up);
    b2 = kpde3drhs(p,t,bC);

    b = b + b1 - Rp*u - D0 - (1/k)*b2;

    % Système linéaire
    A = (1/k)*MC + Ms + Rp + D;

    % CONDITIONS DE BORD
    b = b - A * ubcd;
    b(ibcd) = [];
    A(:,ibcd) = [];
    A(ibcd,:) = [];

    % Conditionnement
    kappa = condest(A);
    if iterNL > cap
        kappa_hist = [kappa_hist; zeros(cap,1)]; %#ok<AGROW>
        newton_err_history = [newton_err_history; zeros(cap,1)]; %#ok<AGROW>
        cap = numel(kappa_hist);
    end
    kappa_hist(iterNL) = kappa;

    % ============================================================
    % Solve linéaire GMRES + ILU/ICHOL
    % ============================================================
    if isempty(perm) || mod(iterNL-1,reuseEvery)==0 || isempty(Lpre)
        perm = amd(A);
        Ap = A(perm,perm);
        bp = b(perm);

        Lpre = []; Upre = [];
        try
            [Lpre,Upre] = ilu(Ap, opts_ilu);
        catch
            try
                R = ichol(Ap, opts_ichol);
                Lpre = R; Upre = R';
            catch
                Lpre = []; Upre = [];
            end
        end
    else
        Ap = A(perm,perm);
        bp = b(perm);
    end

    nA = size(Ap,1);
    restart = min(restart_default, nA);
    max_outer = ceil(maxit_total / max(1,restart));
    x0 = zeros(size(bp));

    if ~isempty(Lpre)
        [wip, flag, relres, itGM] = gmres(Ap, bp, restart, tol_gmres, max_outer, Lpre, Upre, x0);
    else
        [wip, flag, relres, itGM] = gmres(Ap, bp, restart, tol_gmres, max_outer, [], [], x0);
    end

    if numel(itGM)==2
        itTotal = itGM(1)*restart + itGM(2);
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

    % Mise à jour de la solution
    w(inodes) = wi;
   
    u = u + lambda .* w;

    % Calcul de l'erreur (sera stockée au début de la prochaine itération)
    err = sqrt((w' * M * w) / max((u' * M * u), eps));
end

% Post-analysis
kappa_hist = kappa_hist(1:iterNL);
newton_err_history = newton_err_history(1:iterNL);  % AJOUT

cond_diagnostic.final_kappa = kappa_hist(end);
cond_diagnostic.max_kappa = max(kappa_hist);
cond_diagnostic.mean_kappa = mean(kappa_hist);

% AJOUT: Stockage de l'historique Newton
cond_diagnostic.newton_err_history = newton_err_history;
cond_diagnostic.newton_iter_total = iterNL;

% Stats GMRES
cond_diagnostic.gmres_calls = gmres_calls;
cond_diagnostic.gmres_it_avg = gmres_iter_sum / max(gmres_calls,1);
cond_diagnostic.gmres_iter_history = gmres_iter_history;
cond_diagnostic.gmres_flag_history = gmres_flag_history;
cond_diagnostic.gmres_relres_history = gmres_relres_history;

if iterNL >= IterMaxNL
    warning('Non-convergence après %d itérations (err=%e)', IterMaxNL, err);
end

end