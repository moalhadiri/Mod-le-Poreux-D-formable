function [u, iterNL, kappa_hist, cond_diagnostic, err_hist] = solveNonLinearNewton( ...
    lam,p,t,k,ibcd,inodes,eps1,time,up,test_id,test_cond)

np = size(p,1);

[ue,~,~,~] = uex(p(ibcd,1),p(ibcd,2),p(ibcd,3),time,test_cond);

u = up;
ubcd = zeros(np,1);
ubcd(ibcd) = ue;

% =============================
% PARAMETRES
% =============================

IterMaxNL = 200;
coef = 1;

tol_gmres = 1e-6;
restart = 50;
maxit = 500;

% =============================
% MATRICE MASSE
% =============================

M = kpde3dmass(p,t,1);

% =============================
% HISTORIQUES
% =============================

err_hist = zeros(IterMaxNL,1);
kappa_hist = zeros(IterMaxNL,1);

cond_diagnostic = struct();

% =============================
% PRECONDITIONNEUR
% =============================

ilu_done = false;
perm_done = false;

Lpre = [];
Upre = [];

% =============================
% BOUCLE NEWTON
% =============================

err = 1;
iterNL = 0;

while(err > eps1 && iterNL < IterMaxNL)

    iterNL = iterNL + 1;

    % =============================
    % ASSEMBLAGE (IDENTIQUE)
    % =============================

    Rp = kpde3drgd(p,t,coef.*tgam6(u,t),coef.*tgam6(u,t),coef.*gam6(u,t));

    nux = talpha2(u,p,t) + talpha3(u,p,t);
    nuz = alpha2(u,p,t) + alpha3(u,p,t);

    D = kpde3div(p,t,coef.*nux,coef.*nux,coef.*nuz);

    Ms = kpde3dmass(p,t,coef.*alpha0(u,p,t));

    fh = fex(p(:,1),p(:,2),p(:,3),time,test_id);
    b = kpde3drhs(p,t,coef.*fh);

    b1 = kpde3drhs(p,t,coef.*gam3(u,p,t));

    D0 = kpde3drhs(p,t,coef.*tgam4(u,p,t)+coef.*gam4(u,p,t));

    ru = cp(u).*(u-up);
    cofcondu = (c(u)+ru);

    MC = kpde3dmass(p,t,cofcondu);

    bC = c(u).*(u-up);
    b2 = kpde3drhs(p,t,bC);

    b = b + b1 - Rp*u - D0 - (1/k)*b2;

    % =============================
    % MATRICE
    % =============================

    A = (1/k)*MC + Ms + Rp + D;

    % =============================
    % DIRICHLET
    % =============================

    b = b - A*ubcd;

    b(ibcd) = [];
    A(:,ibcd) = [];
    A(ibcd,:) = [];

    % =============================
    % CONDITIONNEMENT
    % =============================

    if iterNL == 1
        kappa_hist(iterNL) = condest(A);
    else
        kappa_hist(iterNL) = kappa_hist(iterNL-1);
    end

    % =============================
    % PERMUTATION
    % =============================

    if ~perm_done
        perm = symamd(A);
        perm_done = true;
    end

    Aperm = A(perm,perm);
    bperm = b(perm);

    % =============================
    % ILU
    % =============================

    if ~ilu_done
        setup.type = 'ilutp';
        setup.droptol = 1e-3;
        setup.udiag = 1;
        [Lpre,Upre] = ilu(Aperm,setup);
        ilu_done = true;
    end

    % =============================
    % GMRES
    % =============================

    [wperm,flag,relres,iter] = gmres(Aperm,bperm,restart,tol_gmres,maxit,Lpre,Upre);

    if numel(iter)==2
        itTotal = iter(1)*restart + iter(2);
    else
        itTotal = iter;
    end

    % =============================
    % RECONSTRUCTION
    % =============================

    wi = zeros(size(b));
    wi(perm) = wperm;

    if flag ~= 0
        wi = A\b;
    end

    w = zeros(np,1);
    w(inodes) = wi;

    % =============================
    % UPDATE NEWTON (AVEC LAMBDA)
    % =============================

    u = u + lam*w;

    % =============================
    % ERREUR
    % =============================

    err = norm(w)/max(norm(u),1e-14);
    err_hist(iterNL) = err;

    % =============================
    % DIAGNOSTIC GMRES
    % =============================

    cond_diagnostic.gmres_flag_last = flag;
    cond_diagnostic.gmres_relres_last = relres;
    cond_diagnostic.gmres_it_last = itTotal;

end

% =============================
% POST
% =============================

err_hist = err_hist(1:iterNL);
kappa_hist = kappa_hist(1:iterNL);

cond_diagnostic.final_kappa = kappa_hist(end);
cond_diagnostic.max_kappa = max(kappa_hist);

if iterNL >= IterMaxNL
    warning('Newton non convergé');
end

end

% function [u1,iterNL,kappa_hist,cond_diagnostic] = solveNonLinearLscheme( ...
%     L,p,t,k,ibcd,inodes,eps1,time,up,test_id,test_cond)
% %SOLVENONLINEARLSCHEME L-scheme nonlinear solver+preconditioned GMRES linear solve
% % ------------------------------------------------------------
% % L-scheme nonlinear solver+preconditioned GMRES linear solve.
% %
% % Inputs:
% %   ell,L,p,t,k,ibcd,inodes,eps1,time,up,test_id,test_cond
% %
% % Outputs:
% %   u1 : solution at current time step
% %   iterNL : number of nonlinear iterations (L-scheme)
% %   kappa_hist : history of condest(A) (on reduced system)
% %   cond_diagnostic : diagnostics (conditioning+GMRES)
% % ------------------------------------------------------------
% 
% np = size(p,1);
% 
% % Dirichlet at current time
% [ue,~,~,~] = uex(p(:,1),p(:,2),p(:,3),time,test_cond);
% ubcd = ue(ibcd);
% 
% % Mass matrix (constant)
% M = kpde3dmass(p,t,1);
% 
% % Initialization
% u1 = up;
% u  = u1;
% 
% err = 1;
% iterNL = 0;
% IterMaxNL = 5000000000;
% 
% kappa_hist = zeros(1000,1);
% 
% % ============================================================
% % GMRES settings+preconditioner (ILU/ICHOL)
% % ============================================================
% tol_gmres   = 1e-8;
% 
% restart_req = 200;   % <-- what you wanted (will be bounded automatically)
% maxit_total = 2000;  % <-- total GMRES iterations budget (approx)
% 
% % ILU (often better for non-symmetric)
% opts_ilu.type    = 'ilutp';
% opts_ilu.droptol = 1e-3;
% opts_ilu.udiag   = 1;
% 
% % ICHOL fallback
% opts_ichol.type     = 'ict';
% opts_ichol.michol   = 'on';
% opts_ichol.droptol  = 1e-3;
% opts_ichol.diagcomp = 1e-3;
% 
% % Preconditioner reuse
% reuseEvery = 3;
% Lpre = []; Upre = [];
% perm = [];
% 
% % GMRES diagnostics
% gmres_iter_last   = NaN;
% gmres_iter_sum    = 0;
% gmres_calls       = 0;
% gmres_relres_last = NaN;
% gmres_flag_last   = NaN;
% 
% while (err > eps1 && iterNL < IterMaxNL)
%     iterNL = iterNL+1;
% 
%     % ============================================================
%     % L-scheme assembly
%     % ============================================================
%     Rp  = kpde3drgd(p,t,a0(u,t),a0(u,t),a3(u,t));
%     nux = a2(u,p,t);
%     nuz = a4(u,p,t);
%     D   = kpde3div(p,t,nux,nux,nuz);
% 
%     fh     = fex(p(:,1),p(:,2),p(:,3),time,test_id);
%     b      = kpde3drhs(p,t,fh);
%     b1     = kpde3drhs(p,t,a5(u,p,t));
%     b_vg_0 = kpde3drhs(p,t,theta_vg(up));
%     b_vg_1 = kpde3drhs(p,t,theta_vg(u));
% 
%     % RHS/Matrix
%     b = k*b+k*b1+L*M*u+b_vg_0-b_vg_1;
%     A = L*M+k*(Rp+D);
% 
%     % ============================================================
%     % Dirichlet: b <- b-A*ubcd,then reduction
%     % ============================================================
%     ubcd_full = zeros(np,1);
%     ubcd_full(ibcd) = ubcd;
% 
%     b = b-A*ubcd_full;
% 
%     % Dirichlet reduction
%     b(ibcd)   = [];
%     A(:,ibcd) = [];
%     A(ibcd,:) = [];
% 
%     % ============================================================
%     % Conditioning (optional)
%     % ============================================================
%     if iterNL == 1
%         kappa = condest(A);
%     else
%         kappa = kappa_hist(iterNL-1);
%     end
%     if iterNL > numel(kappa_hist)
%         kappa_hist = [kappa_hist; zeros(numel(kappa_hist),1)]; 
%     end
%     kappa_hist(iterNL) = kappa;
% 
%     % ============================================================
%     % Linear solve: GMRES+preconditioner+AMD permutation
%     % ============================================================
%     % AMD permutation
%     if isempty(perm) || mod(iterNL-1,reuseEvery) == 0 || isempty(Lpre)
%         perm = amd(A);
%         Ap   = A(perm,perm);
%         bp   = b(perm);
% 
%         % Preconditioner: ILU then ICHOL fallback
%         Lpre = []; Upre = [];
%         try
%             [Lpre,Upre] = ilu(Ap,opts_ilu);
%         catch
%             try
%                 R = ichol(Ap,opts_ichol);
%                 Lpre = R;
%                 Upre = R';
%             catch
%                 % no preconditioner
%                 Lpre = [];
%                 Upre = [];
%             end
%         end
%     else
%         Ap = A(perm,perm);
%         bp = b(perm);
%     end
% 
%     nA = size(Ap,1);
% 
%     % --- Important fix: restart must be <= nA
%     restart = min(restart_req,nA);
% 
%     % --- Max outer cycles consistent with total budget
%     max_outer = max(1,ceil(maxit_total/restart));
% 
%     x0 = zeros(size(bp));
% 
%     if ~isempty(Lpre)
%         [xperm,flag,relres,itGM] = gmres(Ap,bp,restart,tol_gmres,max_outer,Lpre,Upre,x0);
%     else
%         [xperm,flag,relres,itGM] = gmres(Ap,bp,restart,tol_gmres,max_outer,[],[],x0);
%     end
% 
%     % itGM = [outer inner]
%     if numel(itGM) == 2
%         % total: (outer-1)*restart+inner
%         itTotal = (itGM(1)-1)*restart+itGM(2);
%     else
%         itTotal = itGM;
%     end
% 
%     gmres_calls       = gmres_calls+1;
%     gmres_iter_last   = itTotal;
%     gmres_iter_sum    = gmres_iter_sum+itTotal;
%     gmres_relres_last = relres;
%     gmres_flag_last   = flag;
% 
%     % Inverse permutation
%     ui = zeros(size(b));
%     ui(perm) = xperm;
% 
%     % Safety if GMRES fails
%     if flag ~= 0
%         ui = A\b;
%     end
% 
%     % Reconstruction in u (only inodes are free)
%     u(inodes) = ui;
% 
%     % ============================================================
%     % Stopping criterion (M-weighted relative error)
%     % ============================================================
%     du  = u-u1;
%     err = sqrt((du'*M*du)/max((u1'*M*u1),1e-12));
%     u1  = u;
% end
% 
% kappa_hist = kappa_hist(1:iterNL);
% 
% cond_diagnostic.final_kappa = kappa_hist(end);
% cond_diagnostic.max_kappa   = max(kappa_hist);
% cond_diagnostic.mean_kappa  = mean(kappa_hist);
% 
% cond_diagnostic.gmres_it_last   = gmres_iter_last;
% cond_diagnostic.gmres_it_avg    = gmres_iter_sum/max(gmres_calls,1);
% cond_diagnostic.gmres_relres    = gmres_relres_last;
% cond_diagnostic.gmres_flag_last = gmres_flag_last;
% cond_diagnostic.gmres_calls     = gmres_calls;
% 
% if iterNL >= IterMaxNL
%     warning('Non-convergence after %d iterations (err=%e)',IterMaxNL,err);
% end
% 
% end