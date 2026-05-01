function start_gui()
%START_GUI Entry point to launch the Richards 3D graphical user interface
%   This function serves as the main launcher for the Richards 3D simulation GUI.
%   It performs the following operations:
%       1) Clears the command window and closes all open figures
%       2) (Optional) Cleans up old results folders to prevent data contamination
%       3) Locates the project root directory (portable GitHub version)
%       4) Adds src/, gui/, examples/ to the MATLAB path
%       5) Launches the main GUI interface (run_all_cases_gui)
%
%   INPUTS:
%       None
%
%   OUTPUTS:
%       None (launches GUI)
%
%   USAGE:
%       start_gui()
%
%   DEPENDENCIES:
%       - gui/run_all_cases_gui.m
%       - main.m at repository root
%       - src/ folder (FEM, models, solvers, utils)
%
%   NOTES:
%       - The function automatically finds the project root regardless
%         of where it is installed (portable for GitHub)
%       - Optional cleanup prevents data contamination between runs
%       - All necessary paths are added automatically
%
%   AUTHOR: Alhadiri MOELEVOU
%   ORGANIZATION: Université Clermont Auvergne - LIMOS
%   DATE:   20/02/2026
%   VERSION: 1.0
%
%   See also: RUN_ALL_CASES_GUI, MAIN

    clc;
    close all;

    % ===================== Locate project root ===========================
    % Find the repository root by climbing up until main.m or src/ is found
    baseDir = fileparts(mfilename('fullpath'));
    root    = baseDir;

    maxUp = 10;
    for k = 1:maxUp
        if exist(fullfile(root,'main.m'),'file') || isfolder(fullfile(root,'src'))
            break;
        end
        parent = fileparts(root);
        if strcmp(parent, root)
            error('Project root not found when climbing up from: %s', baseDir);
        end
        root = parent;
    end

    % ===================== Optional cleanup ==============================
    DO_CLEANUP = true;  % set false if you want to keep results between runs

    if DO_CLEANUP
        fprintf('Cleaning up old results folders...\n');
        folders = {'results_physical', 'results_validation', 'results'};
        for i = 1:numel(folders)
            folder_path = fullfile(root, folders{i});
            if exist(folder_path, 'dir')
                rmdir(folder_path, 's');  % recursive deletion
                fprintf('  Removed: %s\n', folder_path);
            end
        end
        fprintf('Cleanup completed.\n\n');
    end

    % ===================== Add paths =====================================
    gui_folder      = fullfile(root, 'gui');
    src_folder      = fullfile(root, 'src');
    examples_folder = fullfile(root, 'examples');

    if ~exist(gui_folder, 'dir')
        error('Folder "gui" not found at: %s', gui_folder);
    end

    % Add gui first (contains run_all_cases_gui)
    addpath(genpath(gui_folder));

    % Add core source code
    if exist(src_folder, 'dir')
        addpath(genpath(src_folder));
    else
        warning('Folder "src" not found at: %s (continuing anyway)', src_folder);
    end

    % Add examples (optional)
    if exist(examples_folder, 'dir')
        addpath(genpath(examples_folder));
    end

    % ===================== Launch GUI ====================================
    run_all_cases_gui();
end