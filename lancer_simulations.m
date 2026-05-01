function run_simulations()
% RUN_SIMULATIONS - Main launcher for Richards 3D simulations
% Executes simulations and launches visualization tool
%
% Usage: run_simulations

clear; clc; close all;

fprintf('\n========================================================================\n');
fprintf('   RICHARDS 3D SIMULATION LAUNCHER\n');
fprintf('========================================================================\n');

% Parent directory
parent_dir = pwd;

% Check for required folders
has_validation = exist(fullfile(parent_dir, 'VALIDATION'), 'dir');
has_physique = exist(fullfile(parent_dir, 'PHYSIQUE'), 'dir');
has_viz = exist(fullfile(parent_dir, 'Analyse_differentes_methodes.m'), 'file');

% Display available folders
fprintf('\nAvailable folders:\n');
if has_validation, fprintf('  [x] VALIDATION/\n'); end
if has_physique, fprintf('  [x] PHYSIQUE/\n'); end
if has_viz, fprintf('  [x] Analyse_differentes_methodes.m (visualization)\n'); end
fprintf('\n');

if ~has_validation && ~has_physique
    fprintf('ERROR: No simulation folder found.\n');
    fprintf('Place this script in the parent folder containing VALIDATION/ and PHYSIQUE/\n');
    return;
end

% =========================================================================
% MAIN MENU
% =========================================================================
while true
    fprintf('------------------------------------------------------------------------\n');
    fprintf('MAIN MENU\n');
    fprintf('------------------------------------------------------------------------\n');
    fprintf('  1. Run VALIDATION simulation\n');
    fprintf('  2. Run PHYSIQUE simulation\n');
    fprintf('  3. Run both simulations\n');
    fprintf('  4. Launch visualization only\n');
    fprintf('  5. Exit\n');
    fprintf('------------------------------------------------------------------------\n');
    
    choice = input('\nYour choice (1-5): ');
    
    switch choice
        case 1
            if ~has_validation
                fprintf('ERROR: VALIDATION folder not found.\n');
                continue;
            end
            run_single_simulation('VALIDATION', parent_dir);
            
        case 2
            if ~has_physique
                fprintf('ERROR: PHYSIQUE folder not found.\n');
                continue;
            end
            run_single_simulation('PHYSIQUE', parent_dir);
            
        case 3
            if has_validation
                run_single_simulation('VALIDATION', parent_dir);
            else
                fprintf('WARNING: VALIDATION not available, skipped.\n');
            end
            
            if has_physique
                run_single_simulation('PHYSIQUE', parent_dir);
            else
                fprintf('WARNING: PHYSIQUE not available, skipped.\n');
            end
            
            fprintf('\nBoth simulations completed.\n');
            launch_visualization(parent_dir);
            
        case 4
            launch_visualization(parent_dir);
            
        case 5
            fprintf('\nGoodbye.\n');
            break;
            
        otherwise
            fprintf('Invalid choice.\n');
    end
end

end

% =========================================================================
% RUN A SINGLE SIMULATION
% =========================================================================
function run_single_simulation(folder_name, parent_dir)
    
    fprintf('\n========================================================================\n');
    fprintf('RUNNING SIMULATION: %s\n', folder_name);
    fprintf('========================================================================\n');
    
    folder_path = fullfile(parent_dir, folder_name);
    
    if ~exist(folder_path, 'dir')
        fprintf('ERROR: Folder %s not found.\n', folder_name);
        return;
    end
    
    original_dir = pwd;
    cd(folder_path);
    
    % List available main files
    main_files = dir('main_*.m');
    
    if isempty(main_files)
        fprintf('ERROR: No main_*.m file found in %s\n', folder_name);
        cd(original_dir);
        return;
    end
    
    % Auto-select first main file
    main_file = main_files(1).name;
    fprintf('Executing: %s\n', main_file);
    
    % Save file name before execution
    executed_file = main_file;
    
    fprintf('Running...\n');
    tic;
    
    try
        run(executed_file);
        elapsed = toc;
        fprintf('\nSimulation %s completed in %.2f seconds.\n', folder_name, elapsed);
        success = true;
        
    catch ME
        elapsed = toc;
        fprintf('\nERROR while running %s:\n', executed_file);
        fprintf('  %s\n', ME.message);
        success = false;
    end
    
    cd(original_dir);
    
    if ~success
        fprintf('\nSimulation failed. Visualization skipped.\n');
        return;
    end
    
    fprintf('\n------------------------------------------------------------------------\n');
    run_viz = input('Launch visualization? (y/n) [y]: ', 's');
    if isempty(run_viz) || strcmpi(run_viz, 'y')
        launch_visualization(parent_dir);
    end
    
end

% =========================================================================
% LAUNCH VISUALIZATION TOOL
% =========================================================================
function launch_visualization(parent_dir)
    
    fprintf('\n========================================================================\n');
    fprintf('LAUNCHING VISUALIZATION\n');
    fprintf('========================================================================\n');
    
    original_dir = pwd;
    cd(parent_dir);
    
    viz_file = fullfile(parent_dir, 'Analyse_differentes_methodes.m');
    
    if exist(viz_file, 'file')
        fprintf('Starting visualization interface...\n');
        
        try
            Analyse_differentes_methodes;
            fprintf('\nVisualization completed.\n');
        catch ME
            fprintf('\nERROR in visualization tool:\n');
            fprintf('  %s\n', ME.message);
        end
    else
        fprintf('ERROR: Analyse_differentes_methodes.m not found.\n');
        fprintf('Make sure the file is in the same folder as this launcher.\n');
    end
    
    cd(original_dir);
    
end

