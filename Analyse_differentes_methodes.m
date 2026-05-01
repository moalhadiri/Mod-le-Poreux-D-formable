lanceur_resultat_bat()


function charger_resultats_dossier(results_base, dossier_nom)
    % CHARGER_RESULTATS_DOSSIER - Load results from a specific folder
    
    fprintf('\n--- LOADING RESULTS (%s) ---\n', dossier_nom);
    
    if ~exist(results_base, 'dir')
        fprintf('ERROR: Results folder not found: %s\n', results_base);
        fprintf('Please run the main script first in the %s folder\n', dossier_nom);
        return;
    end
    
    % Look for subfolders (numerical_validation or physical_case)
    subdirs = dir(results_base);
    subdirs = subdirs([subdirs.isdir] & ~ismember({subdirs.name}, {'.', '..'}));
    
    if isempty(subdirs)
        fprintf('ERROR: No subfolder found in %s\n', results_base);
        return;
    end
    
    % Display available cases
    fprintf('\nAvailable cases:\n');
    for i = 1:length(subdirs)
        fprintf('%d - %s\n', i, subdirs(i).name);
    end
    
    case_choice = input('Your choice: ');
    if case_choice < 1 || case_choice > length(subdirs)
        fprintf('Invalid choice.\n');
        return;
    end
    
    case_path = fullfile(results_base, subdirs(case_choice).name);
    
    % Look for Newton folder
    newton_path = fullfile(case_path, 'Newton');
    if ~exist(newton_path, 'dir')
        fprintf('ERROR: Newton folder not found: %s\n', newton_path);
        return;
    end
    
    % List lambda folders
    lambda_dirs = dir(fullfile(newton_path, 'lambda_*'));
    lambda_dirs = lambda_dirs([lambda_dirs.isdir]);
    
    if isempty(lambda_dirs)
        fprintf('ERROR: No lambda folder found\n');
        return;
    end
    
    fprintf('\nAvailable lambda values:\n');
    for i = 1:length(lambda_dirs)
        lambda_val = strrep(lambda_dirs(i).name, 'lambda_', '');
        lambda_val = strrep(lambda_val, '_', '.');
        fprintf('%d - lambda = %s\n', i, lambda_val);
    end
    
    lambda_choice = input('Your choice: ');
    if lambda_choice < 1 || lambda_choice > length(lambda_dirs)
        fprintf('Invalid choice.\n');
        return;
    end
    
    lambda_path = fullfile(newton_path, lambda_dirs(lambda_choice).name);
    
    % List dt folders
    dt_dirs = dir(fullfile(lambda_path, 'dt_*'));
    dt_dirs = dt_dirs([dt_dirs.isdir]);
    
    if isempty(dt_dirs)
        fprintf('ERROR: No dt folder found\n');
        return;
    end
    
    fprintf('\nAvailable time steps:\n');
    for i = 1:length(dt_dirs)
        dt_val = strrep(dt_dirs(i).name, 'dt_', '');
        dt_val = strrep(dt_val, '_', '.');
        fprintf('%d - dt = %s\n', i, dt_val);
    end
    
    dt_choice = input('Your choice: ');
    if dt_choice < 1 || dt_choice > length(dt_dirs)
        fprintf('Invalid choice.\n');
        return;
    end
    
    dt_path = fullfile(lambda_path, dt_dirs(dt_choice).name);
    results_dir = fullfile(dt_path, 'resultats_complets');
    solutions_dir = fullfile(dt_path, 'solutions_temporelles');
    
    if ~exist(results_dir, 'dir')
        fprintf('ERROR: resultats_complets folder not found: %s\n', results_dir);
        return;
    end
    
    % Load results file
    data_file = fullfile(results_dir, 'resultats_complets.mat');
    
    if ~exist(data_file, 'file')
        fprintf('ERROR: File not found: %s\n', data_file);
        return;
    end
    
    fprintf('Loading data...\n');
    try
        data = load(data_file);
        lambda_used = strrep(lambda_dirs(lambda_choice).name, 'lambda_', '');
        lambda_used = strrep(lambda_used, '_', '.');
        dt_used = strrep(dt_dirs(dt_choice).name, 'dt_', '');
        dt_used = strrep(dt_used, '_', '.');
        schema_name = sprintf('%s - Newton (lambda=%s, dt=%s)', dossier_nom, lambda_used, dt_used);
        fprintf('Data loaded: %s\n', schema_name);
    catch ME
        fprintf('Error during loading: %s\n', ME.message);
        return;
    end
    
    if ~exist(solutions_dir, 'dir')
        fprintf('Warning: solutions_temporelles folder not found\n');
    else
        fprintf('Solutions folder found\n');
    end
    
    % Launch visualization menu - CHANGE THIS LINE
    fprintf('\n============================================\n');
    fprintf('   VISUALIZATION MENU (%s)\n', schema_name);
    fprintf('============================================\n');
    
    % Use menu_principal_bat instead of menu_principal_visualisation
    menu_principal_bat(solutions_dir, schema_name, data);
    
end
function menu_principal_bat(solutions_dir, schema_name, data)
    % MENU_PRINCIPAL_BAT - Main menu for visualizations
    
    fprintf('\n\n=== VISUALIZATION MENU ===\n');
    
    while true
        fprintf('\nVISUALIZATION OPTIONS (%s):\n', schema_name);
        fprintf('1 - Isosurface at given time\n');
        fprintf('2 - Cross-section at given time\n');
        fprintf('3 - Convergence by mesh\n');
        fprintf('4 - Convergence by mesh (all schemes)\n');
        fprintf('5 - Compare schemes (CPU, iterations, errors, conditioning)\n');
        fprintf('0 - Back\n');
        
        choice = input('Your choice: ');
        
        switch choice
            case 1
                visualisation_isosurface_temps_bat(data, solutions_dir);
            case 2
                visualisation_coupe_temps(data, solutions_dir);
            case 3
                visualiser_convergence_par_maillage(data, schema_name);
            case 4
                visualiser_convergence_par_maillage_avancee();
            case 5
                menu_comparaison_schemes();
            case 0
                fprintf('Back to main menu!\n');
                break;
            otherwise
                fprintf('Invalid choice.\n');
        end
    end
end


function menu_comparaison_schemes()
    % MENU_COMPARAISON_SCHEMES - Menu for scheme comparisons
    
    fprintf('\n\n=== SCHEME COMPARISON MENU ===\n');
    
    while true
        fprintf('\nCOMPARISON OPTIONS:\n');
        fprintf('1 - Compare all schemes (CPU, iterations, errors, conditioning)\n');
        fprintf('2 - Compare CPU time only\n');
        fprintf('3 - Compare iterations only\n');
        fprintf('4 - Compare L2 and H1 errors\n');
        fprintf('5 - Compare conditioning only\n');
        fprintf('6 - Compare iterative convergence (all schemes)\n');
        fprintf('7 - Convergence rate alpha vs tau\n');
        fprintf('0 - Back\n');
        
        choice = input('Your choice: ');
        
        switch choice
            case 1
                comparer_schemes_bat();
            case 2
                comparer_cpu_seulement();
            case 3
                comparer_iterations_seulement();
            case 4
                comparer_erreurs_seulement();
            case 5
                comparer_conditionnement_seulement();
            case 6
                comparer_convergence_iterative_tous_schemes();
            case 7
                visualiser_taux_vs_tau();
            case 0
                fprintf('Back to main menu!\n');
                break;
            otherwise
                fprintf('Invalid choice.\n');
        end
    end
end


function visualiser_convergence_par_maillage_avancee()
    % VISUALISER_CONVERGENCE_PAR_MAILLAGE_AVANCEE
    % Loads results from results/numerical_validation/Newton/ or results/physique/Newton/
    % and displays iterative convergence (first time step)

    fprintf('\n--- Convergence iterative par maillage (tous schemas) ---\n');

    % ==================== PATHS ====================
    base_paths = {};
    
    % Check all possible result locations
    if exist('VALIDATION/results/numerical_validation/Newton', 'dir')
        base_paths{end+1} = 'VALIDATION/results/numerical_validation/Newton';
    end
    if exist('VALIDATION/results/physique/Newton', 'dir')
        base_paths{end+1} = 'VALIDATION/results/physique/Newton';
    end
    if exist('PHYSIQUE/results/numerical_validation/Newton', 'dir')
        base_paths{end+1} = 'PHYSIQUE/results/numerical_validation/Newton';
    end
    if exist('PHYSIQUE/results/physique/Newton', 'dir')
        base_paths{end+1} = 'PHYSIQUE/results/physique/Newton';
    end
    if exist('results/numerical_validation/Newton', 'dir')
        base_paths{end+1} = 'results/numerical_validation/Newton';
    end
    if exist('results/physique/Newton', 'dir')
        base_paths{end+1} = 'results/physique/Newton';
    end
    
    if isempty(base_paths)
        fprintf('ERROR: No results folder found\n');
        return;
    end
    
    % ==================== LOADING ====================
    all_schemes = {};
    scheme_names = {};
    
    for b = 1:length(base_paths)
        base_path = base_paths{b};
        fprintf('Searching in: %s\n', base_path);
        
        lambda_dirs = dir(fullfile(base_path, 'lambda_*'));
        lambda_dirs = lambda_dirs([lambda_dirs.isdir]);
        
        for l = 1:length(lambda_dirs)
            lambda_path = fullfile(base_path, lambda_dirs(l).name);
            dt_dirs = dir(fullfile(lambda_path, 'dt_*'));
            dt_dirs = dt_dirs([dt_dirs.isdir]);
            
            for d = 1:length(dt_dirs)
                dt_path = fullfile(lambda_path, dt_dirs(d).name);
                results_dir = fullfile(dt_path, 'resultats_complets');
                data_file = fullfile(results_dir, 'resultats_complets.mat');
                
                if exist(data_file, 'file')
                    data = load(data_file);
                    lambda_val = strrep(lambda_dirs(l).name, 'lambda_', '');
                    lambda_val = strrep(lambda_val, '_', '.');
                    dt_val = strrep(dt_dirs(d).name, 'dt_', '');
                    dt_val = strrep(dt_val, '_', '.');
                    
                    all_schemes{end+1} = data;
                    % Format with LaTeX symbols
                    scheme_names{end+1} = sprintf('$\\lambda=%s$, $\\Delta t=%s$', lambda_val, dt_val);
                    fprintf('Loaded: lambda=%s, dt=%s\n', lambda_val, dt_val);
                end
            end
        end
    end
    
    if isempty(all_schemes)
        fprintf('ERROR: No scheme found.\n');
        return;
    end
    
    % ==================== COLLECT MESHES ====================
    all_h = [];
    for i = 1:length(all_schemes)
        data = all_schemes{i};
        if isfield(data, 'Nx_list')
            Nx = data.Nx_list(:);
            h_schema = 1 ./ (Nx - 1);
            all_h = [all_h; h_schema(:)];
        end
    end
    
    all_h = unique(round(all_h*1000)/1000);
    all_h = sort(all_h);
    
    if isempty(all_h)
        fprintf('ERROR: No mesh found.\n');
        return;
    end
    
    % ==================== MENU ====================
    fprintf('\nAvailable meshes (h):\n');
    for i = 1:length(all_h)
        fprintf('  %d - h = %.6f (1/%.0f)\n', i, all_h(i), 1/all_h(i));
    end
    
    choice_h = input('\nSelect mesh numbers to display (e.g., 1 3 5) or "all": ', 's');
    
    if strcmpi(choice_h, 'all')
        indices_h = 1:length(all_h);
    else
        indices_h = str2num(choice_h);
    end
    
    if isempty(indices_h)
        indices_h = 1:length(all_h);
    end
    
    selected_h = all_h(indices_h);
    
    % ==================== OPTIONS ====================
    show_coord = input('\nDisplay coordinates? (y/n) [n]: ', 's');
    show_coord = strcmpi(show_coord, 'y');
    
    yaxis_type = input('\nY-axis: 1 log10(error) | 2 raw error [1]: ');
    if isempty(yaxis_type) || yaxis_type == 1
        log_y = true;
        ylabel_str = '$\log_{10}\left(\left\|\psi^{i}_n-\psi_n^{i-1} \right\|\right)$';
    else
        log_y = false;
        ylabel_str = 'Error $||\psi^{i}_n-\psi_n^{i-1}||$';
    end
    
    % ==================== COLLECT CURVES ====================
    curves_data = {};
    all_y = [];
    
    for i = 1:length(all_schemes)
        data = all_schemes{i};
        scheme_name = scheme_names{i};
        
        if ~isfield(data, 'visualization_data')
            fprintf('Warning: No visualization_data for %s\n', scheme_name);
            continue
        end
        
        Nx_list = data.Nx_list(:);
        
        for j = 1:length(data.visualization_data)
            if j > length(Nx_list)
                continue
            end
            
            nx = Nx_list(j);
            h = 1/(nx-1);
            
            if ~ismember(round(h*1000)/1000, round(selected_h*1000)/1000)
                continue
            end
            
            sim = data.visualization_data(j);
            
            err_hist = [];
            
            % Try different possible fields
            if isfield(sim, 'newton_err_history_all') && ~isempty(sim.newton_err_history_all)
                if iscell(sim.newton_err_history_all)
                    for k = 1:length(sim.newton_err_history_all)
                        if ~isempty(sim.newton_err_history_all{k})
                            err_hist = sim.newton_err_history_all{k};
                            break;
                        end
                    end
                else
                    err_hist = sim.newton_err_history_all;
                end
            elseif isfield(sim, 'err_history_all') && ~isempty(sim.err_history_all)
                if iscell(sim.err_history_all)
                    for k = 1:length(sim.err_history_all)
                        if ~isempty(sim.err_history_all{k})
                            err_hist = sim.err_history_all{k};
                            break;
                        end
                    end
                else
                    err_hist = sim.err_history_all;
                end
            elseif isfield(sim, 'newton_iter_history_all') && ~isempty(sim.newton_iter_history_all)
                % If only iteration count is available, create fictive error
                if iscell(sim.newton_iter_history_all)
                    n_iter = sim.newton_iter_history_all{1};
                else
                    n_iter = sim.newton_iter_history_all(1);
                end
                if ~isempty(n_iter) && n_iter > 0
                    err_hist = 10.^(-(1:n_iter)); % Fictive decreasing error
                    fprintf('Warning: Using fictive error for %s (nx=%d)\n', scheme_name, nx);
                end
            end
            
            if isempty(err_hist)
                fprintf('Warning: No error history for %s, nx=%d\n', scheme_name, nx);
                continue
            end
            
            err_hist = err_hist(:);
            
            if min(err_hist) <= 0
                err_hist = err_hist + eps; % Avoid log10 of zero
            end
            
            if log_y
                y_vals = log10(max(err_hist, 1e-16));
            else
                y_vals = err_hist;
            end
            
            if ~all(isnan(y_vals)) && ~all(isinf(y_vals))
                curves_data{end+1} = {y_vals, scheme_name, nx, h};
                all_y = [all_y; y_vals(~isnan(y_vals) & ~isinf(y_vals))];
                fprintf('  Curve added: %s, nx=%d, %d iterations\n', scheme_name, nx, length(y_vals));
            end
        end
    end
    
    if isempty(curves_data)
        fprintf('ERROR: No convergence data found.\n');
        fprintf('       Verify that your files contain newton_err_history_all or err_history_all\n');
        return
    end
    
    % ==================== COLORS ====================
    palette = [
        0, 0.4470, 0.7410;      % blue
        0.8500, 0.3250, 0.0980; % orange
        0.4660, 0.6740, 0.1880; % green
        0.4940, 0.1840, 0.5560; % purple
        0.3010, 0.7450, 0.9330; % cyan
        0.6350, 0.0780, 0.1840; % dark red
        0.9290, 0.6940, 0.1250; % gold
        0, 0.5, 0.5;            % teal
        0.75, 0.75, 0;          % olive
        0.5, 0, 0.5;            % magenta
    ];
    
    % ==================== FIGURE ====================
    if ~isempty(all_y)
        y_min = min(all_y) - 0.1 * abs(min(all_y));
        y_max = max(all_y) + 0.1 * abs(max(all_y));
    else
        y_min = -10;
        y_max = 0;
    end
    
    figure('Position', [100 100 1600 1000], 'Color', 'w');
    hold on;
    
    legend_handles = [];
    legend_names = {};
    
    for k = 1:length(curves_data)
        y_vals = curves_data{k}{1};
        name = curves_data{k}{2};
        nx = curves_data{k}{3};
        
        color = palette(mod(k-1, size(palette,1)) + 1, :);
        
        line_styles = {'-', '--', '-.', ':'};
        markers = {'o', 's', '^', 'd', 'v', '>', '<', 'p', 'h', '*'};
        style = line_styles{mod(k-1, 4) + 1};
        marker = markers{mod(k-1, length(markers)) + 1};
        
        h_plot = plot(1:length(y_vals), y_vals, [marker style], ...
            'LineWidth', 3.5, 'MarkerSize', 8, ...
            'Color', color, 'MarkerFaceColor', color);
        
        legend_handles = [legend_handles, h_plot];
        legend_names{end+1} = sprintf('%s, $h=1/%d$', name, nx-1);
        
        if show_coord
            for j = 1:length(y_vals)
                if j == 1 || j == length(y_vals) || mod(j, 3) == 0
                    text(j, y_vals(j), sprintf('(%.2e)', y_vals(j)), ...
                        'FontSize', 10, 'Color', color, ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'bottom');
                end
            end
        end
    end
    
    xlabel('Iteration', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel(ylabel_str, 'Interpreter', 'latex', 'FontSize', 24, 'FontWeight', 'bold');
    title('Iterative convergence - Newton', 'FontSize', 26, 'FontWeight', 'bold');
    
    if ~isempty(legend_handles)
        legend(legend_handles, legend_names, 'Location', 'best', ...
               'FontSize', 14, 'Interpreter', 'latex', 'Box', 'on');
    end
    
    grid off;
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';
    
    ylim([y_min, y_max]);
    
    max_iter = max(cellfun(@(c) length(c{1}), curves_data));
    xlim([1, max_iter]);
    
    if max_iter <= 10
        xticks(1:1:max_iter);
    elseif max_iter <= 20
        xticks(1:2:max_iter);
    else
        xticks(1:5:max_iter);
    end
    
    fprintf('Figure generated with %d curves.\n', length(curves_data));
    
    % ==================== DIAGNOSTIC ====================
    fprintf('\nDIAGNOSTIC:\n');
    fprintf('  %d schemes loaded\n', length(all_schemes));
    fprintf('  %d curves displayed\n', length(curves_data));
    if length(curves_data) < length(all_schemes)
        fprintf('  Warning: Some schemes have no error history\n');
    end
end
function lanceur_resultat_bat()
% LANCEUR_RESULTAT_BAT - Main launcher for visualizations
% Asks the user which folder to visualize (VALIDATION or PHYSIQUE)

clear; close all; clc;

fprintf('\n======================================================================\n');
fprintf('   RICHARDS 3D VISUALIZATION LAUNCHER\n');
fprintf('======================================================================\n');

while true
    fprintf('\n--- MAIN MENU ---\n');
    fprintf('1. Visualize VALIDATION folder results\n');
    fprintf('2. Visualize PHYSIQUE folder results\n');
    fprintf('3. Exit\n');
    
    folder_choice = input('\nYour choice: ');
    
    switch folder_choice
        case 1
            % VALIDATION folder
            parent_folder = 'VALIDATION';
            if ~exist(parent_folder, 'dir')
                fprintf('ERROR: VALIDATION folder not found: %s\n', parent_folder);
                fprintf('Please check that you are in the correct directory\n');
                continue;
            end
            fprintf('\nVALIDATION folder found\n');
            charger_resultats_dossier(fullfile(parent_folder, 'results'), 'VALIDATION');
            
        case 2
            % PHYSIQUE folder
            parent_folder = 'PHYSIQUE';
            if ~exist(parent_folder, 'dir')
                fprintf('ERROR: PHYSIQUE folder not found: %s\n', parent_folder);
                fprintf('Please check that you are in the correct directory\n');
                continue;
            end
            fprintf('\nPHYSIQUE folder found\n');
            charger_resultats_dossier(fullfile(parent_folder, 'results'), 'PHYSIQUE');
            
        case 3
            fprintf('\n=== GOODBYE ===\n');
            break;
            
        otherwise
            fprintf('Invalid choice.\n');
    end
end
end













function comparer_convergence_iterative_tous_schemes()
    % COMPARER_CONVERGENCE_ITERATIVE_TOUS_SCHEMES
    % Compares iterative convergence (first time step)
    % for Newton, Picard, and all L values in L-scheme/
    % Style: log10(error) with integer Y ticks, no grid

    fprintf('\n--- Iterative convergence: All schemes ---\n');

    % ==================== LOAD NEWTON ====================
    data_newton = [];
    if exist('Newton/resultats_complets/resultats_complets.mat', 'file')
        data_newton = load('Newton/resultats_complets/resultats_complets.mat');
        fprintf('Newton loaded\n');
    else
        fprintf('Newton not found\n');
    end

    % ==================== LOAD PICARD ====================
    data_picard = [];
    if exist('Picard/resultats_complets/resultats_complets.mat', 'file')
        data_picard = load('Picard/resultats_complets/resultats_complets.mat');
        fprintf('Picard loaded\n');
    else
        fprintf('Picard not found\n');
    end

    % ==================== LOAD ALL L-SCHEME ====================
    L_data = {};
    L_names = {};

    if exist('L-scheme', 'dir')
        folders = dir('L-scheme/L=*');
        fprintf('L-scheme folders found: %d\n', length(folders));
        
        for i = 1:length(folders)
            if folders(i).isdir
                file = fullfile('L-scheme', folders(i).name, ...
                                'resultats_complets', 'resultats_complets.mat');
                if exist(file, 'file')
                    L_data{end+1} = load(file);
                    L_names{end+1} = folders(i).name;
                    fprintf('%s loaded\n', folders(i).name);
                else
                    fprintf('%s: file missing\n', folders(i).name);
                end
            end
        end
    else
        fprintf('L-scheme/ folder not found\n');
    end

    % Check that at least one scheme exists
    if isempty(data_newton) && isempty(data_picard) && isempty(L_data)
        fprintf('No data found.\n');
        return;
    end

    % ==================== DETERMINE NUMBER OF AVAILABLE MESHES ====================
    n_meshes_min = inf;
    
    if ~isempty(data_newton) && isfield(data_newton, 'Nx_list')
        n_meshes_min = min(n_meshes_min, length(data_newton.Nx_list));
        fprintf('Newton: %d meshes\n', length(data_newton.Nx_list));
    end
    if ~isempty(data_picard) && isfield(data_picard, 'Nx_list')
        n_meshes_min = min(n_meshes_min, length(data_picard.Nx_list));
        fprintf('Picard: %d meshes\n', length(data_picard.Nx_list));
    end
    for i = 1:length(L_data)
        if isfield(L_data{i}, 'Nx_list')
            n_meshes_min = min(n_meshes_min, length(L_data{i}.Nx_list));
            fprintf('%s: %d meshes\n', L_names{i}, length(L_data{i}.Nx_list));
        end
    end
    
    if n_meshes_min == inf
        fprintf('Unable to determine meshes.\n');
        return;
    end
    
    fprintf('Number of common meshes: %d\n', n_meshes_min);

    % ==================== SELECT MESH ====================
    fprintf('\nAvailable meshes (common to all schemes):\n');
    if ~isempty(data_newton)
        ref_data = data_newton;
    elseif ~isempty(L_data)
        ref_data = L_data{1};
    elseif ~isempty(data_picard)
        ref_data = data_picard;
    else
        return;
    end
    
    for i = 1:n_meshes_min
        fprintf('%d - nx=%d\n', i, ref_data.Nx_list(i));
    end
    
    idx = input(sprintf('Select mesh (1-%d): ', n_meshes_min));
    if isempty(idx) || idx < 1 || idx > n_meshes_min
        fprintf('Invalid choice. Using first mesh.\n');
        idx = 1;
    end
    nx = ref_data.Nx_list(idx);
    fprintf('Selected mesh: nx=%d (index %d)\n', nx, idx);

    % ==================== PREPARE COLORS ====================
    palette = [
        0, 0.4470, 0.7410;      % blue
        0.8500, 0.3250, 0.0980; % orange
        0.4660, 0.6740, 0.1880; % green
        0.4940, 0.1840, 0.5560; % purple
        0.3010, 0.7450, 0.9330; % cyan
        0.6350, 0.0780, 0.1840; % dark red
        0.9290, 0.6940, 0.1250; % gold
        0, 0.5, 0.5;            % teal
        0.75, 0.75, 0;          % olive
        0.5, 0, 0.5;            % magenta
    ];

    % ==================== FUNCTION TO EXTRACT ERROR HISTORY ====================
    function err_hist = extract_error(sim_data)
        err_hist = [];
        if isfield(sim_data, 'newton_err_history_all') && ~isempty(sim_data.newton_err_history_all)
            err_hist = sim_data.newton_err_history_all{1};
        elseif isfield(sim_data, 'err_history_all') && ~isempty(sim_data.err_history_all)
            err_hist = sim_data.err_history_all{1};
        end
    end

    % ==================== COLLECT LOG10 ERRORS FOR Y TICKS ====================
    all_log_err = [];
    log_err_newton = [];
    log_err_picard = [];
    log_err_L = {};

    % Newton
    if ~isempty(data_newton) && isfield(data_newton, 'visualization_data')
        if length(data_newton.visualization_data) >= idx
            sim = data_newton.visualization_data(idx);
            err = extract_error(sim);
            if ~isempty(err)
                log_err_newton = log10(err);
                all_log_err = [all_log_err, log_err_newton];
            end
        end
    end

    % Picard
    if ~isempty(data_picard) && isfield(data_picard, 'visualization_data')
        if length(data_picard.visualization_data) >= idx
            sim = data_picard.visualization_data(idx);
            err = extract_error(sim);
            if ~isempty(err)
                log_err_picard = log10(err);
                all_log_err = [all_log_err, log_err_picard];
            end
        end
    end

    % L-scheme
    for i = 1:length(L_data)
        if length(L_data{i}.visualization_data) >= idx
            sim = L_data{i}.visualization_data(idx);
            err = extract_error(sim);
            if ~isempty(err)
                log_err_L{i} = log10(err);
                all_log_err = [all_log_err, log_err_L{i}];
            end
        end
    end

    % Determine Y limits
    if ~isempty(all_log_err)
        y_min = floor(min(all_log_err)) - 0.5;
        y_max = ceil(max(all_log_err)) + 0.5;
    else
        y_min = -12;
        y_max = 2;
    end

    % ==================== FIGURE 1: log10(ERROR) ====================
    fig1 = figure('Position', [100, 100, 1400, 900], 'Color', 'w');
    hold on;
    legend_handles = [];
    legend_names = {};

    color_idx = 1;

    % ---------- Newton ----------
    if ~isempty(log_err_newton)
        h = plot(1:length(log_err_newton), log_err_newton, 'o-', 'LineWidth', 3, ...
                 'MarkerSize', 8, 'Color', palette(color_idx,:), ...
                 'MarkerFaceColor', palette(color_idx,:));
        legend_handles = [legend_handles, h];
        legend_names{end+1} = 'Newton';
        color_idx = color_idx + 1;
    end

    % ---------- Picard ----------
    if ~isempty(log_err_picard)
        h = plot(1:length(log_err_picard), log_err_picard, 's-', 'LineWidth', 3, ...
                 'MarkerSize', 8, 'Color', palette(color_idx,:), ...
                 'MarkerFaceColor', palette(color_idx,:));
        legend_handles = [legend_handles, h];
        legend_names{end+1} = 'Picard';
        color_idx = color_idx + 1;
    end

    % ---------- L-scheme ----------
    for i = 1:length(L_data)
        if ~isempty(log_err_L{i})
            h = plot(1:length(log_err_L{i}), log_err_L{i}, '^-', 'LineWidth', 3, ...
                     'MarkerSize', 8, 'Color', palette(color_idx,:), ...
                     'MarkerFaceColor', palette(color_idx,:));
            legend_handles = [legend_handles, h];
            legend_names{end+1} = L_names{i};
            color_idx = color_idx + 1;
        end
    end

    % Formatting
    xlabel('Iteration', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel('$\log_{10}(||\mathbf{w}||_M)$', 'Interpreter', 'latex', ...
           'FontSize', 24, 'FontWeight', 'bold');
    title(sprintf('Iterative convergence - nx=%d', nx), ...
          'FontSize', 26, 'FontWeight', 'bold');

    if ~isempty(legend_handles)
        legend(legend_handles, legend_names, 'Location', 'best', 'FontSize', 16);
    end

    grid off;  % NO GRID
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';
    
    % Y limits
    ylim([y_min, y_max]);
    
    % Y ticks: ONLY integers
    y_ticks = ceil(y_min):1:floor(y_max);
    yticks(y_ticks);

    % ==================== FIGURE 2: RATIOS ====================
    fig2 = figure('Position', [1300, 100, 1400, 900], 'Color', 'w');
    hold on;
    legend_handles = [];
    legend_names = {};
    color_idx = 1;

    % Newton (ratios)
    if ~isempty(log_err_newton) && length(log_err_newton) > 1
        ratios = 10.^(log_err_newton(2:end) - log_err_newton(1:end-1));
        h = plot(1:length(ratios), ratios, 'o-', 'LineWidth', 3, ...
             'MarkerSize', 8, 'Color', palette(color_idx,:), ...
             'MarkerFaceColor', palette(color_idx,:));
        legend_handles = [legend_handles, h];
        legend_names{end+1} = 'Newton';
        color_idx = color_idx + 1;
    end

    % Picard (ratios)
    if ~isempty(log_err_picard) && length(log_err_picard) > 1
        ratios = 10.^(log_err_picard(2:end) - log_err_picard(1:end-1));
        h = plot(1:length(ratios), ratios, 's-', 'LineWidth', 3, ...
             'MarkerSize', 8, 'Color', palette(color_idx,:), ...
             'MarkerFaceColor', palette(color_idx,:));
        legend_handles = [legend_handles, h];
        legend_names{end+1} = 'Picard';
        color_idx = color_idx + 1;
    end

    % L-scheme (ratios)
    for i = 1:length(L_data)
        if ~isempty(log_err_L{i}) && length(log_err_L{i}) > 1
            ratios = 10.^(log_err_L{i}(2:end) - log_err_L{i}(1:end-1));
            h = plot(1:length(ratios), ratios, '^-', 'LineWidth', 3, ...
                 'MarkerSize', 8, 'Color', palette(color_idx,:), ...
                 'MarkerFaceColor', palette(color_idx,:));
            legend_handles = [legend_handles, h];
            legend_names{end+1} = L_names{i};
            color_idx = color_idx + 1;
        end
    end

    % Formatting
    xlabel('Iteration', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel('Ratio $e_{j+1}/e_j$', 'Interpreter', 'latex', ...
           'FontSize', 24, 'FontWeight', 'bold');
    title('Convergence rate evolution', 'FontSize', 26, 'FontWeight', 'bold');
    yline(1, '--k', 'LineWidth', 2);

    if ~isempty(legend_handles)
        legend(legend_handles, legend_names, 'Location', 'best', 'FontSize', 16);
    end

    grid off;
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';

    % Optional save
    save_figs = input('\nSave figures? (y/n) [n]: ', 's');
    if strcmpi(save_figs, 'y') || strcmpi(save_figs, 'yes')
        filename1 = sprintf('convergence_iterative_err_nx%d.png', nx);
        filename2 = sprintf('convergence_iterative_ratio_nx%d.png', nx);
        saveas(fig1, filename1);
        saveas(fig2, filename2);
        fprintf('Figures saved:\n   %s\n   %s\n', filename1, filename2);
    end

    fprintf('Two figures generated (log10 error, integer Y ticks).\n');
end



function visualisation_isosurface_temps_bat(data, output_folder)
    
    fprintf('\n--- Isosurface at given time (without box) ---\n');

    % ---------- Select mesh & time ----------
    idx = choisir_maillage(data); if isempty(idx), return; end
    time = choisir_temps(data, idx, output_folder); if isempty(time), return; end

    % ---------- Load data ----------
    [P, Tet, U, tm] = charger_donnees_temps(output_folder, data.Nx_list(idx), time);
    if isempty(P), return; end
    
    % Safety in case tm is empty
    if isempty(tm)
        tm = time;
    end

    % ---------- Basic diagnostics ----------
    fprintf('\nDIAGNOSTIC:\n');
    fprintf('  P: [%.3f,%.3f]x[%.3f,%.3f]x[%.3f,%.3f]\n', ...
        min(P(:,1)),max(P(:,1)), min(P(:,2)),max(P(:,2)), min(P(:,3)),max(P(:,3)));
    fprintf('  U: [%.3e, %.3e]   (#pts=%d)\n', min(U), max(U), numel(U));
    if any(P(:) < 0 | P(:) > 1)
        fprintf('  Warning: Points outside [0,1]^3\n');
    else
        fprintf('  Points inside [0,1]^3\n');
    end

    % ---------- Interpolation grid ----------
    mx = data.Nx_list(idx) + 1;

    if data.Nx_list(idx) == 64
        mx = 65;
    elseif data.Nx_list(idx) == 32
        mx = 33;
    elseif data.Nx_list(idx) == 16
        mx = 17;
    end

    fprintf('  Grid: %dx%dx%d (mx=%d)\n', mx, mx, mx, mx);
    [X, Y, Z] = meshgrid(linspace(0,1,mx), linspace(0,1,mx), linspace(0,1,mx));

    % ---------- Robust interpolation ----------
    Ugrid = [];
    try
        Fint = scatteredInterpolant(P(:,1), P(:,2), P(:,3), U, 'natural', 'none');
        Ugrid = Fint(X, Y, Z);
        fprintf('  Interpolation: natural\n');
    catch
        try
            Ugrid = griddata(P(:,1),P(:,2),P(:,3),U, X,Y,Z, 'linear');
            fprintf('  Interpolation: linear\n');
        catch ME
            fprintf('  Interpolation failed: %s\n', ME.message);
            Ugrid = zeros(size(X));
            fprintf('  Fallback fill (zeros)\n');
        end
    end

    % ---------- NaN cleaning ----------
    nan_mask = isnan(Ugrid);
    if any(nan_mask(:))
        Ugrid(nan_mask) = NaN;
        fprintf('  %d NaN -> min(U)=%.3e\n', nnz(nan_mask), min(U));
    end
    umin = min(Ugrid(:)); umax = max(Ugrid(:));

    % ---------- Isovalue (mid-range by default) ----------
    iso_value = umin + 0.6*(umax - umin);
    fprintf('  ugrid: [%.3e, %.3e], iso=%.3e\n', umin, umax, iso_value);

    % ---------- Build isosurface ----------
    [F,V] = isosurface(X,Y,Z,Ugrid, iso_value);
    if isempty(V)
        fprintf('  No isosurface found for iso=%.3e\n', iso_value);
        return;
    end
    fprintf('  Isosurface: %d faces, %d vertices\n', size(F,1), size(V,1));

    % ================== FIGURE & STYLE ==================
    fig = figure('Units','centimeters', ...
                 'Position',[2 2 16 14], ...
                 'Color','w', ...
                 'Name', sprintf('Isosurface t=%.3f', tm));

    ax = axes('Parent', fig);

    % Axes style
    set(ax, 'FontName','Times New Roman', ...
            'FontSize',23, ...
            'LineWidth',3, ...
            'Box','off', ...
            'TickDir','out', ...
            'TickLabelInterpreter','latex');

    colormap('parula');

    % Clear axes before drawing
    cla(ax);
    
    % Color based on z coordinate
    Cvert = V(:,3);
    cmin  = min(Cvert);
    cmax  = max(Cvert);

    % ========== ONLY THE ISOSURFACE ==========
    % Colored surface with thin black edges
    patch('Faces', F, 'Vertices', V, ...
          'FaceVertexCData', Cvert, ...
          'FaceColor', 'interp', ...
          'EdgeColor', 'k', ...
          'LineWidth', 0.5, ...
          'FaceAlpha', 1.0, ...
          'DisplayName', 'Isosurface');

    % ---------- Force full axes (0,1)^3 ----------
    xlim([0 1]);
    ylim([0 1]);
    zlim([0 1]);

    daspect([1 1 1]);
    view(60, 20);
    axis vis3d;
    axis on; 
    box off;
    grid off;

    % ---------- Lighting & shading ----------
    camlight headlight;
    camlight right;
    lighting gouraud;
    material dull;

    % ---------- Labels ----------
    xlabel('$\mathbf{x}$', ...
        'Interpreter','latex', ...
        'FontSize',28);
    ylabel('$\mathbf{y}$', ...
        'Interpreter','latex', ...
        'FontSize',28);
    zlabel('$\mathbf{z}$', ...
        'Interpreter','latex', ...
        'FontSize',28);

    % ---------- Color bar (colors = z) ----------
    cb = colorbar;
    cb.Label.Interpreter  = 'latex';
    cb.FontSize           = 28;
    cb.Label.FontSize     = 22;
    cb.LineWidth          = 1.4;
    caxis([cmin cmax]);

    % ====== DRAGGABLE PSI TEXT ======
    psiBox = annotation('textbox', ...
        'String', '$\mathbf{\psi}$', ...
        'Interpreter', 'latex', ...
        'FontSize', 35, ...
        'FontWeight', 'bold', ...
        'EdgeColor', 'none', ...
        'Color', 'k', ...
        'Units', 'normalized', ...
        'Position', [0.10 0.80 0.05 0.05], ...
        'FitBoxToText','on');

    % Make draggable if function exists
    if exist('draggable', 'file')
        draggable(psiBox);
    end

    fprintf('Visualization without box generated (full axes [0,1]^3).\n');
end




function draggable(h)
% DRAGGABLE Make an annotation object draggable with mouse
%   draggable(h) makes the annotation object h draggable

    set(h, 'ButtonDownFcn', @startDrag);
    
    function startDrag(src, ~)
        % Get current figure and units
        fig = ancestor(src, 'figure');
        originalUnits = get(fig, 'Units');
        set(fig, 'Units', 'normalized');
        
        % Get initial position and mouse position
        initialPosition = get(src, 'Position');
        currentPoint = get(fig, 'CurrentPoint');
        
        % Calculate offset
        offsetX = initialPosition(1) - currentPoint(1);
        offsetY = initialPosition(2) - currentPoint(2);
        
        % Set callbacks for dragging and stopping
        set(fig, 'WindowButtonMotionFcn', @dragging, ...
                 'WindowButtonUpFcn', @stopDrag);
        
        function dragging(~, ~)
            currentPoint = get(fig, 'CurrentPoint');
            newX = currentPoint(1) + offsetX;
            newY = currentPoint(2) + offsetY;
            
            % Keep within figure bounds [0,1]
            newX = max(0, min(1, newX));
            newY = max(0, min(1, newY));
            
            set(src, 'Position', [newX, newY, initialPosition(3), initialPosition(4)]);
        end
        
        function stopDrag(~, ~)
            set(fig, 'WindowButtonMotionFcn', '', ...
                     'WindowButtonUpFcn', '');
            set(fig, 'Units', originalUnits);
        end
    end
end




function visualisation_coupe_temps(data, output_folder)
    fprintf('\n--- Cross-section at given time ---\n');

    %----------------- 1) SELECT MESH -----------------
    idx = choisir_maillage(data);
    if isempty(idx), return; end
    nx = data.Nx_list(idx);

    %----------------- 2) MAIN MENU -----------------
    fprintf('\nSection type:\n');
    fprintf('1 - Horizontal section (z constant)\n');
    fprintf('2 - Vertical section (x constant)\n');
    fprintf('3 - Vertical section (y constant)\n');
    fprintf('4 - Display ALL sections for ALL times\n');
    fprintf('5 - Visualize deformed geometry (3D)\n');
    section_choice = input('Your choice: ');

    %====================== OPTION 5 ==========================
    %   3D DEFORMED GEOMETRY VISUALIZATION
    %=========================================================
    if section_choice == 5
        fprintf('\n--- 3D DEFORMED GEOMETRY VISUALIZATION ---\n');

        % Select time
        time = choisir_temps(data, idx, output_folder);
        if isempty(time), return; end

        % Load data
        [p, tmesh, u, tm] = charger_donnees_temps(output_folder, nx, time);
        if isempty(p), return; end

        % CHECK u SIZE
        fprintf('\nLoaded data information:\n');
        fprintf('  Number of points (p): %d\n', size(p, 1));
        fprintf('  u size: %d\n', length(u));
        fprintf('  p dimension: %d\n', size(p, 2));

        % Determine if u needs reshaping
        if length(u) == 3 * size(p, 1)
            % u is a column vector: reshape needed
            u_reshaped = reshape(u, [], 3);
            fprintf('  u reshaped to (%d, 3)\n', size(u_reshaped, 1));
        elseif length(u) == size(p, 1) && size(p, 2) == 1
            % u is scalar per point (no x,y,z components)
            fprintf('Warning: u is a scalar field, not a displacement vector.\n');
            fprintf('   Deformation visualization will not be possible.\n');

            % Ask if still want to visualize
            continue_vis = input('Continue with scalar visualization? (y/n) [n]: ', 's');
            if ~strcmpi(continue_vis, 'y') && ~strcmpi(continue_vis, 'yes')
                return;
            end
            u_reshaped = [u, zeros(size(u)), zeros(size(u))]; % Fake 3D
        elseif size(u, 2) == 3 && size(u, 1) == size(p, 1)
            % u is already in (n_points, 3) format
            u_reshaped = u;
            fprintf('  u already in format (%d, 3)\n', size(u_reshaped, 1));
        else
            fprintf('Incompatible size: p(%d,%d) vs u(%d,%d)\n', ...
                    size(p,1), size(p,2), size(u,1), size(u,2));
            fprintf('   Options:\n');
            fprintf('   1 - u is a column vector: expected %d elements\n', 3*size(p,1));
            fprintf('   2 - u is a matrix: expected (%d, 3)\n', size(p,1));
            return;
        end

        % Ask for scale factor
        scale_factor = input('\nScale factor for deformation [100]: ');
        if isempty(scale_factor), scale_factor = 100; end

        % Ask for visualization mode
        fprintf('\nVisualization options:\n');
        fprintf('1 - Full deformed geometry\n');
        fprintf('2 - Section only (choose axis)\n');
        fprintf('3 - Animation over multiple times\n');
        visu_choice = input('Your choice [1]: ');
        if isempty(visu_choice), visu_choice = 1; end

        % Calculate deformed positions
        deformed_positions = p + scale_factor * u_reshaped;

        % Create 3D figure
        fig = figure('Position',[100,100,1400,900], 'Name','3D Deformed Geometry');
        set(gcf,'Renderer','opengl');

        if visu_choice == 1
            % === FULL VISUALIZATION ===
            % Extract tetrahedron connectivity
            if ~isempty(tmesh) && size(tmesh,1) < 10000 % Performance limit
                % Plot tetrahedra (faces only)
                faces = [];
                n_tets = min(1000, size(tmesh,1)); % Limit for performance
                for i = 1:n_tets
                    tet = tmesh(i,:);
                    % Tetrahedron faces
                    faces = [faces; tet([1,2,3]); tet([1,2,4]); tet([1,3,4]); tet([2,3,4])];
                end

                % Plot undeformed geometry (translucent gray)
                subplot(1,2,1);
                tetramesh(tmesh(1:n_tets,:), p, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.2, ...
                         'EdgeColor', 'k', 'EdgeAlpha', 0.1);
                axis equal tight; grid on; view(3);
                xlabel('X','FontSize',12,'FontWeight','bold'); 
                ylabel('Y','FontSize',12,'FontWeight','bold'); 
                zlabel('Z','FontSize',12,'FontWeight','bold');
                title(sprintf('Undeformed (t=%.3f)', tm), 'FontSize', 14, 'FontWeight', 'bold');

                % Plot deformed geometry (color by displacement)
                subplot(1,2,2);
                norm_displacement = sqrt(sum(u_reshaped.^2, 2));

                % Use patch for faces
                patch('Faces', faces, 'Vertices', deformed_positions, ...
                      'FaceVertexCData', norm_displacement, ...
                      'FaceColor', 'interp', 'EdgeColor', 'k', 'EdgeAlpha', 0.1, ...
                      'FaceAlpha', 0.8);

                axis equal tight; grid on; view(3);
                xlabel('X','FontSize',12,'FontWeight','bold'); 
                ylabel('Y','FontSize',12,'FontWeight','bold'); 
                zlabel('Z','FontSize',12,'FontWeight','bold');
                title(sprintf('Deformed x %d (t=%.3f)', scale_factor, tm), ...
                      'FontSize', 14, 'FontWeight', 'bold');

                % Add colorbar for amplitude
                cb = colorbar;
                cb.Label.String = 'Displacement amplitude';
                cb.Label.FontSize = 11;
                cb.Label.FontWeight = 'bold';
                colormap(jet);

            else
                % If no connectivity or too many tetrahedra, just plot points
                subplot(1,2,1);
                scatter3(p(:,1), p(:,2), p(:,3), 10, 'b', 'filled', 'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0.3);
                axis equal tight; grid on; view(3);
                xlabel('X','FontSize',12,'FontWeight','bold'); 
                ylabel('Y','FontSize',12,'FontWeight','bold'); 
                zlabel('Z','FontSize',12,'FontWeight','bold');
                title(sprintf('Undeformed (t=%.3f)', tm), 'FontSize', 14, 'FontWeight', 'bold');

                subplot(1,2,2);
                norm_displacement = sqrt(sum(u_reshaped.^2, 2));
                scatter3(deformed_positions(:,1), deformed_positions(:,2), ...
                        deformed_positions(:,3), 20, norm_displacement, 'filled', ...
                        'MarkerEdgeColor', 'k', 'MarkerEdgeAlpha', 0.1);
                axis equal tight; grid on; view(3);
                xlabel('X','FontSize',12,'FontWeight','bold'); 
                ylabel('Y','FontSize',12,'FontWeight','bold'); 
                zlabel('Z','FontSize',12,'FontWeight','bold');
                title(sprintf('Deformed x %d (t=%.3f)', scale_factor, tm), ...
                      'FontSize', 14, 'FontWeight', 'bold');

                cb = colorbar;
                cb.Label.String = 'Displacement amplitude';
                cb.Label.FontSize = 11;
                cb.Label.FontWeight = 'bold';
                colormap(jet);
            end

        elseif visu_choice == 2
            % === SECTION ONLY ===
            fprintf('\nSelect section axis:\n');
            fprintf('1 - Plane X = constant\n');
            fprintf('2 - Plane Y = constant\n');
            fprintf('3 - Plane Z = constant\n');
            axis_choice = input('Your choice [1]: ');
            if isempty(axis_choice), axis_choice = 1; end

            % Section value
            cut_val = input('Section value (0-1) [0.5]: ');
            if isempty(cut_val), cut_val = 0.5; end

            % Select points near section plane
            tolerance = 0.02;

            switch axis_choice
                case 1  % X = constant
                    idx_cut = abs(p(:,1) - cut_val) < tolerance;
                    xlabel_str = 'Y'; ylabel_str = 'Z';
                    coords_undef = [p(idx_cut,2), p(idx_cut,3)];
                    coords_def = [deformed_positions(idx_cut,2), deformed_positions(idx_cut,3)];
                    plane_str = sprintf('X = %.2f', cut_val);

                case 2  % Y = constant
                    idx_cut = abs(p(:,2) - cut_val) < tolerance;
                    xlabel_str = 'X'; ylabel_str = 'Z';
                    coords_undef = [p(idx_cut,1), p(idx_cut,3)];
                    coords_def = [deformed_positions(idx_cut,1), deformed_positions(idx_cut,3)];
                    plane_str = sprintf('Y = %.2f', cut_val);

                case 3  % Z = constant
                    idx_cut = abs(p(:,3) - cut_val) < tolerance;
                    xlabel_str = 'X'; ylabel_str = 'Y';
                    coords_undef = [p(idx_cut,1), p(idx_cut,2)];
                    coords_def = [deformed_positions(idx_cut,1), deformed_positions(idx_cut,2)];
                    plane_str = sprintf('Z = %.2f', cut_val);
            end

            % Check if we have points
            if sum(idx_cut) < 10
                fprintf('Too few points in section (tolerance %.3f).\n', tolerance);
                fprintf('Try with larger tolerance.\n');
                tolerance = input('New tolerance [0.1]: ');
                if isempty(tolerance), tolerance = 0.1; end
                % Recalculate with new tolerance
                switch axis_choice
                    case 1, idx_cut = abs(p(:,1) - cut_val) < tolerance;
                    case 2, idx_cut = abs(p(:,2) - cut_val) < tolerance;
                    case 3, idx_cut = abs(p(:,3) - cut_val) < tolerance;
                end
            end

            % Displacement norm for section points
            norm_cut = sqrt(sum(u_reshaped(idx_cut,:).^2, 2));

            % Plot
            subplot(1,2,1);
            scatter(coords_undef(:,1), coords_undef(:,2), 30, 'b', 'filled', ...
                   'MarkerEdgeColor', 'k');
            axis equal tight; grid on; box on;
            xlabel(xlabel_str, 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(ylabel_str, 'FontSize', 12, 'FontWeight', 'bold');
            title({sprintf('Undeformed section (t=%.3f)', tm), plane_str}, ...
                  'FontSize', 12, 'FontWeight', 'bold');

            subplot(1,2,2);
            scatter(coords_def(:,1), coords_def(:,2), 30, norm_cut, 'filled', ...
                   'MarkerEdgeColor', 'k');
            axis equal tight; grid on; box on;
            xlabel(xlabel_str, 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(ylabel_str, 'FontSize', 12, 'FontWeight', 'bold');
            title({sprintf('Deformed section x %d (t=%.3f)', scale_factor, tm), plane_str}, ...
                  'FontSize', 12, 'FontWeight', 'bold');

            cb = colorbar;
            cb.Label.String = 'Displacement amplitude';
            cb.Label.FontSize = 11;
            cb.Label.FontWeight = 'bold';
            colormap(jet);

        elseif visu_choice == 3
            % === ANIMATION OVER MULTIPLE TIMES ===
            fprintf('\n--- DEFORMATION ANIMATION ---\n');

            % List all time files for this mesh
            pattern = sprintf('solution_nx%d_t*.mat', nx);
            files = dir(fullfile(output_folder, pattern));

            if length(files) < 2
                fprintf('Not enough files for animation.\n');
                return;
            end

            % Extract and sort times
            t_list = zeros(length(files), 1);
            for k = 1:length(files)
                tok = regexp(files(k).name, 't([0-9\.]+)s', 'tokens', 'once');
                t_list(k) = str2double(tok{1});
            end
            [t_list, idx_sort] = sort(t_list);
            files = files(idx_sort);

            fprintf('Available times: ');
            fprintf('%.3f ', t_list);
            fprintf('\n');

            % Animation mode choice
            fprintf('\nAnimation mode:\n');
            fprintf('1 - Full loop\n');
            fprintf('2 - Specific sequence\n');
            anim_mode = input('Your choice [1]: ');
            if isempty(anim_mode), anim_mode = 1; end

            if anim_mode == 2
                fprintf('Start and end indices (1-%d)\n', length(files));
                idx_start = input(sprintf('Start [1]: '));
                if isempty(idx_start), idx_start = 1; end
                idx_end = input(sprintf('End [%d]: ', length(files)));
                if isempty(idx_end), idx_end = length(files); end
                files = files(idx_start:idx_end);
                t_list = t_list(idx_start:idx_end);
            end

            % Prepare animation
            figure('Position',[100,100,1200,600]);

            for k = 1:length(files)
                % Load data for this time
                file_path = fullfile(output_folder, files(k).name);
                S = load(file_path);

                p_current = S.p;
                if isfield(S, 'u')
                    u_current = S.u;
                elseif isfield(S, 'u0')
                    u_current = S.u0;
                else
                    fprintf('No u variable in %s\n', files(k).name);
                    continue;
                end

                t_current = t_list(k);

                % Reshape u_current
                if length(u_current) == 3 * size(p_current, 1)
                    u_reshaped_current = reshape(u_current, [], 3);
                elseif size(u_current, 2) == 3 && size(u_current, 1) == size(p_current, 1)
                    u_reshaped_current = u_current;
                else
                    fprintf('Incompatible size for t=%.3f\n', t_current);
                    continue;
                end

                % Calculate deformed positions
                deformed_positions_current = p_current + scale_factor * u_reshaped_current;
                norm_displacement = sqrt(sum(u_reshaped_current.^2, 2));

                % Plot
                clf;

                subplot(1,2,1);
                scatter3(p_current(:,1), p_current(:,2), p_current(:,3), 10, 'b', 'filled');
                axis equal tight; grid on; view(3);
                xlabel('X'); ylabel('Y'); zlabel('Z');
                title(sprintf('Undeformed (t=%.3f)', t_current));

                subplot(1,2,2);
                scatter3(deformed_positions_current(:,1), deformed_positions_current(:,2), ...
                        deformed_positions_current(:,3), 20, norm_displacement, 'filled');
                axis equal tight; grid on; view(3);
                xlabel('X'); ylabel('Y'); zlabel('Z');
                title(sprintf('Deformed x %d (t=%.3f)', scale_factor, t_current));

                colormap(jet);
                colorbar;

                % Pause for animation
                pause(0.1);

                % Option to save each frame
                if input('Save this frame? (y/n) [n]: ', 's') == 'y'
                    frame_name = sprintf('frame_nx%d_t%.3f.png', nx, t_current);
                    saveas(gcf, fullfile(output_folder, frame_name));
                    fprintf('Frame saved: %s\n', frame_name);
                end
            end
        end

        % Scale information
        fprintf('\n===========================================\n');
        fprintf('VISUALIZATION INFORMATION:\n');
        fprintf('Applied scale factor: %d\n', scale_factor);
        fprintf('Original max displacement: %.3e\n', max(sqrt(sum(u_reshaped.^2, 2))));
        fprintf('Visualized max displacement: %.3e\n', max(sqrt(sum((scale_factor*u_reshaped).^2, 2))));
        fprintf('Number of points: %d\n', size(p,1));
        fprintf('Original u size: %d elements\n', length(u));
        if exist('tmesh', 'var') && ~isempty(tmesh)
            fprintf('Number of elements: %d\n', size(tmesh,1));
        end
        fprintf('===========================================\n\n');

        % Option to save figure
        save_fig = input('\nSave figure? (y/n) [n]: ', 's');
        if strcmpi(save_fig, 'y') || strcmpi(save_fig, 'yes')
            filename = sprintf('deformation_nx%d_t%.3f_scale%d.png', nx, tm, scale_factor);
            saveas(gcf, fullfile(output_folder, filename));
            fprintf('Figure saved: %s\n', filename);
        end

        % Option to export deformed positions
        export_data = input('\nExport deformed positions? (y/n) [n]: ', 's');
        if strcmpi(export_data, 'y') || strcmpi(export_data, 'yes')
            output_file = sprintf('deformed_positions_nx%d_t%.3f_scale%d.mat', nx, tm, scale_factor);
            save(fullfile(output_folder, output_file), 'p', 'deformed_positions', 'u', 'scale_factor', 'tm');
            fprintf('Data exported: %s\n', output_file);
        end

        return;
    end

    %====================== OPTION 4 ==========================
    %   ALL SECTIONS FOR ALL TIMES
    %=========================================================
    if section_choice == 4
        % List all solution_nx*_t*.mat files for this mesh
        pattern = sprintf('solution_nx%d_t*.mat', nx);
        files = dir(fullfile(output_folder, pattern));

        if isempty(files)
            fprintf('No file "%s" found in "%s".\n', pattern, output_folder);
            return;
        end

        % Extract times from filenames
        t_list = zeros(numel(files),1);
        for k = 1:numel(files)
            tok = regexp(files(k).name, 't([0-9\.]+)s', 'tokens', 'once');
            t_list(k) = str2double(tok{1});
        end
        [t_list, I] = sort(t_list);
        files = files(I);

        fprintf('\nAvailable times for nx=%d:\n', nx);
        fprintf('  '); fprintf('%.3f ', t_list); fprintf('\n');

        % Section type for this mode
        fprintf('\nSection for "ALL TIMES" mode:\n');
        fprintf('1 - z constant\n2 - x constant\n3 - y constant\n');
        mode_all = input('Your choice (1/2/3): ');
        if isempty(mode_all) || ~ismember(mode_all,[1 2 3])
            fprintf('Invalid choice.\n');
            return;
        end

        % Fixed section value for all times
        cut_val = input('Section value (0-1) [0.5]: ');
        if isempty(cut_val), cut_val = 0.5; end
        cut_val = max(0.01, min(0.99, cut_val));

        % Regular 3D grid
        [Xg, Yg, Zg] = meshgrid(linspace(0,1,nx), ...
                                linspace(0,1,nx), ...
                                linspace(0,1,nx));

        % Calculate global umin/umax over ALL times
        umin_global = +inf;
        umax_global = -inf;

        for k = 1:numel(files)
            S = load(fullfile(output_folder, files(k).name));
            if isfield(S,'u')
                u_val = S.u;
            elseif isfield(S,'u0')
                u_val = S.u0;
            else
                error('File %s contains neither u nor u0.', files(k).name);
            end
            umin_global = min(umin_global, min(u_val(:)));
            umax_global = max(umax_global, max(u_val(:)));
        end

        if ~isfinite(umin_global) || ~isfinite(umax_global) || umax_global <= umin_global
            error('Invalid global bounds: umin=%.3e, umax=%.3e', umin_global, umax_global);
        end

        fprintf('Global color scale: [%.3e, %.3e]\n', umin_global, umax_global);

        % Multiple figure (mosaic)
        nF = numel(files);
        nrows = ceil(sqrt(nF));
        ncols = ceil(nF/nrows);

        figure('Position',[50 50 1600 900]);
        set(gcf,'Renderer','opengl');

        for k = 1:nF
            S = load(fullfile(output_folder, files(k).name));
            if isfield(S,'u')
                u_val = S.u;
            else
                u_val = S.u0;
            end
            p_pts = S.p;

            % Interpolation on regular grid
            Ug = griddata(p_pts(:,1), p_pts(:,2), p_pts(:,3), u_val, Xg, Yg, Zg, 'linear');

            if all(isnan(Ug(:)))
                fprintf('Interpolation NaN for %s\n', files(k).name);
                continue;
            end

            % Extract section based on mode_all
            switch mode_all
                case 1  % z = constant
                    [~, iz] = min(abs(Zg(1,1,:) - cut_val));
                    Xc = squeeze(Xg(:,:,iz));
                    Yc = squeeze(Yg(:,:,iz));
                    Uc = squeeze(Ug(:,:,iz));
                    xx = Xc; yy = Yc;

                case 2  % x = constant
                    [~, ix] = min(abs(Xg(1,:,1) - cut_val));
                    Yc = squeeze(Yg(:,ix,:));
                    Zc = squeeze(Zg(:,ix,:));
                    Uc = squeeze(Ug(:,ix,:));
                    xx = Yc; yy = Zc;

                case 3  % y = constant
                    [~, iy] = min(abs(Yg(:,1,1) - cut_val));
                    Xc = squeeze(Xg(iy,:,:));
                    Zc = squeeze(Zg(iy,:,:));
                    Uc = squeeze(Ug(iy,:,:));
                    xx = Xc; yy = Zc;
            end

            % Associated time
            tplot = t_list(k);
            fprintf('Section t=%.3f: min(Uc)=%.3e, max(Uc)=%.3e\n', ...
                    tplot, min(Uc(:)), max(Uc(:)));

            % Subplot and display
            subplot(nrows, ncols, k);
            contourf(xx, yy, Uc, 20, 'LineStyle', 'none');
            axis equal tight;
            colormap(jet);
            caxis([umin_global, umax_global]);

            title(sprintf('t = %.3f', tplot));
        end

        return;
    end

    %================= OPTIONS 1, 2, 3: SINGLE TIME ===================

    % Select time
    time = choisir_temps(data, idx, output_folder);
    if isempty(time), return; end

    % Load data for this time
    [p, tmesh, u, tm] = charger_donnees_temps(output_folder, nx, time);
    if isempty(p), return; end

    % Regular grid
    [Xg, Yg, Zg] = meshgrid(linspace(0,1,nx), linspace(0,1,nx), linspace(0,1,nx));
    Ug = griddata(p(:,1), p(:,2), p(:,3), u, Xg, Yg, Zg, 'linear');
    if all(isnan(Ug(:)))
        fprintf('Error: Interpolated grid contains only NaN\n');
        return;
    end

    % Section type selection (1,2,3)
    figure('Position',[100,100,1200,800]); 
    set(gcf,'Renderer','opengl');

    switch section_choice
        case 1  % z = constant
            z_cut = input('z value for section (0-1) [0.5]: ');
            if isempty(z_cut), z_cut = 0.5; end
            z_cut = max(0.01, min(0.99, z_cut));
            [~, iz] = min(abs(Zg(1,1,:) - z_cut));
            Xc = squeeze(Xg(:,:,iz));  
            Yc = squeeze(Yg(:,:,iz));  
            Uc = squeeze(Ug(:,:,iz));

            fprintf('Section t=%.3f (z=%.2f): min(Uc)=%.3e, max(Uc)=%.3e\n', ...
                    tm, z_cut, min(Uc(:)), max(Uc(:)));

            contourf(Xc, Yc, Uc, 20, 'LineStyle', 'none');
            xlabel('x', 'FontSize', 24, 'FontWeight', 'bold');
            ylabel('y', 'FontSize', 24, 'FontWeight', 'bold');

        case 2  % x = constant
            x_cut = input('x value for section (0-1) [0.5]: ');
            if isempty(x_cut), x_cut = 0.5; end
            x_cut = max(0.01, min(0.99, x_cut));
            [~, ix] = min(abs(Xg(1,:,1) - x_cut));
            Yc = squeeze(Yg(:,ix,:));  
            Zc = squeeze(Zg(:,ix,:));  
            Uc = squeeze(Ug(:,ix,:));

            fprintf('Section t=%.3f (x=%.2f): min(Uc)=%.3e, max(Uc)=%.3e\n', ...
                    tm, x_cut, min(Uc(:)), max(Uc(:)));

            contourf(Yc, Zc, Uc, 20, 'LineStyle', 'none');
            xlabel('y', 'FontSize', 24, 'FontWeight', 'bold');
            ylabel('z', 'FontSize', 24, 'FontWeight', 'bold');

        case 3  % y = constant
            y_cut = input('y value for section (0-1) [0.5]: ');
            if isempty(y_cut), y_cut = 0.5; end
            y_cut = max(0.01, min(0.99, y_cut));
            [~, iy] = min(abs(Yg(:,1,1) - y_cut));
            Xc = squeeze(Xg(iy,:,:));  
            Zc = squeeze(Zg(iy,:,:));  
            Uc = squeeze(Ug(iy,:,:));

            fprintf('Section t=%.3f (y=%.2f): min(Uc)=%.3e, max(Uc)=%.3e\n', ...
                    tm, y_cut, min(Uc(:)), max(Uc(:)));

            contourf(Xc, Zc, Uc, 20, 'LineStyle', 'none');
            xlabel('x', 'FontSize', 24, 'FontWeight', 'bold');
            ylabel('z', 'FontSize', 24, 'FontWeight', 'bold');

        otherwise
            fprintf('Invalid section choice\n');
            return;
    end

    %----------------- Common formatting -----------------
    ax = gca; 
    ax.FontSize = 22; 
    ax.LineWidth = 1.5; 
    ax.FontWeight = 'bold';
    axis equal tight;
    axis on; box off; grid off;
    colormap(jet); 
    cb = colorbar; cb.FontSize = 18;

    % Color scale:
    % - if data.umin_global / umax_global exist, use them
    % - otherwise use min/max of section
    if isfield(data,'umin_global') && isfield(data,'umax_global')
        caxis([data.umin_global, data.umax_global]);
        umin = data.umin_global;
        umax = data.umax_global;
    else
        umin = min(Uc(:)); 
        umax = max(Uc(:));
        if isfinite(umin) && isfinite(umax) && umax > umin
            caxis([umin umax]);
        end
    end

    fprintf('Value range in section: min=%.3e, max=%.3e\n', umin, umax);
end











function visualisation_convergence_newton_bat(data)
    % VISUALISATION_CONVERGENCE_NEWTON_BAT
    % Displays Newton iterative convergence (first time step)
    % in two separate figures, article style.

    fprintf('\n--- Newton iterative convergence (first time step) ---\n');

    % Check visualization_data field
    if ~isfield(data, 'visualization_data')
        fprintf('visualization_data missing.\n');
        return;
    end

    viz_data = data.visualization_data;

    % Select mesh
    idx = choisir_maillage_bat(data);
    if isempty(idx)
        return;
    end

    if idx > length(viz_data)
        fprintf('Index out of bounds.\n');
        return;
    end

    sim = viz_data(idx);

    % Check newton_err_history_all
    if ~isfield(sim, 'newton_err_history_all') || isempty(sim.newton_err_history_all)
        fprintf('No Newton history for this simulation.\n');
        return;
    end

    err_first_step = sim.newton_err_history_all{1};

    if isempty(err_first_step)
        fprintf('First time step empty.\n');
        return;
    end

    % ================== FIGURE 1: ERROR ==================
    fig1 = figure('Position', [100, 100, 1000, 800], 'Color', 'w');
    
    semilogy(1:length(err_first_step), err_first_step, 'o-', ...
             'LineWidth', 3, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
    xlabel('Newton iteration', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel('Error $||\mathbf{w}||_M$', 'Interpreter', 'latex', ...
           'FontSize', 24, 'FontWeight', 'bold');
    title('Iterative convergence (Newton)', 'FontSize', 26, 'FontWeight', 'bold');
    grid off;
    
    % Axes style
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';
    ax.XTick = 1:length(err_first_step);
    
    % ================== FIGURE 2: RATIOS ==================
    fig2 = figure('Position', [1200, 100, 1000, 800], 'Color', 'w');
    
    ratios = err_first_step(2:end) ./ err_first_step(1:end-1);
    plot(1:length(ratios), ratios, 's-', ...
         'LineWidth', 3, 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    xlabel('Iteration', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel('Ratio $e_{j+1}/e_j$', 'Interpreter', 'latex', ...
           'FontSize', 24, 'FontWeight', 'bold');
    title(sprintf('Mean rate = %.6f', mean(ratios)), ...
          'FontSize', 26, 'FontWeight', 'bold');
    yline(1, '--k', 'LineWidth', 2);
    grid off;
    
    % Axes style
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';
    ax.XTick = 1:length(ratios);
    
    % ================== OPTIONAL SAVE ==================
    save_figs = input('\nSave figures? (y/n) [n]: ', 's');
    if strcmpi(save_figs, 'y') || strcmpi(save_figs, 'yes')
        filename1 = sprintf('convergence_newton_err_nx%d.png', sim.nx);
        filename2 = sprintf('convergence_newton_ratio_nx%d.png', sim.nx);
        saveas(fig1, filename1);
        saveas(fig2, filename2);
        fprintf('Figures saved:\n   %s\n   %s\n', filename1, filename2);
    end

    fprintf('Two Newton convergence figures displayed (article style).\n');
end

function visualiser_taux_vs_tau()
    % VISUALISER_TAUX_VS_TAU
    % Calculates and displays convergence rate alpha versus time step tau
    % for all available schemes (Newton, Picard, L-scheme)
    % Style: log10(alpha) vs log10(tau), with slope 0.5 line

    fprintf('\n--- Convergence rate alpha vs tau ---\n');

    % ==================== LOAD SCHEMES ====================
    all_schemes = {};
    scheme_names = {};

    % Newton
    if exist('Newton/resultats_complets/resultats_complets.mat', 'file')
        all_schemes{end+1} = load('Newton/resultats_complets/resultats_complets.mat');
        scheme_names{end+1} = 'Newton';
        fprintf('Newton loaded\n');
    end

    % Picard
    if exist('Picard/resultats_complets/resultats_complets.mat', 'file')
        all_schemes{end+1} = load('Picard/resultats_complets/resultats_complets.mat');
        scheme_names{end+1} = 'Picard';
        fprintf('Picard loaded\n');
    end

    % L-scheme
    if exist('L-scheme', 'dir')
        folders = dir('L-scheme/L=*');
        for i = 1:length(folders)
            if folders(i).isdir
                file = fullfile('L-scheme', folders(i).name, ...
                                'resultats_complets', 'resultats_complets.mat');
                if exist(file, 'file')
                    all_schemes{end+1} = load(file);
                    L_val = strrep(folders(i).name, 'L=', '');
                    scheme_names{end+1} = sprintf('L-scheme (L=%s)', L_val);
                    fprintf('%s loaded\n', scheme_names{end});
                end
            end
        end
    end

    if isempty(all_schemes)
        fprintf('No scheme found.\n');
        return;
    end

    % ==================== COLLECT DATA ====================
    results = {};  % each element: {scheme_name, [log10_tau], [log10_rate]}

    for s = 1:length(all_schemes)
        data = all_schemes{s};
        name = scheme_names{s};

        if ~isfield(data, 'visualization_data') || ~isfield(data, 'Nx_list')
            continue;
        end

        log_tau_list = [];
        log_rate_list = [];

        for i = 1:length(data.visualization_data)
            sim = data.visualization_data(i);

            % Get tau
            if isfield(data, 'dt_used') && length(data.dt_used) >= i
                tau = data.dt_used(i);
            else
                continue;
            end

            % Get error history
            err_hist = [];
            if isfield(sim, 'newton_err_history_all') && ~isempty(sim.newton_err_history_all)
                err_hist = sim.newton_err_history_all{1};
            elseif isfield(sim, 'err_history_all') && ~isempty(sim.err_history_all)
                err_hist = sim.err_history_all{1};
            end

            if isempty(err_hist) || length(err_hist) < 2
                continue;
            end

            % Calculate mean rate (geometric mean over first 10 iterations)
            n_iter = min(10, length(err_hist)-1);
            ratios = err_hist(2:n_iter+1) ./ err_hist(1:n_iter);
            mean_rate = geomean(ratios);

            log_tau_list = [log_tau_list, log10(tau)];
            log_rate_list = [log_rate_list, log10(mean_rate)];
        end

        if ~isempty(log_tau_list)
            % Sort by increasing tau
            [log_tau_list, idx] = sort(log_tau_list);
            log_rate_list = log_rate_list(idx);

            results{end+1} = {name, log_tau_list, log_rate_list};
        end
    end

    if isempty(results)
        fprintf('No usable data.\n');
        return;
    end

    % ==================== FIGURE ====================
    figure('Position', [100, 100, 1200, 800], 'Color', 'w');
    hold on;

    % Color palette
    palette = [
        0, 0.4470, 0.7410;      % blue
        0.8500, 0.3250, 0.0980; % orange
        0.4660, 0.6740, 0.1880; % green
        0.4940, 0.1840, 0.5560; % purple
        0.3010, 0.7450, 0.9330; % cyan
        0.6350, 0.0780, 0.1840; % dark red
        0.9290, 0.6940, 0.1250; % gold
    ];

    for i = 1:length(results)
        name = results{i}{1};
        log_tau = results{i}{2};
        log_rate = results{i}{3};

        color = palette(mod(i-1, size(palette,1)) + 1, :);

        % If at least 2 points, plot connected curve
        if length(log_tau) >= 2
            plot(log_tau, log_rate, 'o-', ...
                 'LineWidth', 2.5, 'MarkerSize', 8, ...
                 'Color', color, 'MarkerFaceColor', color, ...
                 'MarkerEdgeColor', 'k', ...
                 'DisplayName', name);
        else
            % Just a point
            plot(log_tau, log_rate, 'o', ...
                 'MarkerSize', 10, 'MarkerFaceColor', color, ...
                 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, ...
                 'DisplayName', name);
        end
    end

    % Reference line with slope 0.5
    x_min = -3.2;
    x_max = -0.8;
    x_ref = linspace(x_min, x_max, 100);
    y_ref = 0.5 * x_ref + 1.0;
    plot(x_ref, y_ref, '--k', 'LineWidth', 2, 'DisplayName', 'slope 0.5');

    % Formatting
    xlabel('$\log_{10}(\tau)$', 'Interpreter', 'latex', ...
           'FontSize', 24, 'FontWeight', 'bold');
    ylabel('$\log_{10}(\alpha)$', 'Interpreter', 'latex', ...
           'FontSize', 24, 'FontWeight', 'bold');
    title('Convergence rate $\alpha$ vs $\tau$', ...
          'Interpreter', 'latex', 'FontSize', 26, 'FontWeight', 'bold');

    legend('Location', 'best', 'FontSize', 14, 'Box', 'on', 'Interpreter', 'latex');

    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';
    grid off;

    % Adjust limits
    xlim([-3.2, -0.8]);
    ylim([-1.5, 0.2]);

    fprintf('Figure generated with %d schemes.\n', length(results));
end

function visualisation_erreurs_bat(data)
    % VISUALISATION_ERREURS_BAT - Error graphs and convergence orders
    
    fprintf('\n--- Error graphs and convergence ---\n');
    
    h_values = data.h_values;
    
    % Check data
    if length(h_values) < 2
        fprintf('Not enough meshes for convergence analysis\n');
        return;
    end
    
    fprintf('\n--- Error graph ---\n');

    % h_values: keep name; if absent, deduce from Nx_list
    if isfield(data, 'h_values') && ~isempty(data.h_values)
        h_values = data.h_values;
    else
        h_values = 1 ./ (data.Nx_list - 1);
    end

    % Sort h ascending for clean plot
    [h_sorted, idx_h] = sort(h_values);

    % Labels 10^k for X axis
    pow_labels = compose('10^{%d}', round(log10(h_sorted)));

    % Errors
    err_L2 = data.Erreur_L2(idx_h);
    err_H1 = data.Erreur_H1(idx_h);

    % ===== FIGURE: L2 AND H1 ERRORS =====
    figure('Position', [100, 100, 1200, 800]);
    hold on;
    loglog(h_sorted, err_L2, 'ro-', 'LineWidth', 3, 'MarkerSize', 12, ...
        'DisplayName', 'e_{L_2(\Omega)}(\psi)');
    loglog(h_sorted, err_H1, 'bs-', 'LineWidth', 3, 'MarkerSize', 12, ...
        'DisplayName', 'e_{H_1(\Omega)}(\psi)');

    % Axes configuration
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';

    xlabel('h', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel('Error', 'FontSize', 24, 'FontWeight', 'bold');
    title('L2 and H1 Errors', 'FontSize', 24, 'FontWeight', 'bold');
    legend('Location', 'southwest', 'FontSize', 20);

    % Log scales
    set(ax, 'XScale', 'log', 'YScale', 'log');

    % Limited ticks
    if numel(h_sorted) > 5
        step = max(1, floor(numel(h_sorted)/4));
        selected_ticks = 1:step:numel(h_sorted);
        xticks(h_sorted(selected_ticks));
        xticklabels(pow_labels(selected_ticks));
    else
        xticks(h_sorted);
        xticklabels(pow_labels);
    end

    % Graph style
    grid off;
    ax.GridLineStyle = '--';
    ax.GridAlpha = 0.3;
    ax.GridColor = [0.5, 0.5, 0.5];
    box off;

    % ===== FIGURE 3: CPU TIME =====
    figure('Position', [300, 100, 1000, 800]);
    plot(h_values, data.CPU_times, 'ko-', 'LineWidth', 3, 'MarkerSize', 12);
    
    % Axes configuration
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    
    xlabel('h', 'FontSize', 24, 'FontWeight', 'bold');
    ylabel('CPU Time (s)', 'FontSize', 24, 'FontWeight', 'bold');
    title('Computation Time', 'FontSize', 24, 'FontWeight', 'bold');
    axis on; box off; grid off;
    
    % ===== FIGURE 4: NEWTON ITERATIONS =====
    figure('Position', [400, 100, 800, 600]);
    
    bar([data.Newton_iters_last]);
    grid off;
    
    xlabel('Simulation', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Newton iterations', 'FontSize', 12, 'FontWeight', 'bold');
    title('Newton iterations', 'FontSize', 14, 'FontWeight', 'bold');
    
    set(gca, 'FontSize', 11);

    % ===== FIGURE 5: CPU - BAR CHART (thinner bars) =====
    try
        tau_vals = h_values;
        cats = categorical(compose('%.3g', tau_vals));
        cats = reordercats(cats, compose('%.3g', tau_vals));

        figure('Position', [150, 100, 900, 700]);
        b = bar(cats, data.CPU_times, 'EdgeColor', 'k', 'LineWidth', 1.2);
        b.BarWidth = 0.35;
        b.FaceColor = 'flat';
        colormap(lines);

        ax = gca;
        ax.FontSize = 22;
        ax.LineWidth = 1.5;
        ax.FontWeight = 'bold';
        ax.TickLabelInterpreter = 'tex';

        xlabel('\tau', 'FontSize', 24, 'FontWeight', 'bold');
        ylabel('CPU time [s]', 'FontSize', 24, 'FontWeight', 'bold');
        title('CPU time vs \tau', 'FontSize', 24, 'FontWeight', 'bold');

        grid off; box off;
        set(gcf, 'Color', 'white');
    catch
        figure('Position', [150, 100, 900, 700]);
        b = bar(tau_vals, data.CPU_times, 'EdgeColor', 'k', 'LineWidth', 1.2);
        b.BarWidth = 0.35;
        ax = gca;
        ax.FontSize = 22;
        ax.LineWidth = 1.5;
        ax.FontWeight = 'bold';
        xlabel('\tau', 'FontSize', 24, 'FontWeight', 'bold');
        ylabel('CPU time [s]', 'FontSize', 24, 'FontWeight', 'bold');
        title('CPU time vs \tau', 'FontSize', 24, 'FontWeight', 'bold');
        grid off; box off;
        set(gcf, 'Color', 'white');
    end

    % ===== FIGURE 6: NEWTON ITERATIONS - BAR CHART (thinner bars) =====
    try
        tau_vals = h_values;
        cats = categorical(compose('%.3g', tau_vals));
        cats = reordercats(cats, compose('%.3g', tau_vals));

        figure('Position', [250, 100, 900, 700]);
        b = bar(cats, data.Newton_iters_last, 'EdgeColor', 'k', 'LineWidth', 1.2);
        b.BarWidth = 0.35;
        b.FaceColor = 'flat';
        colormap(lines);

        ax = gca;
        ax.FontSize = 22;
        ax.LineWidth = 1.5;
        ax.FontWeight = 'bold';
        ax.TickLabelInterpreter = 'tex';

        xlabel('\tau', 'FontSize', 24, 'FontWeight', 'bold');
        ylabel('Number of iterations', 'FontSize', 24, 'FontWeight', 'bold');
        title('Newton iterations vs \tau', 'FontSize', 24, 'FontWeight', 'bold');

        grid off; box off;
        set(gcf, 'Color', 'white');
    catch
        figure('Position', [250, 100, 900, 700]);
        b = bar(tau_vals, data.Newton_iters_last, 'EdgeColor', 'k', 'LineWidth', 1.2);
        b.BarWidth = 0.35;
        ax = gca;
        ax.FontSize = 22;
        ax.LineWidth = 1.5;
        ax.FontWeight = 'bold';
        xlabel('\tau', 'FontSize', 24, 'FontWeight', 'bold');
        ylabel('Number of iterations', 'FontSize', 24, 'FontWeight', 'bold');
        title('Newton iterations vs \tau', 'FontSize', 24, 'FontWeight', 'bold');
        grid off; box off;
        set(gcf, 'Color', 'white');
    end
end

function idx = choisir_maillage_bat(data)
    % CHOISIR_MAILLAGE_BAT - Select mesh with data verification
    
    fprintf('\nSelect mesh:\n');
    
    % Determine available meshes
    if isfield(data, 'Nx_list_original')
        nx_list = data.Nx_list_original;
    elseif isfield(data, 'Nx_list')
        nx_list = data.Nx_list;
    elseif isfield(data, 'nx_used')
        nx_list = unique(data.nx_used);
    else
        fprintf('Unable to find mesh information.\n');
        idx = [];
        return;
    end
    
    % Display available meshes
    for i = 1:length(nx_list)
        fprintf('%d - nx=%d\n', i, nx_list(i));
    end
    
    try
        choice = input(['Your choice (1-' num2str(length(nx_list)) '): ']);
        
        % Robust choice verification
        if isempty(choice)
            fprintf('Empty choice. Using first mesh.\n');
            idx = 1;
        elseif ~isnumeric(choice)
            fprintf('Non-numeric choice. Using first mesh.\n');
            idx = 1;
        elseif choice < 1 || choice > length(nx_list)
            fprintf('Choice out of bounds. Using first mesh.\n');
            idx = 1;
        else
            idx = choice;
            fprintf('Selected mesh: nx=%d\n', nx_list(idx));
        end
        
    catch ME
        fprintf('Error during selection: %s\n', ME.message);
        fprintf('Using first mesh.\n');
        idx = 1;
    end
    
    % Ensure idx is valid
    if isempty(idx) || idx < 1 || idx > length(nx_list)
        idx = 1;
        fprintf('Automatic correction: using first mesh (nx=%d)\n', nx_list(1));
    end
end



function comparer_schemes_bat()
    % COMPARER_SCHEMES_BAT - Compare all L values + Newton + Picard
    
    fprintf('\n--- COMPLETE COMPARISON (L=1, L=0.25, L=0.15 + Newton + Picard) ---\n');
    
    % Load all data using utility function
    [data_all, scheme_names] = charger_toutes_donnees_comparaison();
    
    % Create 4 figures
    fprintf('\nCreating comparison figures...\n');
    figure_cpu_comparaison_complete(data_all, scheme_names);
    figure_iterations_comparaison_complete(data_all, scheme_names);
    figure_erreur_comparaison_complete(data_all, scheme_names);
    figure_conditionnement_comparaison_complete(data_all, scheme_names);
    
    fprintf('Comparison completed! 4 figures created with %d schemes.\n', length(data_all));
end

function figure_cpu_comparaison_complete(data_all, scheme_names)
    % FIGURE_CPU_COMPARAISON_COMPLETE - CPU time figure with 1/h axis
    % Article version with displayed values

    figure('Position', [100, 100, 1000, 800], 'Name', 'Computation Time');
    
    % Colors (3 main schemes + 2 backups)
    colors = {
        [0, 0.4470, 0.7410],     % L-scheme (L=1) -> blue
        [0.4660, 0.6740, 0.1880],% L-scheme (L=0.15) -> green
        [0.2, 0.2, 0.2],         % Newton -> gray/black
        [0.4940, 0.1840, 0.5560],% (unused / backup)
        [0.8500, 0.3250, 0.0980] % (unused / backup)
    };

    styles = {'-o', '-s', '-^', '-d', '--s'};  % Newton dashed with squares
    
    hold on;
    
    text_handles = [];
    
    % Plot each scheme with provided data
    for i = 1:length(data_all)
        data = data_all{i};
        color = colors{mod(i-1, length(colors))+1};
        style = styles{mod(i-1, length(styles))+1};
        
        if isfield(data, 'h_values') && isfield(data, 'CPU_times')
            % Convert h to 1/h
            inv_h = 1 ./ data.h_values;
            cpu_times = data.CPU_times;
            
            n_points = min(length(inv_h), length(cpu_times));
            inv_h = inv_h(1:n_points);
            cpu_times = cpu_times(1:n_points);
            
            % Special style for Newton (dashed)
            if contains(scheme_names{i}, 'Newton')
                plot(inv_h, cpu_times, '--s', ...
                     'Color', color, ...
                     'LineWidth', 3.5, ...
                     'MarkerSize', 9, ...
                     'MarkerFaceColor', color, ...
                     'DisplayName', formatLegend(scheme_names{i}));
            else
                % Normal styles for others
                plot(inv_h, cpu_times, style, ...
                     'Color', color, ...
                     'LineWidth', 3.5, ...
                     'MarkerSize', 8, ...
                     'MarkerFaceColor', color, ...
                     'DisplayName', formatLegend(scheme_names{i}));
            end
            
            % Display actual CPU values
            for j = 1:n_points
                if cpu_times(j) >= 1000
                    label_text = sprintf('(%.0f)', cpu_times(j));
                else
                    label_text = sprintf('(%.1f)', cpu_times(j));
                end
                
                h_text = text(inv_h(j), cpu_times(j), ...
                     label_text, 'FontSize', 20, 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center', ...
                     'VerticalAlignment', 'bottom', ...
                     'Color', color, ...
                     'ButtonDownFcn', @startDrag);
                
                text_handles = [text_handles, h_text];
            end
        end
    end
    
    % Axes configuration (article style)
    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';
    
    % Labels
    xlabel('1/h', 'FontSize', 20, 'FontWeight', 'bold');
    
    % Draggable legend with LaTeX interpreter
    h_legend = legend('Location', 'northwest', 'FontSize', 22, 'Box', 'on', ...
                      'Interpreter', 'latex');
    set(h_legend, 'ButtonDownFcn', @legendButtonDown);
    
    % Ticks and limits
    xticks([0, 4, 8, 16, 32, 64]);
    xticklabels({'0', '4', '8', '16', '32', '64'});
    xlim([0, 65]);
    ylim([0, 3100]);
    
    % Log scale Y
    set(gca, 'YScale', 'log');
    ylim([0, 1e4]);

    yticks(10.^(0:4));
    yticklabels({'10^0','10^1','10^2','10^3','10^4'});

    % No grid
    grid off;
    
    % White background
    set(gcf, 'Color', 'white');
    
    hold off;
    
    % === FUNCTION TO FORMAT LEGENDS ===
    function formatted_legend = formatLegend(name)
        if contains(name, 'L=1')
            formatted_legend = '$\mathbf{L-scheme \left(L=1\right)}$';
        elseif contains(name, 'Newton')
            formatted_legend = '$\mathbf{Newton}$';
        elseif contains(name, 'L=0.15')
            formatted_legend = '$\mathbf{L-scheme \left(L=0.15\right)}$';
        elseif contains(name, 'L=0.25')
            formatted_legend = '$\mathbf{L-scheme \left(L=0.25\right)}$';
        elseif contains(name, 'L=0.5')
            formatted_legend = '$L-scheme \left(L=0.5\right)$';
        elseif contains(name, 'L=2.42e-5')
            formatted_legend = 'L-scheme \left(L=2.42\times10^{-5}\right)';
        else
            formatted_legend = '$\mathbf{Picard}$';
        end
    end
    
    % === FUNCTIONS TO DRAG LEGEND AND TEXT ===
    function legendButtonDown(~, ~)
        set(gcf, 'WindowButtonMotionFcn', @legendDrag, ...
                 'WindowButtonUpFcn', @stopLegendDrag);
    end

    function legendDrag(~, ~)
        currentPoint = get(gcf, 'CurrentPoint');
        fig_pos = get(gcf, 'Position');
        legend_pos = [currentPoint(1)/fig_pos(3), currentPoint(2)/fig_pos(4), 0.2, 0.2];
        set(h_legend, 'Units','normalized', 'Position', legend_pos);
    end

    function stopLegendDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', '', ...
                 'WindowButtonUpFcn', '');
    end

    function startDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', @dragText, ...
                 'WindowButtonUpFcn', @stopDrag);
    end

    function dragText(~, ~)
        currentPoint = get(gca, 'CurrentPoint');
        h_text = gco;
        if isgraphics(h_text, 'text')
            newPos = [currentPoint(1,1), currentPoint(1,2), 0];
            set(h_text, 'Position', newPos);
        end
    end

    function stopDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', '', ...
                 'WindowButtonUpFcn', '');
    end
    
    fprintf('Computation Time figure created (1/h, colors, CPU values).\n');
end

function [data_all, scheme_names] = charger_toutes_donnees_comparaison()
    % CHARGER_TOUTES_DONNEES_COMPARAISON - Load all data for comparison
    % Continues even if some files are missing
    
    % Paths to all folders
    folders = {
        'L-scheme/L=1',     'L-scheme (L=1)';
        'L-scheme/L=0.25',  'L-scheme (L=0.25)'; 
        'L-scheme/L=0.15',  'L-scheme (L=0.15)';
        'L-scheme/L=2.4200e-05', 'L-scheme (L=2.42e-5)';
        'Newton',           'Newton';
        'Picard',           'Picard'
    };
    
    data_all = {};
    scheme_names = {};
    
    fprintf('Loading data for comparison...\n');
    
    for i = 1:size(folders, 1)
        folder = folders{i, 1};
        scheme_name = folders{i, 2};
        
        % Build file path
        data_file = fullfile(folder, 'resultats_complets', 'resultats_complets.mat');
        
        if ~exist(data_file, 'file')
            fprintf('File not found: %s\n', data_file);
            continue;
        else
            try
                data = load(data_file);
                data_all{end+1} = data;
                scheme_names{end+1} = scheme_name;
                fprintf('Data loaded: %s\n', scheme_name);
            catch ME
                fprintf('Error loading %s: %s\n', scheme_name, ME.message);
                continue;
            end
        end
    end
    
    fprintf('Total: %d/%d schemes loaded successfully\n', length(data_all), size(folders, 1));
end

function figure_iterations_comparaison_complete(data_all, scheme_names)
    % FIGURE_ITERATIONS_COMPARAISON_COMPLETE - Iterations figure with 1/h axis
    % Style identical to CPU figure

    figure('Position', [100, 100, 1000, 800], 'Name', 'Number of iterations');

    % Colors identical to CPU figure
    color_L1    = [0, 0.4470, 0.7410];      % blue
    color_L015  = [0.4660, 0.6740, 0.1880]; % green
    color_L025  = [0.2, 0.2, 0.2];          % gray/black
    color_Newton = [0.4940, 0.1840, 0.5560]; % purple
    color_Picard = [0.8500, 0.3250, 0.0980]; % orange

    styles = {'-o', '-s', '-^', '-d', '--s'};

    hold on;
    text_handles = [];

    % Reorder: L=1, L=0.25, L=0.15, Picard, Newton
    order = zeros(size(scheme_names));
    for i = 1:numel(scheme_names)
        n = scheme_names{i};
        if contains(n, 'L=1')
            order(i) = 1;
        elseif contains(n, 'L=0.25')
            order(i) = 2;
        elseif contains(n, 'L=0.15')
            order(i) = 3;
        elseif contains(n, 'Picard')
            order(i) = 4;
        elseif contains(n, 'Newton')
            order(i) = 5;
        else
            order(i) = 99;
        end
    end
    [~, idxSort] = sort(order);
    data_all = data_all(idxSort);
    scheme_names = scheme_names(idxSort);

    % Plot each scheme
    for i = 1:length(data_all)
        data = data_all{i};
        name = scheme_names{i};

        % Select color based on name
        color = color_Picard;
        if contains(name, 'L=1')
            color = color_L1;
        elseif contains(name, 'L=0.15')
            color = color_L015;
        elseif contains(name, 'L=0.25')
            color = color_L025;
        elseif contains(name, 'Newton')
            color = color_Newton;
        elseif contains(name, 'Picard')
            color = color_Picard;
        end

        if ~isfield(data, 'h_values')
            fprintf('Missing fields for %s\n', name);
            continue;
        end

        % Convert h to 1/h
        inv_h = 1 ./ data.h_values;

        % Select iteration field
        if contains(name, 'Newton')
            if isfield(data, 'Newton_iters_moyenne')
                iterations = data.Newton_iters_moyenne;
            elseif isfield(data, 'Newton_iters')
                iterations = data.Newton_iters;
            elseif isfield(data, 'Picard_iters_moyenne')
                iterations = data.Picard_iters_moyenne;
            else
                fprintf('Missing Newton iterations for %s\n', name);
                continue;
            end
        else
            if ~isfield(data, 'Picard_iters_moyenne')
                fprintf('Missing fields for %s\n', name);
                continue;
            end
            iterations = data.Picard_iters_moyenne;
        end

        n_points = min(length(inv_h), length(iterations));
        inv_h = inv_h(1:n_points);
        iterations = iterations(1:n_points);

        % Special style for Newton
        if contains(name, 'Newton')
            plot(inv_h, iterations, '--s', ...
                 'Color', color, ...
                 'LineWidth', 3.5, ...
                 'MarkerSize', 9, ...
                 'MarkerFaceColor', color, ...
                 'DisplayName', formatLegend(name));
        else
            style = styles{mod(i-1, length(styles))+1};
            plot(inv_h, iterations, style, ...
                 'Color', color, ...
                 'LineWidth', 3.5, ...
                 'MarkerSize', 8, ...
                 'MarkerFaceColor', color, ...
                 'DisplayName', formatLegend(name));
        end

        % Display iteration values
        for j = 1:n_points
            label_text = formatIterations(iterations(j));
            h_text = text(inv_h(j), iterations(j), label_text, ...
                 'FontSize', 20, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center', ...
                 'VerticalAlignment', 'bottom', ...
                 'Color', color, ...
                 'ButtonDownFcn', @startDrag);
            text_handles = [text_handles, h_text];
        end
    end

    % Axes configuration
    ax = gca;
    ax.FontSize = 20;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';

    xlabel('1/h', 'FontSize', 20, 'FontWeight', 'bold');

    % Draggable legend
    h_legend = legend('Location', 'northwest', 'FontSize', 20, 'Box', 'on', ...
                      'Interpreter', 'latex');
    set(h_legend, 'ButtonDownFcn', @legendButtonDown);

    % Ticks and limits
    xticks([0, 4, 8, 16, 32, 64]);
    xticklabels({'0', '4', '8', '16', '32', '64'});
    xlim([0, 65]);

    % Linear Y scale
    set(gca, 'YScale', 'linear');
    yl = ylim;
    if isfinite(yl(2)) && yl(2) > 0
        ylim([0, yl(2)*1.15]);
    end

    grid off;
    set(gcf, 'Color', 'white');
    hold off;

    function formatted_legend = formatLegend(name)
        if contains(name, 'L=1')
            formatted_legend = '$\mathbf{L-scheme \left(L=1\right)}$';
        elseif contains(name, 'L=0.15')
            formatted_legend = '$\mathbf{L-scheme \left(L=0.15\right)}$';
        elseif contains(name, 'L=0.25')
            formatted_legend = '$\mathbf{L-scheme \left(L=0.25\right)}$';
        elseif contains(name, 'Newton')
            formatted_legend = '$\mathbf{Newton}$';
        else
            formatted_legend = '$\mathbf{Picard}$';
        end
    end

    function str = formatIterations(val)
        if abs(val - round(val)) < 1e-12
            str = sprintf('(%d)', round(val));
        else
            if val < 10
                str = sprintf('(%.1f)', val);
            else
                str = sprintf('(%.2f)', val);
            end
            str = regexprep(str, '\.0+\)$', ')');
        end
    end

    % Drag functions
    function legendButtonDown(~, ~)
        set(gcf, 'WindowButtonMotionFcn', @legendDrag, ...
                 'WindowButtonUpFcn', @stopLegendDrag);
    end

    function legendDrag(~, ~)
        currentPoint = get(gcf, 'CurrentPoint');
        fig_pos = get(gcf, 'Position');
        legend_pos = [currentPoint(1)/fig_pos(3), currentPoint(2)/fig_pos(4), 0.2, 0.2];
        set(h_legend, 'Units','normalized', 'Position', legend_pos);
    end

    function stopLegendDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', '', ...
                 'WindowButtonUpFcn', '');
    end

    function startDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', @dragText, ...
                 'WindowButtonUpFcn', @stopDrag);
    end

    function dragText(~, ~)
        currentPoint = get(gca, 'CurrentPoint');
        h_text = gco;
        if isgraphics(h_text, 'text')
            newPos = [currentPoint(1,1), currentPoint(1,2), 0];
            set(h_text, 'Position', newPos);
        end
    end

    function stopDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', '', ...
                 'WindowButtonUpFcn', '');
    end

    fprintf('Iterations figure created.\n');
end

function figure_conditionnement_comparaison_complete(data_all, scheme_names)
    % FIGURE_CONDITIONNEMENT_COMPARAISON_COMPLETE - Conditioning figure with 1/h axis

    figure('Position', [400, 100, 1000, 800], 'Name', 'Condition Numbers');
    
    % Colors identical to CPU figure
    colors = {
        [0, 0.4470, 0.7410],     % L-scheme (L=1) -> blue
        [0.4660, 0.6740, 0.1880],% L-scheme (L=0.15) -> green
        [0.2, 0.2, 0.2],         % Newton/Picard -> gray/black
        [0.4940, 0.1840, 0.5560],% backup
        [0.8500, 0.3250, 0.0980] % backup
    };

    styles = {'-o', '-s', '-^', '-d', '--s'};
    hold on;
    
    text_handles = [];
    
    for i = 1:length(data_all)
        data = data_all{i};
        color = colors{mod(i-1, length(colors))+1};
        style = styles{mod(i-1, length(styles))+1};
        
        if isfield(data, 'h_values') && isfield(data, 'Cond_max')
            % Convert h to 1/h
            inv_h = 1 ./ data.h_values;
            cond_max = data.Cond_max;
            
            n_points = min(length(inv_h), length(cond_max));
            inv_h = inv_h(1:n_points);
            cond_max = cond_max(1:n_points);

            % x linear, y log
            if contains(scheme_names{i}, 'Newton')
                semilogy(inv_h, cond_max, '--s', ...
                     'Color', color, ...
                     'LineWidth', 3.5, ...
                     'MarkerSize', 9, ...
                     'MarkerFaceColor', color, ...
                     'DisplayName', formatLegend(scheme_names{i}));
            else
                semilogy(inv_h, cond_max, style, ...
                     'Color', color, ...
                     'LineWidth', 3.5, ...
                     'MarkerSize', 8, ...
                     'MarkerFaceColor', color, ...
                     'DisplayName', formatLegend(scheme_names{i}));
            end
            
            % Integer labels with parentheses
            for j = 1:n_points
                label_text = sprintf('(%d)', round(cond_max(j)));
                h_text = text(inv_h(j), cond_max(j), label_text, ...
                    'FontSize', 20, 'FontWeight', 'bold', ...
                    'Color', color, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'ButtonDownFcn', @startDrag);
                
                text_handles = [text_handles, h_text];
            end
        end
    end
    
    ax = gca;
    ax.FontSize = 20;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    ax.Box = 'off';
    ax.TickDir = 'out';

    xlabel('1/h', 'FontSize', 20, 'FontWeight', 'bold');

    h_legend = legend('Location', 'northwest', 'FontSize', 20, 'Box', 'on', ...
                      'Interpreter', 'latex');
    set(h_legend, 'ButtonDownFcn', @legendButtonDown);

    % X axis: log scale
    set(gca, 'XScale', 'log');
    xlim([0 1e2]);
    xticks([1e1 1e2]);
    xticklabels({'10^1', '10^2'});
    ax.XMinorTick = 'on';
    ax.TickLabelInterpreter = 'tex';

    % Y axis: log scale
    set(gca, 'YScale', 'log');
    ylim([6, 1e4]);

    yticks([6, 10, 100, 1000, 10000]);
    yticklabels({'', '10^1', '10^2', '10^3', '10^4'});

    grid off;
    set(gcf, 'Color', 'white');
    hold off;

    fprintf('Condition Numbers figure created.\n');

    function formatted_legend = formatLegend(name)
        if contains(name, 'L=1')
            formatted_legend = '$\mathbf{L-scheme \left(L=1\right)}$';
        elseif contains(name, 'Newton')
            formatted_legend = '$\mathbf{Newton}$';
        elseif contains(name, 'L=0.15')
            formatted_legend = '$\mathbf{L-scheme \left(L=0.15\right)}$';
        elseif contains(name, 'L=0.25')
            formatted_legend = '$\mathbf{L-scheme \left(L=0.25\right)}$';
        elseif contains(name, 'L=0.5')
            formatted_legend = 'L-scheme \left(L=0.5\right)';
        elseif contains(name, 'L=2.42e-5')
            formatted_legend = 'L-scheme \left(L=2.42\times10^{-5}\right)';
        else
            formatted_legend = '$\mathbf{Picard }$';
        end
    end

    % Drag functions
    function legendButtonDown(~, ~)
        try
            set(gcf, 'WindowButtonMotionFcn', @legendDrag, ...
                     'WindowButtonUpFcn', @stopLegendDrag);
        catch
        end
    end

    function legendDrag(~, ~)
        try
            currentPoint = get(gcf, 'CurrentPoint');
            fig_pos = get(gcf, 'Position');
            legend_pos = [currentPoint(1)/fig_pos(3), currentPoint(2)/fig_pos(4), 0.2, 0.2];
            set(h_legend, 'Position', legend_pos);
        catch
        end
    end

    function stopLegendDrag(~, ~)
        try
            set(gcf, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
        catch
        end
    end

    function startDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', @dragText, ...
                 'WindowButtonUpFcn', @stopDrag);
    end

    function dragText(~, ~)
        try
            currentPoint = get(gca, 'CurrentPoint');
            h_text = gco;
            if isgraphics(h_text, 'text')
                newPos = [currentPoint(1,1), currentPoint(1,2), 0];
                set(h_text, 'Position', newPos);
            end
        catch
        end
    end

    function stopDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
    end
end




function visualisation_conditionnement_bat(data)
    % VISUALISATION_CONDITIONNEMENT_BAT - Conditioning and iterations analysis
    
    fprintf('\n--- CONDITIONING AND ITERATIONS ANALYSIS ---\n');
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Subplot 1: Max and mean conditioning
    subplot(2,2,1);
    if isfield(data, 'Cond_max') && isfield(data, 'Cond_moyen')
        bar([data.Cond_max, data.Cond_moyen]);
        grid on;
        xlabel('Simulation', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Condition number', 'FontSize', 12, 'FontWeight', 'bold');
        title('Condition number (max and mean)', 'FontSize', 14, 'FontWeight', 'bold');
        legend('Max', 'Mean', 'Location', 'best');
        set(gca, 'YScale', 'log');
        set(gca, 'FontSize', 11);
    else
        text(0.5, 0.5, 'Conditioning data not available', ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    % Subplot 2: Problematic iterations (if available)
    subplot(2,2,2);
    if isfield(data, 'Iter_problematiques')
        bar(data.Iter_problematiques);
        grid on;
        xlabel('Simulation', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Iterations > 1e10', 'FontSize', 12, 'FontWeight', 'bold');
        title('Problematic iterations', 'FontSize', 14, 'FontWeight', 'bold');
        set(gca, 'FontSize', 11);
    else
        text(0.5, 0.5, 'Problematic iterations data not available', ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    % Subplot 3: Iterations vs h
    subplot(2,2,3);
    if isfield(data, 'h_values') && isfield(data, 'Newton_iters_moyenne')
        plot(data.h_values, data.Newton_iters_moyenne, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
        grid on;
        xlabel('h', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Average iterations', 'FontSize', 12, 'FontWeight', 'bold');
        title('Iterations vs h', 'FontSize', 14, 'FontWeight', 'bold');
        set(gca, 'FontSize', 11);
    else
        text(0.5, 0.5, 'Iteration data not available', ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    % Subplot 4: Conditioning vs error
    subplot(2,2,4);
    if isfield(data, 'Erreur_L2') && isfield(data, 'Cond_max')
        plot(data.Erreur_L2, data.Cond_max, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
        grid on;
        xlabel('L2 error', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Max condition number', 'FontSize', 12, 'FontWeight', 'bold');
        title('Condition number vs Error', 'FontSize', 14, 'FontWeight', 'bold');
        set(gca, 'XScale', 'log', 'YScale', 'log');
        set(gca, 'FontSize', 11);
    else
        text(0.5, 0.5, 'Error/Conditioning data not available', ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    sgtitle('CONDITIONING AND ITERATIONS ANALYSIS', ...
            'FontSize', 16, 'FontWeight', 'bold');
    
    % Display statistics
    fprintf('\nCONDITIONING STATISTICS:\n');
    
    % Determine number of simulations
    if isfield(data, 'nx_used')
        n_simulations = length(data.nx_used);
        for i = 1:n_simulations
            if isfield(data, 'Cond_max') && isfield(data, 'Cond_moyen') && isfield(data, 'Iter_problematiques')
                fprintf('Simulation %d: Cond_max=%.2e, Cond_mean=%.2e, Problematic_iter=%d\n', ...
                        i, data.Cond_max(i), data.Cond_moyen(i), data.Iter_problematiques(i));
            end
        end
    elseif isfield(data, 'Nx_list')
        n_simulations = length(data.Nx_list);
        for i = 1:n_simulations
            if isfield(data, 'Cond_max') && isfield(data, 'Cond_moyen') && isfield(data, 'Iter_problematiques')
                fprintf('Simulation %d: Cond_max=%.2e, Cond_mean=%.2e, Problematic_iter=%d\n', ...
                        i, data.Cond_max(i), data.Cond_moyen(i), data.Iter_problematiques(i));
            end
        end
    else
        fprintf('Mesh information not available\n');
    end
    
    fprintf('Conditioning graphs generated.\n');
end






function comparer_cpu_seulement()
    % COMPARER_CPU_SEULEMENT - CPU time comparison only
    
    fprintf('\n--- CPU TIME COMPARISON ONLY ---\n');
    
    % Load all data
    [data_all, scheme_names] = charger_toutes_donnees_comparaison();
    
    % Create CPU only figure
    figure_cpu_comparaison_complete(data_all, scheme_names);
    
    fprintf('CPU figure created with %d schemes.\n', length(data_all));
end

function comparer_iterations_seulement()
    % COMPARER_ITERATIONS_SEULEMENT - Iterations comparison only
    
    fprintf('\n--- ITERATIONS COMPARISON ONLY ---\n');
    
    % Load all data
    [data_all, scheme_names] = charger_toutes_donnees_comparaison();
    
    % Create iterations only figure
    figure_iterations_comparaison_complete(data_all, scheme_names);
    
    fprintf('Iterations figure created with %d schemes.\n', length(data_all));
end

function comparer_erreurs_seulement()
    % COMPARER_ERREURS_SEULEMENT - L2 and H1 errors comparison
    
    fprintf('\n--- L2 AND H1 ERRORS COMPARISON ---\n');
    
    % Load all data
    [data_all, scheme_names] = charger_toutes_donnees_comparaison();
    
    % Create errors only figure
    figure_erreur_comparaison_complete(data_all, scheme_names);
    
    fprintf('Errors figure created with %d schemes.\n', length(data_all));
end


function comparer_conditionnement_seulement()
    % COMPARER_CONDITIONNEMENT_SEULEMENT - Conditioning comparison only
    
    fprintf('\n--- CONDITIONING COMPARISON ONLY ---\n');
    
    % Load all data
    [data_all, scheme_names] = charger_toutes_donnees_comparaison();
    
    % Create conditioning only figure
    figure_conditionnement_comparaison_complete(data_all, scheme_names);
    
    fprintf('Conditioning figure created with %d schemes.\n', length(data_all));
end








function figure_erreur_comparaison_complete(data_all, scheme_names)
    % FIGURE_ERREUR_COMPARAISON_COMPLETE - L2 and H1 errors figure
    % Version with bold dashed Newton and same colors

    figure('Position', [300, 100, 1200, 800], 'Name', 'Errors L2 and H1');

    % Exact colors as CPU figure
    colors = {
        [0, 0.4470, 0.7410],     % L-scheme (L=1) -> blue
        [0.4660, 0.6740, 0.1880],% L-scheme (L=0.15) -> green
        [0.2, 0.2, 0.2],         % Newton -> gray/black
        [0.4940, 0.1840, 0.5560],% (unused / backup)
        [0.8500, 0.3250, 0.0980] % (unused / backup)
    };

    % Keep one style per error type
    styles_L2 = {'-o', '-s', '-^', '-d', '--s'};  % L2: continuous lines
    styles_H1 = {'--o', '--s', '--^', '--d', ':s'}; % H1: dashed lines

    hold on;

    % Store text handles for draggable labels
    text_handles_L2 = [];
    text_handles_H1 = [];

    for i = 1:numel(data_all)
        data = data_all{i};
        scheme_name = scheme_names{i};
        color = colors{mod(i-1, numel(colors))+1};

        if ~isfield(data, 'h_values') || ~isfield(data, 'Erreur_L2')
            fprintf('Missing L2 fields for %s\n', scheme_name);
            continue;
        end

        % Data
        h = data.h_values(:);
        err_L2 = data.Erreur_L2(:);

        % Convert to 1/h
        x = 1 ./ h;
        [x, idx] = sort(x);
        err_L2 = err_L2(idx);

        % Same color for L2 with continuous style
        loglog(x, err_L2, styles_L2{mod(i-1, numel(styles_L2))+1}, ...
            'Color', color, ...
            'LineWidth', 5, ...
            'MarkerSize', 8, ...
            'MarkerFaceColor', color, ...
            'DisplayName', formatLegend([scheme_name ' L2']));

        % Add labels for L2 with \left( \right)
        for j = 1:length(x)
            label_text = formatScientific(err_L2(j));
            h_text_L2 = text(x(j), err_L2(j), ['$\left(' label_text '\right)$'], ...
                'FontSize', 20, 'FontWeight', 'bold', ...
                'Color', color, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'Interpreter', 'latex', ...
                'ButtonDownFcn', @startDrag);

            text_handles_L2 = [text_handles_L2, h_text_L2];
        end

        % Plot H1 if available
        if isfield(data, 'Erreur_H1')
            err_H1 = data.Erreur_H1(:);
            err_H1 = err_H1(idx);

            % Different color for H1 (darker)
            color_H1 = color * 0.6; % H1 darker than L2

            loglog(x, err_H1, styles_H1{mod(i-1, numel(styles_H1))+1}, ...
                'Color', color_H1, ...
                'LineWidth', 5, ...
                'MarkerSize', 8, ...
                'MarkerFaceColor', color_H1, ...
                'DisplayName', formatLegend([scheme_name ' H1']));

            % Add labels for H1 with \left( \right)
            for j = 1:length(x)
                label_text = formatScientific(err_H1(j));
                h_text_H1 = text(x(j), err_H1(j), ['$\left(' label_text '\right)$'], ...
                    'FontSize', 20, 'FontWeight', 'bold', ...
                    'Color', color_H1, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'top', ...
                    'Interpreter', 'latex', ...
                    'ButtonDownFcn', @startDrag);

                text_handles_H1 = [text_handles_H1, h_text_H1];
            end
        end
    end

    % Axes configuration with article style
    ax = gca;
    set(ax, 'XScale', 'log', 'YScale', 'log');
    ax.FontSize = 20;
    ax.FontWeight = 'bold';
    ax.LineWidth = 1.5;
    ax.Box = 'off';
    ax.TickDir = 'out';

    % Labels
    xlabel('1/h', 'FontSize', 20, 'FontWeight', 'bold');

    % Draggable legend with LaTeX interpreter
    h_legend = legend('Location', 'southwest', 'FontSize', 20, 'Box', 'on', ...
                      'Interpreter', 'latex');
    set(h_legend, 'ButtonDownFcn', @legendButtonDown);

    grid off;

    % Tick configuration
    xticks([0, 4, 8, 16, 32]);
    xticklabels({'0', '4', '8', '16', '32'});

    xlim([0, 33]);

    % White background
    set(gcf, 'Color', 'white');

    fprintf('Errors L2 and H1 figure created with different colors for L2 and H1\n');

    % === FUNCTION TO FORMAT LEGENDS ===
    function formatted_legend = formatLegend(name)
        % Format specifically for L=0.25, others remain simple
        if contains(name, 'L=0.25') && contains(name, 'L2')
            formatted_legend = '$\mathbf{L-scheme\ (L=0.25)\ L_2(\Omega)}$';
        elseif contains(name, 'L=0.25') && contains(name, 'H1')
            formatted_legend = '$\mathbf{L-scheme\ (L=0.25)\ H_1(\Omega)}$';
        else
            % For all other cases, keep the name as is
            formatted_legend = ['$\mathbf{' name '}$'];
        end
    end

    % === FUNCTION TO FORMAT a x 10^n ===
    function str = formatScientific(value)
        if value == 0
            str = '0';
            return;
        end

        exponent = floor(log10(value));
        mantissa = value / (10^exponent);

        % Adjust mantissa to have 1 digit before decimal
        if mantissa >= 10
            mantissa = mantissa / 10;
            exponent = exponent + 1;
        elseif mantissa < 1
            mantissa = mantissa * 10;
            exponent = exponent - 1;
        end

        % Format with 3 digits after decimal
        if exponent == 0
            str = sprintf('%.3f', mantissa);
        elseif exponent == 1
            str = sprintf('%.3f\\times10', mantissa);
        else
            str = sprintf('%.3f\\times10^{%d}', mantissa, exponent);
        end

        % Clean up .000 and .xxx0
        str = strrep(str, '.000\\times', '\\times');
        str = strrep(str, '.000}', '}');
        str = regexprep(str, '\.(\d*)0+\\times', '.$1\\times');
        str = regexprep(str, '\.(\d*)0+}', '.$1}');
    end

    % === FUNCTIONS TO DRAG ELEMENTS ===
    function legendButtonDown(~, ~)
        try
            set(gcf, 'WindowButtonMotionFcn', @legendDrag, ...
                     'WindowButtonUpFcn', @stopLegendDrag);
        catch
        end
    end

    function legendDrag(~, ~)
        try
            currentPoint = get(gcf, 'CurrentPoint');
            fig_pos = get(gcf, 'Position');
            legend_pos = [currentPoint(1)/fig_pos(3), currentPoint(2)/fig_pos(4), 0.2, 0.2];
            set(h_legend, 'Position', legend_pos);
        catch
        end
    end

    function stopLegendDrag(~, ~)
        try
            set(gcf, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
        catch
        end
    end

    function startDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', @dragText, ...
                 'WindowButtonUpFcn', @stopDrag);
    end

    function dragText(~, ~)
        try
            currentPoint = get(gca, 'CurrentPoint');
            h_text = gco;
            if isgraphics(h_text, 'text')
                newPos = [currentPoint(1,1), currentPoint(1,2), 0];
                set(h_text, 'Position', newPos);
            end
        catch
        end
    end

    function stopDrag(~, ~)
        set(gcf, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
    end
end


 
 

function [p, t, u, tm] = charger_donnees_temps(output_folder, nx, time)
    file_pattern = sprintf('solution_nx%d_t%.3fs.mat', nx, time);
    file_path = fullfile(output_folder, file_pattern);
    
    if ~exist(file_path, 'file')
        fprintf('File not found: %s\n', file_path);
        p = []; t = []; u = []; tm = [];
        return;
    end
    
    data = load(file_path);
    
    % --- solution u / u0 ---
    if isfield(data, 'u')
        u = data.u;
    elseif isfield(data, 'u0')
        u = data.u0;  % compatibility with older files
    else
        fprintf('Solution variable not found in file\n');
        p = []; t = []; u = []; tm = [];
        return;
    end
    
    p = data.p;
    t = data.t;

    % --- time tm: multiple possibilities ---
    if isfield(data, 'tm')
        tm = data.tm;
    elseif isfield(data, 't') && isscalar(data.t)
        tm = data.t;
    else
        % fallback: use the passed argument
        tm = time;
    end
    
    fprintf('Data loaded for t=%.3f\n', tm);
end

function time = choisir_temps(data, idx, output_folder)
    % Find all time files for this mesh
    nx = data.Nx_list(idx);
    pattern = sprintf('solution_nx%d_t*.mat', nx);
    files = dir(fullfile(output_folder, pattern));
    
    if isempty(files)
        fprintf('No files found for nx=%d\n', nx);
        time = [];
        return;
    end
    
    % Extract and display available times
    time_list = zeros(length(files), 1);
    for i = 1:length(files)
        [~, name] = fileparts(files(i).name);
        temp_str = regexp(name, 't([\d.]+)s', 'tokens');
        if ~isempty(temp_str)
            time_list(i) = str2double(temp_str{1}{1});
        end
    end
    
    [time_list, idx_sort] = sort(time_list);
    files = files(idx_sort);
    
    fprintf('\nAvailable times for nx=%d:\n', nx);
    for i = 1:length(time_list)
        fprintf('%d - t=%.2f\n', i, time_list(i));
    end
    
    choice = input('Select time: ');
    if choice < 1 || choice > length(time_list)
        fprintf('Invalid choice.\n');
        time = [];
        return;
    end
    
    time = time_list(choice);
end

function idx = choisir_maillage(data)
    if length(data.Nx_list) > 1
        fprintf('\nAvailable meshes:\n');
        for i = 1:length(data.Nx_list)
            fprintf('%d - nx=%d\n', i, data.Nx_list(i));
        end
        choice = input('Select mesh: ');
        if choice < 1 || choice > length(data.Nx_list)
            fprintf('Invalid choice.\n');
            idx = [];
            return;
        end
        idx = choice;
    else
        idx = 1;
    end
end