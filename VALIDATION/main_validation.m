%==========================================================================
% MAIN - Batch driver for Richards 3D Newton simulations
% in deformable porous media (Vertisol) - NUMERICAL VALIDATION ONLY
%
% This script runs numerical validation cases directly without GUI.
%
% AUTHOR: Alhadiri MOELEVOU
% ORGANIZATION: Universite Clermont Auvergne - LIMOS
% DATE:   20/02/2026
% VERSION: 2.0 (Newton version)
%==========================================================================

%clear; clc; close all;

% =========================================================================
% SIMULATION PARAMETERS - NUMERICAL VALIDATION
% =========================================================================
case_type = 'numerical_validation';
vertisol_mode = 'deformable';

% Mesh and time parameters
Nx_list = [9, 17];
t_final = 1;

% Time step parameters
dt0 = 0.05;
dt_list = [0.05];

% Newton parameters
lambda_list = [1.00];
lam_Newton = 1.0;

% Solver parameters
test_id = 1;
test_cond = 1;
eps1 = 1e-5;
save_interval = 0.2;

% Fixed parameters
ell = 3;
iso = -0.001;

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
        error('Project root not found when climbing up from: %s', baseDir);
    end
    root = parent;
end

% =========================================================================
% CORE FOLDERS
% =========================================================================
srcDir = fullfile(root, 'src');
FEMDir = fullfile(srcDir, 'FEM');
modelsDir = fullfile(srcDir, 'models');
utilsDir = fullfile(srcDir, 'utils');
solversDir = fullfile(srcDir, 'solvers');
examplesDir = fullfile(root, 'examples');

% Add paths
addpath(genpath(srcDir));
addpath(genpath(examplesDir));
addpath(FEMDir, '-begin');
addpath(utilsDir, '-begin');

% =========================================================================
% MODELS FOLDERS - NUMERICAL VALIDATION
% =========================================================================
vertisolBaseDir = fullfile(modelsDir, 'vertisol');
vanBaseDir = fullfile(modelsDir, 'van');
caseFolder = 'numerical_validation';

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
        
        results_root = fullfile(results_base, case_type, scheme_name, lambda_dir, dt_dir);
        results_dir = fullfile(results_root, 'resultats_complets');
        solutions_dir = fullfile(results_root, 'solutions_temporelles');
        
        if ~exist(results_dir, 'dir'), mkdir(results_dir); end
        if ~exist(solutions_dir, 'dir'), mkdir(solutions_dir); end
        
        fprintf('Folders:\n');
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
            dt_used(i) = dt;
            
            fprintf('\n=== Mesh %d/%d: nx=%d, dt=%.6f, h=%.6f ===\n', ...
                i, length(Nx_list), nx, dt, h);
            fprintf('Ratio dt/h = %.6f\n', dt/h);
            fprintf('Number of time steps: %d\n', N);
            
            % =========================================================
            % 3D MESH + BOUNDARY NODES
            % =========================================================
            [p, tmesh, pbx, pby, pbz] = kpde3dumsh(0, 1, 0, 1, 0, 1, nx, nx, nx);
            x = p(:,1); y = p(:,2); z = p(:,3);
            np = size(p, 1);
            
            pbx = union(pbx(:,1), pbx(:,2));
            pby = union(pby(:,1), pby(:,2));
            pbz = union(pbz(:,1), pbz(:,2));
            ibcd = union(pbx, union(pby, pbz));
            
            fprintf('Nodes: %d, Tetrahedra: %d, Dirichlet nodes: %d\n', ...
                np, size(tmesh, 1), length(ibcd));
            fprintf('Free nodes: %d\n', np - length(ibcd));
            
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
            
            % Snapshots
            it_save = 1;
            ut_partial = u0;
            t_saved_partial = 0;
            
            solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, 0);
            save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u0', 't', 'nx', 'lambda', 'dt');
            
            next_save_time = save_interval;
            
            % =========================================================
            % TIME LOOP
            % =========================================================
            it = 0;
            
            while (t < t_final - 1e-12)
                
                kstep = kstep + 1;
                t = kstep * ht;
                it = kstep;
                
                if t > t_final
                    t = t_final;
                end
                
                [u, n_iter, kappa_hist_step, ~] = ...
                    solveNonLinearNewton(lambda, p, tmesh, 1/dt, ibcd, inodes, ...
                    eps1, t, up, test_id, test_cond);
                
                % Snapshots
                if t >= next_save_time - 1e-12
                    it_save = it_save + 1;
                    ut_partial(:, it_save) = u;
                    t_saved_partial(it_save, 1) = t;
                    
                    solution_file = sprintf('solution_nx%d_t%.3fs.mat', nx, t);
                    save(fullfile(solutions_dir, solution_file), 'p', 'tmesh', 'u', 't', 'nx', 'lambda', 'dt');
                    
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
            
            % =========================================================
            % STORE VISUALIZATION DATA
            % =========================================================
            visualization_data(i).p = p;
            visualization_data(i).t = tmesh;
            visualization_data(i).u = u;
            visualization_data(i).nx = nx;
            visualization_data(i).t_final = t;
            visualization_data(i).X = reshape(p(:,1), nx, nx, nx);
            visualization_data(i).Y = reshape(p(:,2), nx, nx, nx);
            visualization_data(i).Z = reshape(p(:,3), nx, nx, nx);
            visualization_data(i).U = reshape(u, nx, nx, nx);
            visualization_data(i).ut_partial = ut_partial;
            visualization_data(i).t_saved_partial = t_saved_partial;
            visualization_data(i).iso = iso;
            
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
        % TEXT SUMMARY
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