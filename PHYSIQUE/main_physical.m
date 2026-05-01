% =========================================================================
% PROJECT ROOT DETECTION AND PATH ADDITION
% =========================================================================
baseDir = fileparts(mfilename('fullpath'));
if isempty(baseDir)
    baseDir = pwd;
end
root = baseDir;

maxUp = 10;
for k = 1:maxUp
    if exist(fullfile(root, 'main.m'), 'file') || isfolder(fullfile(root, 'src'))
        break;
    end
    parent = fileparts(root);
    if strcmp(parent, root)
        warning('Project root not found, using current directory: %s', baseDir);
        root = baseDir;
        break;
    end
    root = parent;
end

% =========================================================================
% PATH ADDITION
% =========================================================================
srcDir = fullfile(root, 'src');
FEMDir = fullfile(srcDir, 'FEM');
modelsDir = fullfile(srcDir, 'models');
utilsDir = fullfile(srcDir, 'utils');
solversDir = fullfile(srcDir, 'solvers');
examplesDir = fullfile(root, 'examples');

% Create folders if they don't exist
if ~exist(examplesDir, 'dir'), mkdir(examplesDir); end
if ~exist(utilsDir, 'dir'), mkdir(utilsDir); end

% Add main paths
addpath(genpath(srcDir));
addpath(FEMDir, '-begin');
addpath(utilsDir, '-begin');

% Add examples folder (contains uex, fex, parameters, solvers)
addpath(examplesDir, '-begin');

fprintf('Project root directory: %s\n', root);
fprintf('Source directory: %s\n', srcDir);
fprintf('FEM directory: %s\n', FEMDir);
fprintf('Examples directory: %s\n', examplesDir);

% =========================================================================
% ESSENTIAL FUNCTIONS CHECK
% =========================================================================
fprintf('\n=== ESSENTIAL FUNCTIONS CHECK ===\n');
functions_check = {'kpde3dumsh', 'kpde3derr_all', 'uex', 'fex', 'solveNonLinearStep'};
for f = 1:length(functions_check)
    if exist(functions_check{f}, 'file')
        fprintf('  ✓ %s -> %s\n', functions_check{f}, which(functions_check{f}));
    else
        fprintf('  ✗ %s NOT FOUND\n', functions_check{f});
    end
end
fprintf('========================================\n\n');

% =========================================================================
% SIMULATION PARAMETERS - PHYSICS
% =========================================================================
case_type = 'physique';
vertisol_mode = 'deformable';

% Mesh and time parameters
Nx_list = [9, 17];
t_final = 1;

% Time step parameters
dt0 = [.25 0.05];
dt_list = [0.05];

% Newton parameters
lambda_list = [0.60 1.00];
lam_Newton = 1.0;

% Solver parameters
test_id = 3;
test_cond = 3;
eps1 = 1e-5;
save_interval = 0.2;

% Fixed parameters
ell = 3;
iso = -0.001;

% If a specific lambda is passed as environment variable
if exist('LAMBDA', 'var') && ~isempty(LAMBDA)
    lambda_list = str2double(LAMBDA);
    fprintf('Specific lambda from variable: %.2f\n', lambda_list);
end

% =========================================================================
% MODELS FOLDERS - PHYSICS
% =========================================================================
vertisolBaseDir = fullfile(modelsDir, 'vertisol');
vanBaseDir = fullfile(modelsDir, 'van');
caseFolder = 'physique';

% Add model paths
addpath(fullfile(vanBaseDir, caseFolder), '-begin');
addpath(fullfile(vertisolBaseDir, caseFolder, vertisol_mode), '-begin');

fprintf('\n================ ACTIVE CONFIGURATION ================\n');
fprintf('Case type: %s\n', case_type);
fprintf('Vertisol mode: %s\n', vertisol_mode);
fprintf('========================================================\n\n');

% =========================================================================
% LOOP PREPARATION
% =========================================================================
if ~isempty(dt_list)
    dt_loop_list = dt_list;
else
    dt_loop_list = dt0;
end

if ~isempty(lambda_list)
    lambda_loop_list = lambda_list;
else
    lambda_loop_list = lam_Newton;
end

% =========================================================================
% MAIN LOOP OVER LAMBDAS AND DT
% =========================================================================
simulation_counter = 0;
all_simulations = struct();

for idx_lambda = 1:length(lambda_loop_list)
    for idx_dt = 1:length(dt_loop_list)
        
        lambda = lambda_loop_list(idx_lambda);
        dt = dt_loop_list(idx_dt);
        
        simulation_counter = simulation_counter + 1;
        
        fprintf('\n========================================');
        fprintf('\n=== SIMULATION %d/%d ===', simulation_counter, length(lambda_loop_list)*length(dt_loop_list));
        fprintf('\n=== lambda = %.2f, dt = %.4f ===', lambda, dt);
        fprintf('\n========================================\n');
        
        % ======================================================================
        % OUTPUT DIRECTORIES
        % ======================================================================
        results_base = 'results';
        scheme_name = 'Newton';
        
        lambda_dir = sprintf('lambda_%.2f', lambda);
        lambda_dir = strrep(lambda_dir, '.', '_');
        
        dt_dir = sprintf('dt_%.4f', dt);
        dt_dir = strrep(dt_dir, '.', '_');
        
        % Structure: results/physique/Newton/lambda_X/dt_Y/
        results_root = fullfile(results_base, case_type, scheme_name, lambda_dir, dt_dir);
        results_dir = fullfile(results_root, 'resultats_complets');
        solutions_dir = fullfile(results_root, 'solutions_temporelles');
        
        if ~exist(results_dir, 'dir'), mkdir(results_dir); end
        if ~exist(solutions_dir, 'dir'), mkdir(solutions_dir); end
        
        fprintf('Folders created:\n');
        fprintf('  - %s\n', results_dir);
        fprintf('  - %s\n', solutions_dir);
        
        % ======================================================================
        % RESULT ARRAYS
        % ======================================================================
        Erreur_L1 = zeros(length(Nx_list), 1);
        Erreur_L2 = zeros(length(Nx_list), 1);
        Erreur_Linf = zeros(length(Nx_list), 1);
        Erreur_H1 = zeros(length(Nx_list), 1);
        
        Newton_iters_last = zeros(length(Nx_list), 1);
        Newton_iters_moyenne = zeros(length(Nx_list), 1);
        CPU_times = zeros(length(Nx_list), 1);
        
        Cond_max = zeros(length(Nx_list), 1);
        Cond_moyen = zeros(length(Nx_list), 1);
        Iter_problematiques = zeros(length(Nx_list), 1);
        
        dt_used = zeros(length(Nx_list), 1);
        
        visualization_data = struct();
        
        % ======================================================================
        % LOOP OVER MESHES
        % ======================================================================
        for i = 1:length(Nx_list)
            
            tic;
            
            nx = Nx_list(i);
            h = 1/(nx - 1);
            
            N = ceil(t_final / dt);
            if N < 1
                N = 1;
            end
            dt_used(i) = dt;
            
            fprintf('\n=== Simulation %d/%d: nx=%d, dt=%.6f, h=%.6f ===\n', ...
                i, length(Nx_list), nx, dt, h);
            fprintf('Ratio dt/h = %.6f\n', dt/h);
            fprintf('Number of time steps: %d\n', N);
            
            % =========================================================
            % 3D MESH + BOUNDARY NODES
            % =========================================================
            [p, tmesh, pbx, pby, pbz] = kpde3dumsh(0, 1, 0, 1, 0, 1, nx, nx, nx);
            x = p(:,1);
            y = p(:,2);
            z = p(:,3);
            np = size(p, 1);
            
            pbx = union(pbx(:,1), pbx(:,2));
            pby = union(pby(:,1), pby(:,2));
            pbz = union(pbz(:,1), pbz(:,2));
            ibcd = union(pbx, union(pby, pbz));
            
            fprintf('Number of nodes: %5d, Number of tetrahedra: %5d\n', size(p, 1), size(tmesh, 1));
            fprintf('Dirichlet nodes: %d, Free nodes: %d\n', length(ibcd), np - length(ibcd));
            
            nodes = (1:np)';
            inodes = setdiff(nodes, ibcd);
            
            % =========================================================
            % INITIALIZATION
            % =========================================================
            t = 0;
            kstep = 0;
            ht = dt;
            
            [u0, ~, ~, ~] = uex(x, y, z, t, test_cond);
            up = u0;
            
            iter_total = 0;
            nsteps = 0;
            
            kappa_history_sim = [];
            
            % Detailed histories
            newton_err_history_all = {};
            newton_iter_history_all = {};
            gmres_iter_history_all = {};
            gmres_flag_history_all = {};
            gmres_relres_history_all = {};
            
            % Snapshots
            it_save = 1;
            ut_partial = u0;
            t_saved_partial = 0;
            
            solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, 0);
            save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u0', 't', 'nx', 'test_id', 'test_cond', 'lambda', 'dt');
            
            next_save_time = save_interval;
            
            % =========================================================
            % TIME LOOP
            % =========================================================
            it = 0;
            
            while (t < t_final - 1e-12)
                
                kstep = kstep + 1;
                t = kstep * ht;
                it = kstep;
                
                if t > t_final + 10 * eps
                    t = t_final;
                end
                
                [u, n_iter, kappa_hist_step, cond_diag_step] = ...
                    solveNonLinearStep(lambda, p, tmesh, dt, ibcd, inodes, eps1, t, up, test_id, test_cond);
                
                % Store GMRES histories
                if isfield(cond_diag_step, 'newton_err_history')
                    newton_err_history_all{it} = cond_diag_step.newton_err_history;
                else
                    newton_err_history_all{it} = [];
                end
                
                newton_iter_history_all{it} = n_iter;
                
                if isfield(cond_diag_step, 'gmres_iter_history')
                    gmres_iter_history_all{it} = cond_diag_step.gmres_iter_history;
                else
                    gmres_iter_history_all{it} = [];
                end
                
                if isfield(cond_diag_step, 'gmres_flag_history')
                    gmres_flag_history_all{it} = cond_diag_step.gmres_flag_history;
                else
                    gmres_flag_history_all{it} = [];
                end
                
                if isfield(cond_diag_step, 'gmres_relres_history')
                    gmres_relres_history_all{it} = cond_diag_step.gmres_relres_history;
                else
                    gmres_relres_history_all{it} = [];
                end
                
                % Display performance
                if ~isempty(gmres_iter_history_all{it}) && iscell(gmres_iter_history_all{it})
                    last_gmres = gmres_iter_history_all{it}{end};
                elseif ~isempty(gmres_iter_history_all{it})
                    last_gmres = gmres_iter_history_all{it}(end);
                else
                    last_gmres = 0;
                end
                fprintf('Step %d | Newton=%d | Last GMRES it=%d\n', it, n_iter, last_gmres);
                
                % Snapshots
                if t >= next_save_time - 1e-12
                    it_save = it_save + 1;
                    ut_partial(:, it_save) = u;
                    t_saved_partial(it_save, 1) = t;
                    
                    solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, t);
                    save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u', 't', 'nx', 'test_id', 'test_cond', 'lambda', 'dt');
                    
                    next_save_time = next_save_time + save_interval;
                end
                
                kappa_history_sim = [kappa_history_sim; kappa_hist_step];
                
                up = u;
                iter_total = iter_total + n_iter;
                nsteps = nsteps + 1;
                
                if mod(it, max(1, floor(N/10))) == 0
                    fprintf('  Time step %d/%d, t=%.3f, Newton iter=%d\n', it, N, t, n_iter);
                end
                
                if it >= N
                    break;
                end
            end
            
            % =========================================================
            % POST-PROCESSING
            % =========================================================
            if ~isempty(kappa_history_sim)
                Cond_max(i) = max(kappa_history_sim);
                Cond_moyen(i) = mean(kappa_history_sim);
                Iter_problematiques(i) = sum(kappa_history_sim > 1e10);
            else
                Cond_max(i) = NaN;
                Cond_moyen(i) = NaN;
                Iter_problematiques(i) = 0;
            end
            
            [eL2, eH1, eL1, eLinf] = kpde3derr_all(p, tmesh, u, t, test_cond);
            
            Erreur_L1(i) = eL1;
            Erreur_L2(i) = eL2;
            Erreur_Linf(i) = eLinf;
            Erreur_H1(i) = eH1;
            
            Newton_iters_last(i) = n_iter;
            Newton_iters_moyenne(i) = iter_total / max(1, nsteps);
            
            CPU_times(i) = toc;
            
            fprintf('\n--- Results for nx=%d ---\n', nx);
            fprintf('  L1 error = %.3e\n', Erreur_L1(i));
            fprintf('  L2 error = %.3e\n', Erreur_L2(i));
            fprintf('  Linf error = %.3e\n', Erreur_Linf(i));
            fprintf('  H1 error = %.3e\n', Erreur_H1(i));
            fprintf('  Newton iterations: last=%d, avg=%.2f\n', Newton_iters_last(i), Newton_iters_moyenne(i));
            fprintf('  CPU time = %.2f s\n', CPU_times(i));
            fprintf('  Conditioning: max=%.3e, mean=%.3e\n', Cond_max(i), Cond_moyen(i));
            fprintf('------------------------\n');
            
            % Store visualization data
            visualization_data(i).p = p;
            visualization_data(i).t = tmesh;
            visualization_data(i).u = u;
            visualization_data(i).nx = nx;
            visualization_data(i).t_final = t;
            visualization_data(i).X = reshape(p(:,1), nx, nx, nx);
            visualization_data(i).Y = reshape(p(:,2), nx, nx, nx);
            visualization_data(i).Z = reshape(p(:,3), nx, nx, nx);
            visualization_data(i).U = reshape(u, nx, nx, nx);
            visualization_data(i).iso = iso;
            visualization_data(i).ut_partial = ut_partial;
            visualization_data(i).t_saved_partial = t_saved_partial;
            visualization_data(i).newton_err_history_all = newton_err_history_all;
            visualization_data(i).newton_iter_history_all = newton_iter_history_all;
            visualization_data(i).gmres_iter_history_all = gmres_iter_history_all;
            visualization_data(i).gmres_flag_history_all = gmres_flag_history_all;
            visualization_data(i).gmres_relres_history_all = gmres_relres_history_all;
            
        end % end loop over meshes
        
        % ======================================================================
        % SAVE COMPLETE RESULTS
        % ======================================================================
        h_values = 1 ./ (Nx_list - 1);
        data_file = fullfile(results_dir, 'resultats_complets.mat');
        
        newton_params = struct('lambda', lambda, 'ell', ell, 'tolerance', eps1);
        
        save(data_file, 'Erreur_L1', 'Erreur_L2', 'Erreur_Linf', 'Erreur_H1', ...
             'Newton_iters_last', 'Newton_iters_moyenne', 'CPU_times', ...
             'Cond_max', 'Cond_moyen', 'Iter_problematiques', 'dt_used', ...
             'Nx_list', 'visualization_data', 'h_values', 'newton_params', ...
             'test_id', 'test_cond', 't_final', 'case_type', 'vertisol_mode', 'dt', 'lambda');
        
        fprintf('\nData saved: %s\n', data_file);
        
        % ======================================================================
        % SAVE TEXT SUMMARY
        % ======================================================================
        summary_file = fullfile(results_dir, 'resume_resultats.txt');
        fid = fopen(summary_file, 'w');
        
        fprintf(fid, 'RESULTS SUMMARY - Newton scheme | case=%s\n', case_type);
        fprintf(fid, 'Date: %s\n', datestr(now));
        fprintf(fid, 'Final time: %.6f\n', t_final);
        fprintf(fid, 'Newton configuration:\n');
        fprintf(fid, '  - Lambda (damping): %.2f\n', lambda);
        fprintf(fid, '  - ell parameter: %d\n', ell);
        fprintf(fid, '  - Nonlinear tolerance: %.1e\n\n', eps1);
        
        fprintf(fid, '%-8s %-10s %-12s %-12s %-12s %-12s %-10s %-10s %-10s\n', ...
            'h', 'dt', 'L1', 'L2', 'Linf', 'H1', 'It.last', 'It.mean', 'CPU(s)');
        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');
        
        for i = 1:length(Nx_list)
            fprintf(fid, '1/%-2d   %-9.4f %-12.3e %-12.3e %-12.3e %-12.3e %-9d %-10.2f %-8.2f\n', ...
                Nx_list(i)-1, dt, Erreur_L1(i), Erreur_L2(i), ...
                Erreur_Linf(i), Erreur_H1(i), Newton_iters_last(i), ...
                Newton_iters_moyenne(i), CPU_times(i));
        end
        
        fprintf(fid, '\n=== NEWTON CONVERGENCE STATISTICS ===\n');
        fprintf(fid, 'Average Newton iterations per time step: %.2f\n', mean(Newton_iters_moyenne));
        fprintf(fid, 'Max Newton iterations in a time step: %d\n', max(Newton_iters_last));
        
        fclose(fid);
        fprintf('Summary saved: %s\n', summary_file);
        
        % Store in global structure
        sim_name = sprintf('lambda_%.2f_dt_%.4f', lambda, dt);
        sim_name = strrep(sim_name, '.', '_');
        
        all_simulations.(sim_name).lambda = lambda;
        all_simulations.(sim_name).dt = dt;
        all_simulations.(sim_name).Nx_list = Nx_list;
        all_simulations.(sim_name).Newton_iters_last = Newton_iters_last;
        all_simulations.(sim_name).Newton_iters_moyenne = Newton_iters_moyenne;
        all_simulations.(sim_name).CPU_times = CPU_times;
        all_simulations.(sim_name).Cond_max = Cond_max;
        all_simulations.(sim_name).Erreur_L1 = Erreur_L1;
        all_simulations.(sim_name).Erreur_L2 = Erreur_L2;
        all_simulations.(sim_name).Erreur_Linf = Erreur_Linf;
        all_simulations.(sim_name).Erreur_H1 = Erreur_H1;
        
    end % end loop over dt
end % end loop over lambda

% ======================================================================
% SAVE ALL SIMULATIONS
% ======================================================================
all_data_file = fullfile('results', case_type, 'Newton', 'toutes_les_simulations.mat');
if ~exist(fileparts(all_data_file), 'dir'), mkdir(fileparts(all_data_file)); end
save(all_data_file, 'all_simulations', 'lambda_loop_list', 'dt_loop_list', 'Nx_list', ...
    'test_id', 'test_cond', 't_final', 'eps1', 'case_type', 'vertisol_mode');

fprintf('\n========================================\n');
fprintf('=== ALL SIMULATIONS COMPLETED ===\n');
fprintf('=== Total simulations: %d ===\n', simulation_counter);
fprintf('========================================\n');

fprintf('\nResults saved in:\n');
fprintf('  results/%s/Newton/lambda_X/dt_Y/\n', case_type);
fprintf('    - resultats_complets/\n');
fprintf('    - solutions_temporelles/\n');
fprintf('\nGlobal data saved in:\n');
fprintf('  %s\n', all_data_file);



%clear; clc; close all;

% % % % % % =========================================================================
% % % % % % DETECTION DE LA RACINE DU PROJET ET AJOUT DES CHEMINS
% % % % % % =========================================================================
% % % % % baseDir = fileparts(mfilename('fullpath'));
% % % % % if isempty(baseDir)
% % % % %     baseDir = pwd;
% % % % % end
% % % % % root = baseDir;
% % % % % 
% % % % % maxUp = 10;
% % % % % for k = 1:maxUp
% % % % %     if exist(fullfile(root, 'main.m'), 'file') || isfolder(fullfile(root, 'src'))
% % % % %         break;
% % % % %     end
% % % % %     parent = fileparts(root);
% % % % %     if strcmp(parent, root)
% % % % %         warning('Dossier racine du projet non trouvé, utilisation du dossier courant: %s', baseDir);
% % % % %         root = baseDir;
% % % % %         break;
% % % % %     end
% % % % %     root = parent;
% % % % % end
% % % % % 
% % % % % % =========================================================================
% % % % % % AJOUT DES CHEMINS
% % % % % % =========================================================================
% % % % % srcDir = fullfile(root, 'src');
% % % % % FEMDir = fullfile(srcDir, 'FEM');
% % % % % modelsDir = fullfile(srcDir, 'models');
% % % % % utilsDir = fullfile(srcDir, 'utils');
% % % % % solversDir = fullfile(srcDir, 'solvers');
% % % % % examplesDir = fullfile(root, 'examples');
% % % % % 
% % % % % % Création des dossiers s'ils n'existent pas
% % % % % if ~exist(examplesDir, 'dir'), mkdir(examplesDir); end
% % % % % if ~exist(utilsDir, 'dir'), mkdir(utilsDir); end
% % % % % 
% % % % % % Ajout des chemins principaux
% % % % % addpath(genpath(srcDir));
% % % % % addpath(FEMDir, '-begin');
% % % % % addpath(utilsDir, '-begin');
% % % % % 
% % % % % % Ajout du dossier examples (contient uex, fex, parameters, solveurs)
% % % % % addpath(examplesDir, '-begin');
% % % % % 
% % % % % fprintf('Dossier racine du projet: %s\n', root);
% % % % % fprintf('Dossier src: %s\n', srcDir);
% % % % % fprintf('Dossier FEM: %s\n', FEMDir);
% % % % % fprintf('Dossier examples: %s\n', examplesDir);
% % % % % 
% % % % % % =========================================================================
% % % % % % VERIFICATION DES FONCTIONS ESSENTIELLES
% % % % % % =========================================================================
% % % % % fprintf('\n=== VERIFICATION DES FONCTIONS ===\n');
% % % % % functions_check = {'kpde3dumsh', 'kpde3derr_all', 'uex', 'fex', 'solveNonLinearStep'};
% % % % % for f = 1:length(functions_check)
% % % % %     if exist(functions_check{f}, 'file')
% % % % %         fprintf('  ✓ %s -> %s\n', functions_check{f}, which(functions_check{f}));
% % % % %     else
% % % % %         fprintf('  ✗ %s NON TROUVE\n', functions_check{f});
% % % % %     end
% % % % % end
% % % % % fprintf('========================================\n\n');
% % % % % 
% % % % % % =========================================================================
% % % % % % PARAMETRES DE LA SIMULATION - PHYSIQUE
% % % % % % =========================================================================
% % % % % case_type = 'physique';  % Changé de 'numerical_validation' à 'physique'
% % % % % vertisol_mode = 'deformable';
% % % % % 
% % % % % % Paramètres de maillage et temps
% % % % % Nx_list = [9, 17];
% % % % % t_final = 1;
% % % % % 
% % % % % % Paramètres de pas de temps
% % % % % dt0 = 0.05;
% % % % % dt_list = [0.05];
% % % % % 
% % % % % % Paramètres de Newton
% % % % % lambda_list = [1.00];
% % % % % lam_Newton = 1.0;
% % % % % 
% % % % % % Paramètres du solveur
% % % % % test_id = 3;  % Changé de 1 à 3
% % % % % test_cond = 3;  % Changé de 1 à 3
% % % % % eps1 = 1e-5;
% % % % % save_interval = 0.2;
% % % % % 
% % % % % % Paramètres fixes
% % % % % ell = 3;
% % % % % iso = -0.001;
% % % % % 
% % % % % % Si un lambda spécifique est passé en variable d'environnement
% % % % % if exist('LAMBDA', 'var') && ~isempty(LAMBDA)
% % % % %     lambda_list = str2double(LAMBDA);
% % % % %     fprintf('Lambda spécifique depuis variable: %.2f\n', lambda_list);
% % % % % end
% % % % % 
% % % % % % =========================================================================
% % % % % % MODELS FOLDERS - PHYSIQUE
% % % % % % =========================================================================
% % % % % vertisolBaseDir = fullfile(modelsDir, 'vertisol');
% % % % % vanBaseDir = fullfile(modelsDir, 'van');
% % % % % caseFolder = 'physique';  % Changé pour correspondre à case_type
% % % % % 
% % % % % % Add model paths
% % % % % addpath(fullfile(vanBaseDir, caseFolder), '-begin');
% % % % % addpath(fullfile(vertisolBaseDir, caseFolder, vertisol_mode), '-begin');
% % % % % 
% % % % % fprintf('\n================ ACTIVE CONFIGURATION ================\n');
% % % % % fprintf('Case type: %s\n', case_type);
% % % % % fprintf('Vertisol mode: %s\n', vertisol_mode);
% % % % % fprintf('========================================================\n\n');
% % % % % 
% % % % % % =========================================================================
% % % % % % PREPARATION DES BOUCLES
% % % % % % =========================================================================
% % % % % if ~isempty(dt_list)
% % % % %     dt_loop_list = dt_list;
% % % % % else
% % % % %     dt_loop_list = dt0;
% % % % % end
% % % % % 
% % % % % if ~isempty(lambda_list)
% % % % %     lambda_loop_list = lambda_list;
% % % % % else
% % % % %     lambda_loop_list = lam_Newton;
% % % % % end
% % % % % 
% % % % % % =========================================================================
% % % % % % BOUCLE PRINCIPALE SUR LES LAMBDAS ET DT
% % % % % % =========================================================================
% % % % % simulation_counter = 0;
% % % % % all_simulations = struct();
% % % % % 
% % % % % for idx_lambda = 1:length(lambda_loop_list)
% % % % %     for idx_dt = 1:length(dt_loop_list)
% % % % % 
% % % % %         lambda = lambda_loop_list(idx_lambda);
% % % % %         dt = dt_loop_list(idx_dt);
% % % % % 
% % % % %         simulation_counter = simulation_counter + 1;
% % % % % 
% % % % %         fprintf('\n========================================');
% % % % %         fprintf('\n=== SIMULATION %d/%d ===', simulation_counter, length(lambda_loop_list)*length(dt_loop_list));
% % % % %         fprintf('\n=== lambda = %.2f, dt = %.4f ===', lambda, dt);
% % % % %         fprintf('\n========================================\n');
% % % % % 
% % % % %         % ======================================================================
% % % % %         % OUTPUT DIRECTORIES - MÊME STRUCTURE QUE LE CODE COURT
% % % % %         % ======================================================================
% % % % %         results_base = 'results';
% % % % %         scheme_name = 'Newton';
% % % % % 
% % % % %         lambda_dir = sprintf('lambda_%.2f', lambda);
% % % % %         lambda_dir = strrep(lambda_dir, '.', '_');
% % % % % 
% % % % %         dt_dir = sprintf('dt_%.4f', dt);
% % % % %         dt_dir = strrep(dt_dir, '.', '_');
% % % % % 
% % % % %         % Structure: results/physique/Newton/lambda_X/dt_Y/
% % % % %         results_root = fullfile(results_base, case_type, scheme_name, lambda_dir, dt_dir);
% % % % %         results_dir = fullfile(results_root, 'resultats_complets');
% % % % %         solutions_dir = fullfile(results_root, 'solutions_temporelles');
% % % % % 
% % % % %         if ~exist(results_dir, 'dir'), mkdir(results_dir); end
% % % % %         if ~exist(solutions_dir, 'dir'), mkdir(solutions_dir); end
% % % % % 
% % % % %         fprintf('Dossiers créés:\n');
% % % % %         fprintf('  - %s\n', results_dir);
% % % % %         fprintf('  - %s\n', solutions_dir);
% % % % % 
% % % % %         % ======================================================================
% % % % %         % TABLEAUX RESULTATS
% % % % %         % ======================================================================
% % % % %         Erreur_L1 = zeros(length(Nx_list), 1);
% % % % %         Erreur_L2 = zeros(length(Nx_list), 1);
% % % % %         Erreur_Linf = zeros(length(Nx_list), 1);
% % % % %         Erreur_H1 = zeros(length(Nx_list), 1);
% % % % % 
% % % % %         Newton_iters_last = zeros(length(Nx_list), 1);
% % % % %         Newton_iters_moyenne = zeros(length(Nx_list), 1);
% % % % %         CPU_times = zeros(length(Nx_list), 1);
% % % % % 
% % % % %         Cond_max = zeros(length(Nx_list), 1);
% % % % %         Cond_moyen = zeros(length(Nx_list), 1);
% % % % %         Iter_problematiques = zeros(length(Nx_list), 1);
% % % % % 
% % % % %         dt_used = zeros(length(Nx_list), 1);
% % % % % 
% % % % %         visualization_data = struct();
% % % % % 
% % % % %         % ======================================================================
% % % % %         % BOUCLE SUR LES MAILLAGES
% % % % %         % ======================================================================
% % % % %         for i = 1:length(Nx_list)
% % % % % 
% % % % %             tic;
% % % % % 
% % % % %             nx = Nx_list(i);
% % % % %             h = 1/(nx - 1);
% % % % % 
% % % % %             N = ceil(t_final / dt);
% % % % %             if N < 1
% % % % %                 N = 1;
% % % % %             end
% % % % %             dt_used(i) = dt;
% % % % % 
% % % % %             fprintf('\n=== Simulation %d/%d: nx=%d, dt=%.6f, h=%.6f ===\n', ...
% % % % %                 i, length(Nx_list), nx, dt, h);
% % % % %             fprintf('Rapport dt/h = %.6f\n', dt/h);
% % % % %             fprintf('Nombre de pas de temps : %d\n', N);
% % % % % 
% % % % %             % =========================================================
% % % % %             % MAILLAGE 3D
% % % % %             % =========================================================
% % % % %             [p, tmesh, pbx, pby, pbz] = kpde3dumsh(0, 1, 0, 1, 0, 1, nx, nx, nx);
% % % % %             x = p(:,1);
% % % % %             y = p(:,2);
% % % % %             z = p(:,3);
% % % % %             np = size(p, 1);
% % % % % 
% % % % %             pbx = union(pbx(:,1), pbx(:,2));
% % % % %             pby = union(pby(:,1), pby(:,2));
% % % % %             pbz = union(pbz(:,1), pbz(:,2));
% % % % %             ibcd = union(pbx, union(pby, pbz));
% % % % % 
% % % % %             fprintf('Nombre de noeuds : %5d et Nombre de tétraèdres : %5d\n', size(p, 1), size(tmesh, 1));
% % % % %             fprintf('Noeuds Dirichlet: %d, Noeuds libres: %d\n', length(ibcd), np - length(ibcd));
% % % % % 
% % % % %             nodes = (1:np)';
% % % % %             inodes = setdiff(nodes, ibcd);
% % % % % 
% % % % %             % =========================================================
% % % % %             % INITIALISATION
% % % % %             % =========================================================
% % % % %             t = 0;
% % % % %             kstep = 0;
% % % % %             ht = dt;
% % % % % 
% % % % %             [u0, ~, ~, ~] = uex(x, y, z, t, test_cond);
% % % % %             up = u0;
% % % % % 
% % % % %             iter_total = 0;
% % % % %             nsteps = 0;
% % % % % 
% % % % %             kappa_history_sim = [];
% % % % % 
% % % % %             % Historiques détaillés
% % % % %             newton_err_history_all = {};
% % % % %             newton_iter_history_all = {};
% % % % %             gmres_iter_history_all = {};
% % % % %             gmres_flag_history_all = {};
% % % % %             gmres_relres_history_all = {};
% % % % % 
% % % % %             % Snapshots
% % % % %             it_save = 1;
% % % % %             ut_partial = u0;
% % % % %             t_saved_partial = 0;
% % % % % 
% % % % %             solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, 0);
% % % % %             save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u0', 't', 'nx', 'test_id', 'test_cond', 'lambda', 'dt');
% % % % % 
% % % % %             next_save_time = save_interval;
% % % % % 
% % % % %             % =========================================================
% % % % %             % BOUCLE TEMPORELLE
% % % % %             % =========================================================
% % % % %             it = 0;
% % % % % 
% % % % %             while (t < t_final - 1e-12)
% % % % % 
% % % % %                 kstep = kstep + 1;
% % % % %                 t = kstep * ht;
% % % % %                 it = kstep;
% % % % % 
% % % % %                 if t > t_final + 10 * eps
% % % % %                     t = t_final;
% % % % %                 end
% % % % % 
% % % % %                 [u, n_iter, kappa_hist_step, cond_diag_step] = ...
% % % % %                     solveNonLinearStep(lambda, p, tmesh, dt, ibcd, inodes, eps1, t, up, test_id, test_cond);
% % % % % 
% % % % %                 % Stockage des historiques GMRES
% % % % %                 if isfield(cond_diag_step, 'newton_err_history')
% % % % %                     newton_err_history_all{it} = cond_diag_step.newton_err_history;
% % % % %                 else
% % % % %                     newton_err_history_all{it} = [];
% % % % %                 end
% % % % % 
% % % % %                 newton_iter_history_all{it} = n_iter;
% % % % % 
% % % % %                 if isfield(cond_diag_step, 'gmres_iter_history')
% % % % %                     gmres_iter_history_all{it} = cond_diag_step.gmres_iter_history;
% % % % %                 else
% % % % %                     gmres_iter_history_all{it} = [];
% % % % %                 end
% % % % % 
% % % % %                 if isfield(cond_diag_step, 'gmres_flag_history')
% % % % %                     gmres_flag_history_all{it} = cond_diag_step.gmres_flag_history;
% % % % %                 else
% % % % %                     gmres_flag_history_all{it} = [];
% % % % %                 end
% % % % % 
% % % % %                 if isfield(cond_diag_step, 'gmres_relres_history')
% % % % %                     gmres_relres_history_all{it} = cond_diag_step.gmres_relres_history;
% % % % %                 else
% % % % %                     gmres_relres_history_all{it} = [];
% % % % %                 end
% % % % % 
% % % % %                 % Affichage des performances
% % % % %                 if ~isempty(gmres_iter_history_all{it}) && iscell(gmres_iter_history_all{it})
% % % % %                     last_gmres = gmres_iter_history_all{it}{end};
% % % % %                 elseif ~isempty(gmres_iter_history_all{it})
% % % % %                     last_gmres = gmres_iter_history_all{it}(end);
% % % % %                 else
% % % % %                     last_gmres = 0;
% % % % %                 end
% % % % %                 fprintf('Step %d | Newton=%d | Dernière it GMRES=%d\n', it, n_iter, last_gmres);
% % % % % 
% % % % %                 % Snapshots
% % % % %                 if t >= next_save_time - 1e-12
% % % % %                     it_save = it_save + 1;
% % % % %                     ut_partial(:, it_save) = u;
% % % % %                     t_saved_partial(it_save, 1) = t;
% % % % % 
% % % % %                     solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, t);
% % % % %                     save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u', 't', 'nx', 'test_id', 'test_cond', 'lambda', 'dt');
% % % % % 
% % % % %                     next_save_time = next_save_time + save_interval;
% % % % %                 end
% % % % % 
% % % % %                 kappa_history_sim = [kappa_history_sim; kappa_hist_step];
% % % % % 
% % % % %                 up = u;
% % % % %                 iter_total = iter_total + n_iter;
% % % % %                 nsteps = nsteps + 1;
% % % % % 
% % % % %                 if mod(it, max(1, floor(N/10))) == 0
% % % % %                     fprintf('  Pas de temps %d/%d, t=%.3f, Newton iter=%d\n', it, N, t, n_iter);
% % % % %                 end
% % % % % 
% % % % %                 if it >= N
% % % % %                     break;
% % % % %                 end
% % % % %             end
% % % % % 
% % % % %             % =========================================================
% % % % %             % POST-TRAITEMENT
% % % % %             % =========================================================
% % % % %             if ~isempty(kappa_history_sim)
% % % % %                 Cond_max(i) = max(kappa_history_sim);
% % % % %                 Cond_moyen(i) = mean(kappa_history_sim);
% % % % %                 Iter_problematiques(i) = sum(kappa_history_sim > 1e10);
% % % % %             else
% % % % %                 Cond_max(i) = NaN;
% % % % %                 Cond_moyen(i) = NaN;
% % % % %                 Iter_problematiques(i) = 0;
% % % % %             end
% % % % % 
% % % % %             [eL2, eH1, eL1, eLinf] = kpde3derr_all(p, tmesh, u, t, test_cond);
% % % % % 
% % % % %             Erreur_L1(i) = eL1;
% % % % %             Erreur_L2(i) = eL2;
% % % % %             Erreur_Linf(i) = eLinf;
% % % % %             Erreur_H1(i) = eH1;
% % % % % 
% % % % %             Newton_iters_last(i) = n_iter;
% % % % %             Newton_iters_moyenne(i) = iter_total / max(1, nsteps);
% % % % % 
% % % % %             CPU_times(i) = toc;
% % % % % 
% % % % %             fprintf('\n--- Résultats pour nx=%d ---\n', nx);
% % % % %             fprintf('  Erreur L1 = %.3e\n', Erreur_L1(i));
% % % % %             fprintf('  Erreur L2 = %.3e\n', Erreur_L2(i));
% % % % %             fprintf('  Erreur Linf = %.3e\n', Erreur_Linf(i));
% % % % %             fprintf('  Erreur H1 = %.3e\n', Erreur_H1(i));
% % % % %             fprintf('  Itérations Newton: dernière=%d, moyenne=%.2f\n', Newton_iters_last(i), Newton_iters_moyenne(i));
% % % % %             fprintf('  Temps CPU = %.2f s\n', CPU_times(i));
% % % % %             fprintf('  Conditionnement: max=%.3e, moyen=%.3e\n', Cond_max(i), Cond_moyen(i));
% % % % %             fprintf('------------------------\n');
% % % % % 
% % % % %             % Stockage des données de visualisation
% % % % %             visualization_data(i).p = p;
% % % % %             visualization_data(i).t = tmesh;
% % % % %             visualization_data(i).u = u;
% % % % %             visualization_data(i).nx = nx;
% % % % %             visualization_data(i).t_final = t;
% % % % %             visualization_data(i).X = reshape(p(:,1), nx, nx, nx);
% % % % %             visualization_data(i).Y = reshape(p(:,2), nx, nx, nx);
% % % % %             visualization_data(i).Z = reshape(p(:,3), nx, nx, nx);
% % % % %             visualization_data(i).U = reshape(u, nx, nx, nx);
% % % % %             visualization_data(i).iso = iso;
% % % % %             visualization_data(i).ut_partial = ut_partial;
% % % % %             visualization_data(i).t_saved_partial = t_saved_partial;
% % % % %             visualization_data(i).newton_err_history_all = newton_err_history_all;
% % % % %             visualization_data(i).newton_iter_history_all = newton_iter_history_all;
% % % % %             visualization_data(i).gmres_iter_history_all = gmres_iter_history_all;
% % % % %             visualization_data(i).gmres_flag_history_all = gmres_flag_history_all;
% % % % %             visualization_data(i).gmres_relres_history_all = gmres_relres_history_all;
% % % % % 
% % % % %         end % fin boucle sur les maillages
% % % % % 
% % % % %         % ======================================================================
% % % % %         % SAUVEGARDE DES RÉSULTATS COMPLETS
% % % % %         % ======================================================================
% % % % %         h_values = 1 ./ (Nx_list - 1);
% % % % %         data_file = fullfile(results_dir, 'resultats_complets.mat');
% % % % % 
% % % % %         newton_params = struct('lambda', lambda, 'ell', ell, 'tolerance', eps1);
% % % % % 
% % % % %         save(data_file, 'Erreur_L1', 'Erreur_L2', 'Erreur_Linf', 'Erreur_H1', ...
% % % % %              'Newton_iters_last', 'Newton_iters_moyenne', 'CPU_times', ...
% % % % %              'Cond_max', 'Cond_moyen', 'Iter_problematiques', 'dt_used', ...
% % % % %              'Nx_list', 'visualization_data', 'h_values', 'newton_params', ...
% % % % %              'test_id', 'test_cond', 't_final', 'case_type', 'vertisol_mode', 'dt', 'lambda');
% % % % % 
% % % % %         fprintf('\nDonnées sauvegardées: %s\n', data_file);
% % % % % 
% % % % %         % ======================================================================
% % % % %         % SAUVEGARDE DU RÉSUMÉ TEXTE
% % % % %         % ======================================================================
% % % % %         summary_file = fullfile(results_dir, 'resume_resultats.txt');
% % % % %         fid = fopen(summary_file, 'w');
% % % % % 
% % % % %         fprintf(fid, 'RÉSUMÉ DES RÉSULTATS - Schéma Newton | cas=%s\n', case_type);
% % % % %         fprintf(fid, 'Date: %s\n', datestr(now));
% % % % %         fprintf(fid, 'Temps final: %.6f\n', t_final);
% % % % %         fprintf(fid, 'Configuration Newton:\n');
% % % % %         fprintf(fid, '  - Lambda (damping): %.2f\n', lambda);
% % % % %         fprintf(fid, '  - Paramètre ell: %d\n', ell);
% % % % %         fprintf(fid, '  - Tolérance non linéaire: %.1e\n\n', eps1);
% % % % % 
% % % % %         fprintf(fid, '%-8s %-10s %-12s %-12s %-12s %-12s %-10s %-10s %-10s\n', ...
% % % % %             'h', 'dt', 'L1', 'L2', 'Linf', 'H1', 'It.last', 'It.moy', 'CPU(s)');
% % % % %         fprintf(fid, '----------------------------------------------------------------------------------------------------\n');
% % % % % 
% % % % %         for i = 1:length(Nx_list)
% % % % %             fprintf(fid, '1/%-2d   %-9.4f %-12.3e %-12.3e %-12.3e %-12.3e %-9d %-10.2f %-8.2f\n', ...
% % % % %                 Nx_list(i)-1, dt, Erreur_L1(i), Erreur_L2(i), ...
% % % % %                 Erreur_Linf(i), Erreur_H1(i), Newton_iters_last(i), ...
% % % % %                 Newton_iters_moyenne(i), CPU_times(i));
% % % % %         end
% % % % % 
% % % % %         fprintf(fid, '\n=== STATISTIQUES DE CONVERGENCE NEWTON ===\n');
% % % % %         fprintf(fid, 'Itérations Newton moyennes par pas de temps: %.2f\n', mean(Newton_iters_moyenne));
% % % % %         fprintf(fid, 'Itérations Newton max sur un pas de temps: %d\n', max(Newton_iters_last));
% % % % % 
% % % % %         fclose(fid);
% % % % %         fprintf('Résumé sauvegardé: %s\n', summary_file);
% % % % % 
% % % % %         % Stockage dans la structure globale
% % % % %         sim_name = sprintf('lambda_%.2f_dt_%.4f', lambda, dt);
% % % % %         sim_name = strrep(sim_name, '.', '_');
% % % % % 
% % % % %         all_simulations.(sim_name).lambda = lambda;
% % % % %         all_simulations.(sim_name).dt = dt;
% % % % %         all_simulations.(sim_name).Nx_list = Nx_list;
% % % % %         all_simulations.(sim_name).Newton_iters_last = Newton_iters_last;
% % % % %         all_simulations.(sim_name).Newton_iters_moyenne = Newton_iters_moyenne;
% % % % %         all_simulations.(sim_name).CPU_times = CPU_times;
% % % % %         all_simulations.(sim_name).Cond_max = Cond_max;
% % % % %         all_simulations.(sim_name).Erreur_L1 = Erreur_L1;
% % % % %         all_simulations.(sim_name).Erreur_L2 = Erreur_L2;
% % % % %         all_simulations.(sim_name).Erreur_Linf = Erreur_Linf;
% % % % %         all_simulations.(sim_name).Erreur_H1 = Erreur_H1;
% % % % % 
% % % % %     end % fin boucle sur dt
% % % % % end % fin boucle sur lambda
% % % % % 
% % % % % % ======================================================================
% % % % % % SAUVEGARDE DE TOUTES LES SIMULATIONS
% % % % % % ======================================================================
% % % % % all_data_file = fullfile('results', case_type, 'Newton', 'toutes_les_simulations.mat');
% % % % % if ~exist(fileparts(all_data_file), 'dir'), mkdir(fileparts(all_data_file)); end
% % % % % save(all_data_file, 'all_simulations', 'lambda_loop_list', 'dt_loop_list', 'Nx_list', ...
% % % % %     'test_id', 'test_cond', 't_final', 'eps1', 'case_type', 'vertisol_mode');
% % % % % 
% % % % % fprintf('\n========================================\n');
% % % % % fprintf('=== TOUTES LES SIMULATIONS SONT TERMINÉES ===\n');
% % % % % fprintf('=== Nombre total de simulations: %d ===\n', simulation_counter);
% % % % % fprintf('========================================\n');
% % % % % 
% % % % % fprintf('\nRésultats sauvegardés dans:\n');
% % % % % fprintf('  results/%s/Newton/lambda_X/dt_Y/\n', case_type);
% % % % % fprintf('    - resultats_complets/\n');
% % % % % fprintf('    - solutions_temporelles/\n');
% % % % % fprintf('\nDonnées globales sauvegardées dans:\n');
% % % % % fprintf('  %s\n', all_data_file);

% clear; clc; close all;
% 
% % =========================================================================
% % DETECTION DE LA RACINE DU PROJET ET AJOUT DES CHEMINS
% % =========================================================================
% baseDir = fileparts(mfilename('fullpath'));
% if isempty(baseDir)
%     baseDir = pwd;
% end
% root = baseDir;
% 
% maxUp = 10;
% for k = 1:maxUp
%     if exist(fullfile(root, 'main.m'), 'file') || isfolder(fullfile(root, 'src'))
%         break;
%     end
%     parent = fileparts(root);
%     if strcmp(parent, root)
%         warning('Dossier racine du projet non trouvé, utilisation du dossier courant: %s', baseDir);
%         root = baseDir;
%         break;
%     end
%     root = parent;
% end
% 
% % =========================================================================
% % AJOUT DES CHEMINS
% % =========================================================================
% srcDir = fullfile(root, 'src');
% FEMDir = fullfile(srcDir, 'FEM');
% modelsDir = fullfile(srcDir, 'models');
% utilsDir = fullfile(srcDir, 'utils');
% solversDir = fullfile(srcDir, 'solvers');
% examplesDir = fullfile(root, 'examples');
% 
% % Création des dossiers s'ils n'existent pas
% if ~exist(examplesDir, 'dir'), mkdir(examplesDir); end
% if ~exist(utilsDir, 'dir'), mkdir(utilsDir); end
% 
% % Ajout des chemins principaux
% addpath(genpath(srcDir));
% addpath(FEMDir, '-begin');
% addpath(utilsDir, '-begin');
% 
% % Ajout du dossier examples (contient uex, fex, parameters, solveurs)
% addpath(examplesDir, '-begin');
% 
% fprintf('Dossier racine du projet: %s\n', root);
% fprintf('Dossier src: %s\n', srcDir);
% fprintf('Dossier FEM: %s\n', FEMDir);
% fprintf('Dossier examples: %s\n', examplesDir);
% 
% % =========================================================================
% % VERIFICATION DES FONCTIONS ESSENTIELLES
% % =========================================================================
% fprintf('\n=== VERIFICATION DES FONCTIONS ===\n');
% functions_check = {'kpde3dumsh', 'kpde3derr_all', 'uex', 'fex', 'solveNonLinearStep'};
% for f = 1:length(functions_check)
%     if exist(functions_check{f}, 'file')
%         fprintf('  ✓ %s -> %s\n', functions_check{f}, which(functions_check{f}));
%     else
%         fprintf('  ✗ %s NON TROUVE\n', functions_check{f});
%     end
% end
% fprintf('========================================\n\n');
% 
% % =========================================================================
% % PARAMETRES INITIAUX
% % =========================================================================
% t_final = 1;
% 
% % Liste des pas de temps
% ell0 = 3;
% dt0 = 0.1 * 2^(1 - ell0);
% dt_list = [0.05];
% 
% % Paramètres fixes
% ell = ell0;
% Nx_list = [9, 17];
% eps1 = 1e-5;
% save_interval = 0.2;
% test_id = 3;
% test_cond = 3;
% iso = -0.001;
% 
% % Valeurs de lambda à tester
% LAMBDA_VALUES = [1.00];
% 
% % Si un lambda spécifique est passé en variable d'environnement
% if exist('LAMBDA', 'var') && ~isempty(LAMBDA)
%     LAMBDA_VALUES = str2double(LAMBDA);
%     fprintf('Lambda spécifique depuis variable: %.2f\n', LAMBDA_VALUES);
% end
% 
% % =========================================================================
% % AFFICHAGE DE LA CONFIGURATION
% % =========================================================================
% fprintf('\n========================================\n');
% fprintf('=== SIMULATION PARALLÈLE ===\n');
% fprintf('=== Nombre de lambdas à tester: %d ===\n', length(LAMBDA_VALUES));
% fprintf('=== PID = %d ===\n', feature('getpid'));
% fprintf('=== Date: %s ===\n', datestr(now));
% fprintf('========================================\n\n');
% 
% fprintf('=== DT_LIST contient %d valeurs ===\n', length(dt_list));
% for idx = 1:length(dt_list)
%     fprintf('  dt(%d) = %.4f\n', idx, dt_list(idx));
% end
% fprintf('========================================\n');
% 
% % =========================================================================
% % BOUCLE PRINCIPALE SUR LES LAMBDAS
% % =========================================================================
% for lambda_idx = 1:length(LAMBDA_VALUES)
% 
%     lambda = LAMBDA_VALUES(lambda_idx);
% 
%     fprintf('\n========================================\n');
%     fprintf('=== LAMBDA = %.2f (%d/%d) ===\n', lambda, lambda_idx, length(LAMBDA_VALUES));
%     fprintf('========================================\n\n');
% 
%     % =========================================================================
%     % BOUCLE SUR LES DT
%     % =========================================================================
%     for idx_dt = 1:length(dt_list)
% 
%         dt = dt_list(idx_dt);
% 
%         fprintf('\n========================================');
%         fprintf('\n=== lambda = %.2f, dt = %.4f (%d/%d) ===', lambda, dt, idx_dt, length(dt_list));
%         fprintf('\n========================================\n');
% 
%         % ======================================================================
%         % DOSSIERS
%         % ======================================================================
%         lambda_dir = sprintf('lambda_%.2f', lambda);
%         lambda_dir = strrep(lambda_dir, '.', '_');
% 
%         dt_dir = sprintf('dt_%.4f', dt);
%         dt_dir = strrep(dt_dir, '.', '_');
% 
%         results_dir = fullfile(lambda_dir, dt_dir, 'resultats_complets');
%         solutions_dir = fullfile(lambda_dir, dt_dir, 'solutions_temporelles');
% 
%         if ~exist(results_dir, 'dir'), mkdir(results_dir); end
%         if ~exist(solutions_dir, 'dir'), mkdir(solutions_dir); end
% 
%         fprintf('Dossiers créés:\n');
%         fprintf('  - %s\n', results_dir);
%         fprintf('  - %s\n', solutions_dir);
% 
%         % ======================================================================
%         % TABLEAUX RESULTATS
%         % ======================================================================
%         Erreur_L1 = zeros(length(Nx_list), 1);
%         Erreur_L2 = zeros(length(Nx_list), 1);
%         Erreur_Linf = zeros(length(Nx_list), 1);
%         Erreur_H1 = zeros(length(Nx_list), 1);
% 
%         Newton_iters_last = zeros(length(Nx_list), 1);
%         Newton_iters_moyenne = zeros(length(Nx_list), 1);
%         CPU_times = zeros(length(Nx_list), 1);
% 
%         Cond_max = zeros(length(Nx_list), 1);
%         Cond_moyen = zeros(length(Nx_list), 1);
%         Iter_problematiques = zeros(length(Nx_list), 1);
% 
%         dt_used = zeros(length(Nx_list), 1);
% 
%         visualization_data = struct();
% 
%         % ======================================================================
%         % BOUCLE SUR LES MAILLAGES
%         % ======================================================================
%         for i = 1:length(Nx_list)
% 
%             tic;
% 
%             nx = Nx_list(i);
%             h = 1/(nx - 1);
% 
%             N = ceil(t_final / dt);
%             if N < 1
%                 N = 1;
%             end
%             dt_used(i) = dt;
% 
%             fprintf('\n=== Simulation %d/%d: nx=%d, dt=%.6f, h=%.6f ===\n', ...
%                 i, length(Nx_list), nx, dt, h);
%             fprintf('Rapport dt/h = %.6f\n', dt/h);
%             fprintf('Nombre de pas de temps : %d\n', N);
% 
%             % =========================================================
%             % MAILLAGE
%             % =========================================================
%             [p, tmesh, pbx, pby, pbz] = kpde3dumsh(0, 1, 0, 1, 0, 1, nx, nx, nx);
%             x = p(:,1);
%             y = p(:,2);
%             z = p(:,3);
%             np = size(p, 1);
% 
%             pbx = union(pbx(:,1), pbx(:,2));
%             pby = union(pby(:,1), pby(:,2));
%             pbz = union(pbz(:,1), pbz(:,2));
%             ibcd = union(pbx, union(pby, pbz));
% 
%             fprintf('Nombre de noeuds : %5d et Nombre de tétraèdres : %5d\n', size(p, 1), size(tmesh, 1));
% 
%             % =========================================================
%             % INITIALISATION
%             % =========================================================
%             t = 0;
%             kstep = 0;
%             ht = dt;
% 
%             [u0, ~, ~, ~] = uex(x, y, z, t, test_cond);
%             up = u0;
% 
%             iter_total = 0;
%             nsteps = 0;
% 
%             kappa_history_sim = [];
% 
%             % Historiques
%             newton_err_history_all = {};
%             newton_iter_history_all = {};
%             gmres_iter_history_all = {};
%             gmres_flag_history_all = {};
%             gmres_relres_history_all = {};
% 
%             % Snapshots
%             it_save = 1;
%             ut_partial = u0;
%             t_saved_partial = 0;
% 
%             solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, 0);
%             save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u0', 't', 'nx', 'test_id', 'test_cond', 'lambda', 'dt');
% 
%             next_save_time = save_interval;
% 
%             % =========================================================
%             % BOUCLE TEMPORELLE
%             % =========================================================
%             it = 0;
%             while (t < t_final - 1e-12)
%                 kstep = kstep + 1;
%                 t = kstep * ht;
%                 it = kstep;
% 
%                 if t > t_final + 10 * eps
%                     t = t_final;
%                 end
% 
%                 nodes = (1:np)';
%                 inodes = setdiff(nodes, ibcd);
% 
%                 [u, n_iter, kappa_hist_step, cond_diag_step] = ...
%                     solveNonLinearStep(lambda, p, tmesh, dt, ibcd, inodes, eps1, t, up, test_id, test_cond);
% 
%                 if isfield(cond_diag_step, 'newton_err_history')
%                     newton_err_history_all{it} = cond_diag_step.newton_err_history;
%                 else
%                     newton_err_history_all{it} = [];
%                 end
% 
%                 newton_iter_history_all{it} = n_iter;
% 
%                 if isfield(cond_diag_step, 'gmres_iter_history')
%                     gmres_iter_history_all{it} = cond_diag_step.gmres_iter_history;
%                 else
%                     gmres_iter_history_all{it} = [];
%                 end
% 
%                 if isfield(cond_diag_step, 'gmres_flag_history')
%                     gmres_flag_history_all{it} = cond_diag_step.gmres_flag_history;
%                 else
%                     gmres_flag_history_all{it} = [];
%                 end
% 
%                 if isfield(cond_diag_step, 'gmres_relres_history')
%                     gmres_relres_history_all{it} = cond_diag_step.gmres_relres_history;
%                 else
%                     gmres_relres_history_all{it} = [];
%                 end
% 
%                 if ~isempty(gmres_iter_history_all{it}) && iscell(gmres_iter_history_all{it})
%                     last_gmres = gmres_iter_history_all{it}{end};
%                 elseif ~isempty(gmres_iter_history_all{it})
%                     last_gmres = gmres_iter_history_all{it}(end);
%                 else
%                     last_gmres = 0;
%                 end
%                 fprintf('Step %d | Newton=%d | Dernière it GMRES=%d\n', it, n_iter, last_gmres);
% 
%                 if t >= next_save_time - 1e-12
%                     it_save = it_save + 1;
%                     ut_partial(:, it_save) = u;
%                     t_saved_partial(it_save, 1) = t;
% 
%                     solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, t);
%                     save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u', 't', 'nx', 'test_id', 'test_cond', 'lambda', 'dt');
% 
%                     next_save_time = next_save_time + save_interval;
%                 end
% 
%                 kappa_history_sim = [kappa_history_sim; kappa_hist_step];
% 
%                 up = u;
%                 iter_total = iter_total + n_iter;
%                 nsteps = nsteps + 1;
% 
%                 if mod(it, max(1, floor(N / 10))) == 0
%                     fprintf('  Pas de temps %d/%d, t=%.3f\n', it, N, t);
%                 end
% 
%                 if it >= N
%                     break;
%                 end
%             end
% 
%             % =========================================================
%             % POST-TRAITEMENT
%             % =========================================================
%             if ~isempty(kappa_history_sim)
%                 Cond_max(i) = max(kappa_history_sim);
%                 Cond_moyen(i) = mean(kappa_history_sim);
%                 Iter_problematiques(i) = sum(kappa_history_sim > 1e10);
%             else
%                 Cond_max(i) = NaN;
%                 Cond_moyen(i) = NaN;
%                 Iter_problematiques(i) = 0;
%             end
% 
%             [eL2, eH1, eL1, eLinf] = kpde3derr_all(p, tmesh, u, t, test_cond);
% 
%             Erreur_L1(i) = eL1;
%             Erreur_L2(i) = eL2;
%             Erreur_Linf(i) = eLinf;
%             Erreur_H1(i) = eH1;
% 
%             Newton_iters_last(i) = n_iter;
%             Newton_iters_moyenne(i) = iter_total / max(1, nsteps);
% 
%             CPU_times(i) = toc;
% 
%             fprintf(['Résultat: h=1/%-2d, dt=%.4f | L1=%.3e | L2=%.3e | Linf=%.3e | ' ...
%                 'H1=%.3e | Newton it (dernier)= %d | CPU=%.2fs | Temps atteint=%.2f\n'], ...
%                 nx - 1, dt, eL1, eL2, eLinf, eH1, n_iter, CPU_times(i), t);
% 
%             fprintf('Conditionnement: max=%.3e, moyen=%.3e, itérations problématiques=%d\n', ...
%                 Cond_max(i), Cond_moyen(i), Iter_problematiques(i));
% 
%             % Stockage visualisation
%             visualization_data(i).p = p;
%             visualization_data(i).t = tmesh;
%             visualization_data(i).u = u;
%             visualization_data(i).nx = nx;
%             visualization_data(i).t_final = t;
%             visualization_data(i).X = reshape(p(:,1), nx, nx, nx);
%             visualization_data(i).Y = reshape(p(:,2), nx, nx, nx);
%             visualization_data(i).Z = reshape(p(:,3), nx, nx, nx);
%             visualization_data(i).U = reshape(u, nx, nx, nx);
%             visualization_data(i).iso = iso;
%             visualization_data(i).ut_partial = ut_partial;
%             visualization_data(i).t_saved_partial = t_saved_partial;
%             visualization_data(i).newton_err_history_all = newton_err_history_all;
%             visualization_data(i).newton_iter_history_all = newton_iter_history_all;
%             visualization_data(i).gmres_iter_history_all = gmres_iter_history_all;
%             visualization_data(i).gmres_flag_history_all = gmres_flag_history_all;
%             visualization_data(i).gmres_relres_history_all = gmres_relres_history_all;
% 
%         end
% 
%         % ======================================================================
%         % SAUVEGARDE
%         % ======================================================================
%         h_values = 1 ./ (Nx_list - 1);
% 
%         data_file = fullfile(results_dir, 'resultats_complets.mat');
%         save(data_file, 'Erreur_L1', 'Erreur_L2', 'Erreur_Linf', 'Erreur_H1', ...
%             'Newton_iters_last', 'Newton_iters_moyenne', 'CPU_times', 'Cond_max', ...
%             'Cond_moyen', 'Iter_problematiques', 'dt_used', 'Nx_list', 'test_id', ...
%             'test_cond', 't_final', 'visualization_data', 'h_values', 'iso', ...
%             'ell0', 'dt0', 'ell', 'lambda', 'dt');
% 
%         fprintf('\nDonnées sauvegardées: %s\n', data_file);
% 
%         % Sauvegarde du résumé
%         summary_file = fullfile(results_dir, 'resume_resultats.txt');
%         fid = fopen(summary_file, 'w');
% 
%         fprintf(fid, 'RÉSUMÉ DES RÉSULTATS - Test %d, Condition %d\n', test_id, test_cond);
%         fprintf(fid, 'lambda = %.4f, dt = %.4f\n', lambda, dt);
%         fprintf(fid, 'Date: %s\n', datestr(now));
%         fprintf(fid, 'Temps final: %.2f\n\n', t_final);
% 
%         fprintf(fid, ['===================================================================================================================================\n' ...
%             'RÉSUMÉ FINAL AVEC ITÉRATIONS NEWTON ET GMRES\n' ...
%             '===================================================================================================================================\n']);
%         fprintf(fid, ['h       dt        L1          L2          Linf        H1          ' ...
%             'It. dernier  It. moy.   CPU (s)   Cond_max     Cond_moy\n']);
%         fprintf(fid, '-----------------------------------------------------------------------------------------------------------------------------------\n');
% 
%         for i = 1:length(Nx_list)
%             if ~isnan(Erreur_L1(i))
%                 fprintf(fid, ['1/%-2d   %-9.4f %-12.3e %-12.3e %-12.3e %-12.3e %-11d %-10.2f ' ...
%                     '%-8.2f %-12.3e %-12.3e\n'], ...
%                     Nx_list(i) - 1, dt_used(i), Erreur_L1(i), Erreur_L2(i), Erreur_Linf(i), Erreur_H1(i), ...
%                     Newton_iters_last(i), Newton_iters_moyenne(i), CPU_times(i), Cond_max(i), Cond_moyen(i));
%             else
%                 fprintf(fid, ['1/%-2d   %-9.4f %-12s %-12s %-12s %-12s %-11s %-10s %-8s %-12s %-12s\n'], ...
%                     Nx_list(i) - 1, dt_used(i), 'NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN', 'NaN');
%             end
%         end
%         fprintf(fid, '===================================================================================================================================\n\n');
% 
%         fclose(fid);
%         fprintf('Résumé sauvegardé: %s\n', summary_file);
%     end
% 
%     fprintf('\n========================================\n');
%     fprintf('=== SIMULATION TERMINÉE POUR lambda = %.2f ===\n', lambda);
%     fprintf('========================================\n');
% end
% 
% fprintf('\n========================================\n');
% fprintf('=== TOUTES LES SIMULATIONS SONT TERMINÉES ===\n');
% fprintf('========================================\n');
% 
