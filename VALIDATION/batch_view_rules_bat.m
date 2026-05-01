% function batch_view_rules_bat()
% %BATCH_VIEW_RULES_BAT Automated post-processing for Richards 3D simulations (NEWTON)
% %   Executes a fixed sequence of visualization routines without user input.
% %   ADAPTED FOR NEWTON SOLVER.
% 
%     % === ADD NECESSARY PATHS ===
%     root_dir = fileparts(mfilename('fullpath'));
% 
%     % Add all necessary subfolders to the path
%     addpath(root_dir);
%     addpath(fullfile(root_dir, 'FEM'));
%     addpath(fullfile(root_dir, 'models'));
%     addpath(fullfile(root_dir, 'solvers'));
%     addpath(fullfile(root_dir, 'utils'));
%     addpath(fullfile(root_dir, 'gui'));
%     addpath(fullfile(root_dir, 'visualization'));
%     % === END PATH CONFIGURATION ===
% 
%     fprintf('\n============================================\n');
%     fprintf(' BATCH VIEWER (AUTO-RUN) - NEWTON SOLVER\n');
%     fprintf('============================================\n');
% 
%     % --------- Option 1: Physical case (t=10, last nx) ----------
%     physical_case_t10_only();
% 
%     % --------- Option 2: Scheme comparison (3 figs) -------------
%     run_comparison_fixed_3figs();
% 
%     % --------- Option 3: Scheme Errors (3 figs) -------------
%     visualiser_tableau_erreur_L_Newton()
% 
%     fprintf('\n AUTO-RUN DONE (physical_case+comparison+Newton).\n');
% end
% 
% function visualiser_tableau_erreur_L_Newton()
% %VISUALISER_TABLEAU_ERREUR_L_NEWTON Interactive visualization of error tables for Newton method
% %   This function provides a graphical interface to select and visualize
% %   convergence error tables for different lambda (λ) parameter values.
% %
% %   WORKFLOW:
% %       1) Scans the numerical_validation/Newton directory for lambda_* folders
% %       2) Extracts and sorts available λ values
% %       3) Presents a dialog for single λ selection or "VIEW ALL TABLES" option
% %       4) Calls afficher_tableau_erreur_ameliore_Newton() to render LaTeX-quality tables
% %
% %   DEPENDENCIES:
% %       - Requires results/numerical_validation/Newton/ structure
% %       - Uses afficher_tableau_erreur_ameliore_Newton() for table rendering
% %
% %   OUTPUT:
% %       Displays formatted error tables in figure windows
% 
%     fprintf('\n--- Error Tables Visualization (Newton) ---\n');
% 
%     % Path to results folder
%     thisFileDir = fileparts(mfilename('fullpath'));
%     base_results_dir = fullfile(thisFileDir, 'results');
%     validation_dir = fullfile(base_results_dir, 'numerical_validation');
% 
%     if exist(validation_dir, 'dir') ~= 7
%         fprintf(' Missing folder: %s\n', validation_dir);
%         return;
%     end
% 
%     % Find all Newton folders
%     Newton_root = fullfile(validation_dir, 'Newton');
%     if exist(Newton_root, 'dir') ~= 7
%         fprintf(' Missing folder: %s\n', Newton_root);
%         return;
%     end
% 
%     % Find all lambda_* subdirectories (from dt directories)
%     lambda_dirs = dir(Newton_root);
%     lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
% 
%     % Collect all unique lambda values by scanning dt subdirectories
%     lambda_values = [];
%     lambda_paths = {};
% 
%     for k = 1:length(lambda_dirs)
%         lambda_name = lambda_dirs(k).name;
%         tok = regexp(lambda_name, 'lambda_([0-9_]+)', 'tokens', 'once');
%         if ~isempty(tok)
%             lambda_str = strrep(tok{1}, '_', '.');
%             lambda_val = str2double(lambda_str);
% 
%             % Look for dt subdirectories inside this lambda folder
%             dt_path = fullfile(Newton_root, lambda_name);
%             dt_dirs = dir(dt_path);
%             dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
% 
%             for d = 1:length(dt_dirs)
%                 % Check if resultats_complets exists
%                 data_file = fullfile(dt_path, dt_dirs(d).name, 'resultats_complets', 'resultats_complets.mat');
%                 if exist(data_file, 'file') == 2
%                     lambda_values = [lambda_values; lambda_val];
%                     lambda_paths{end+1} = fullfile(dt_path, dt_dirs(d).name);
%                 end
%             end
%         end
%     end
% 
%     if isempty(lambda_values)
%         fprintf(' No lambda folders with valid data found\n');
%         return;
%     end
% 
%     % Remove duplicates and sort
%     [lambda_values_unique, idx_unique] = unique(lambda_values);
%     lambda_paths_unique = lambda_paths(idx_unique);
% 
%     % Sort by lambda value
%     [lambda_values_sorted, sort_idx] = sort(lambda_values_unique);
%     lambda_paths_sorted = lambda_paths_unique(sort_idx);
% 
%     lambda_names = {};
%     for k = 1:length(lambda_values_sorted)
%         lambda_names{end+1} = sprintf('λ = %.4f', lambda_values_sorted(k));
%     end
% 
%     % Add option to view all tables
%     lambda_names{end+1} = 'VIEW ALL TABLES';
% 
%     % Dialog box to choose λ value
%     [selection_idx, ok] = listdlg(...
%         'PromptString', 'Select λ value to visualize:', ...
%         'SelectionMode', 'single', ...
%         'ListString', lambda_names, ...
%         'Name', 'λ Selection (Newton)', ...
%         'ListSize', [350, 350], ...
%         'OKString', 'Visualize', ...
%         'CancelString', 'Cancel');
% 
%     if ~ok || isempty(selection_idx)
%         fprintf(' Visualization cancelled.\n');
%         return;
%     end
% 
%     % If user chose "VIEW ALL TABLES"
%     if selection_idx == length(lambda_names)
%         for i = 1:length(lambda_paths_sorted)
%             afficher_tableau_erreur_ameliore_Newton(lambda_paths_sorted{i}, lambda_values_sorted(i));
%         end
%     else
%         % Display table for selected λ value
%         afficher_tableau_erreur_ameliore_Newton(lambda_paths_sorted{selection_idx}, lambda_values_sorted(selection_idx));
%     end
% 
%     fprintf(' Visualization completed.\n');
% end
% 
% function afficher_tableau_erreur_ameliore_Newton(results_dir, lambda_val)
% %AFFICHER_TABLEAU_ERREUR_AMELIORE_NEWTON Publication-quality error table for Q1 journals (Newton)
% %   Generates a visually elegant table using MATLAB annotations to display
% %   convergence errors for the Newton method with a given λ parameter.
% %
% %   INPUTS:
% %       results_dir : string, path to the Newton results directory
% %                    Expected structure: .../lambda_X/dt_Y/resultats_complets/
% %       lambda_val  : double, numeric value of λ for display purposes
% %
% %   DATA SOURCE:
% %       Expects resultats_complets/resultats_complets.mat with fields:
% %           - h_values   : vector, mesh sizes
% %           - Erreur_L2  : vector, L2 errors
% %           - Erreur_H1  : vector, H1 errors (optional)
% %
% %   OUTPUT:
% %       Creates a publication-ready figure with:
% %           - Formatted table showing 1/h, L2 error, H1 error, convergence order
% %           - Statistical summary box with minimum error and average order
% %           - Interactive "Change λ" button for exploration
% 
%     % Construct full path to data file
%     data_file = fullfile(results_dir, 'resultats_complets', 'resultats_complets.mat');
% 
%     % Check if data file exists
%     if exist(data_file, 'file') ~= 2
%         fprintf(' No data found for λ = %.4f\n', lambda_val);
%         return;
%     end
% 
%     % Load the data
%     data = load(data_file);
% 
%     % Verify required fields are present
%     if ~isfield(data, 'h_values') || ~isfield(data, 'Erreur_L2')
%         fprintf(' Missing fields (h_values / Erreur_L2) for λ = %.4f\n', lambda_val);
%         return;
%     end
% 
%     % ---- Figure creation (clean, publication-friendly) ----
%     fig = figure('Position', [150, 150, 1100, 700], ...
%         'Name', sprintf('Error Analysis - Newton λ = %.4f', lambda_val), ...
%         'NumberTitle', 'off', ...
%         'Color', [1 1 1]);
% 
%     % --- Button to switch λ interactively ---
%     uicontrol('Parent', fig, ...
%         'Style', 'pushbutton', ...
%         'String', 'Change λ', ...
%         'Units', 'normalized', ...
%         'Position', [0.82, 0.92, 0.14, 0.055], ...
%         'FontSize', 12, ...
%         'FontWeight', 'bold', ...
%         'Callback', @(~,~) switch_lambda_and_refresh(fig, results_dir, lambda_val));
% 
%     % Global typography choices
%     fontNameBody  = 'Times New Roman';
%     fontSizeTitle = 24;
%     fontSizeHead  = 18;
%     fontSizeBody  = 16;
% 
%     % Color palette (soft, journal-like)
%     colTitle   = [0.10 0.20 0.45];
%     colBorder  = [0.55 0.62 0.78];
%     colGrid    = [0.80 0.86 0.94];
%     colHeader  = [0.92 0.95 1.00];
%     colRowA    = [1.00 1.00 1.00];
%     colRowB    = [0.97 0.985 1.00];
%     colStatsBG = [0.95 0.98 1.00];
% 
%     % ---- Title ----
%     annotation('textbox', [0.12, 0.905, 0.76, 0.07], ...
%         'String', sprintf('Error Analysis for Newton method: $\\lambda = %.4f$', lambda_val), ...
%         'FontSize', fontSizeTitle, ...
%         'FontWeight', 'bold', ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'middle', ...
%         'EdgeColor', 'none', ...
%         'Interpreter', 'latex', ...
%         'Color', colTitle);
% 
%     % ---- Compute x = h and ensure ordering (increasing refinement) ----
%     un_sur_h = 1 ./ data.h_values(:);
% 
%     % Sort rows by h (ascending) to keep table consistent
%     [un_sur_h, idx] = sort(un_sur_h, 'ascend');
%     errL2 = data.Erreur_L2(:);
%     errL2 = errL2(idx);
% 
%     % Check if H1 errors are available
%     hasH1 = isfield(data, 'Erreur_H1');
%     if hasH1
%         errH1 = data.Erreur_H1(:);
%         errH1 = errH1(idx);
%     end
% 
%     nx_vals = round(un_sur_h);  % used for display "1/nx"
% 
%     % ---- Layout geometry (normalized coordinates) ----
%     left   = 0.10;
%     right  = 0.90;
%     top    = 0.80;
%     bottom = 0.30;
% 
%     W = right - left;
%     H = top - bottom;
% 
%     nRows = numel(nx_vals);
%     rowH  = H / (nRows+1);          % +1 for header row
%     colW  = W / 4;                  % 4 columns: 1/h, L2, H1, Order
% 
%     % Column x positions (left edges)
%     x0 = left;
%     x1 = x0+colW;
%     x2 = x1+colW;
%     x3 = x2+colW;
% 
%     % Column centers for text alignment
%     xCenters = [x0+colW/2, x1+colW/2, x2+colW/2, x3+colW/2];
% 
%     % ---- Outer table border ----
%     annotation('rectangle', [left, bottom, W, H], ...
%         'EdgeColor', colBorder, 'LineWidth', 2, 'FaceColor', 'none');
% 
%     % ---- Header background row ----
%     annotation('rectangle', [left, top-rowH, W, rowH], ...
%         'FaceColor', colHeader, 'EdgeColor', 'none');
% 
%     % ---- Header text ----
%     headers = {'$1/h$', '$L_2$ error', '$H_1$ error', 'Order'};
%     for c = 1:4
%         annotation('textbox', [xCenters(c)-colW/2, top-rowH, colW, rowH], ...
%             'String', headers{c}, ...
%             'FontSize', fontSizeHead, ...
%             'FontWeight', 'bold', ...
%             'HorizontalAlignment', 'center', ...
%             'VerticalAlignment', 'middle', ...
%             'EdgeColor', 'none', ...
%             'Interpreter', 'latex', ...
%             'Color', [0 0 0]);
%     end
% 
%     % ---- Vertical grid lines ----
%     for x = [x1, x2, x3]
%         annotation('line', [x, x], [bottom, top], ...
%             'Color', colGrid, 'LineWidth', 1);
%     end
% 
%     % Initialize array to store convergence orders for statistics
%     orders = [];
% 
%     % ---- Fill table rows ----
%     for i = 1:nRows
%         % Calculate row y-position (from top)
%         yRow = top - rowH*(i+1);
% 
%         % Alternate row background colors for better readability
%         bg = colRowA;
%         if mod(i,2) == 0
%             bg = colRowB;
%         end
%         annotation('rectangle', [left, yRow, W, rowH], ...
%             'FaceColor', bg, 'EdgeColor', 'none');
% 
%         % ---- Column 1: 1/h ----
%         cell1 = sprintf('$1/%d$', nx_vals(i));
% 
%         % ---- Column 2: L2 error (scientific notation) ----
%         [m2, e2] = format_scientific(errL2(i));
%         cell2 = sprintf('$%.2f \\times 10^{%d}$', m2, e2);
% 
%         % ---- Column 3: H1 error (if available) ----
%         if hasH1
%             [m1, e1] = format_scientific(errH1(i));
%             cell3 = sprintf('$%.2f \\times 10^{%d}$', m1, e1);
%         else
%             cell3 = '$-$';
%         end
% 
%         % ---- Column 4: Convergence order ----
%         if i < nRows
%             % Calculate order between current and next mesh level
%             ord = log10(errL2(i)/errL2(i+1)) / log10(2);
%             orders = [orders, ord];  % Store for statistics
%             cell4 = sprintf('$%.2f$', ord);
%         else
%             cell4 = '$-$';
%         end
% 
%         % Create cell array for this row
%         rowCells = {cell1, cell2, cell3, cell4};
% 
%         % Place all four cells in this row
%         for c = 1:4
%             annotation('textbox', [xCenters(c)-colW/2, yRow, colW, rowH], ...
%                 'String', rowCells{c}, ...
%                 'FontName', fontNameBody, ...
%                 'FontSize', fontSizeBody, ...
%                 'HorizontalAlignment', 'center', ...
%                 'VerticalAlignment', 'middle', ...
%                 'EdgeColor', 'none', ...
%                 'Interpreter', 'latex', ...
%                 'Color', [0 0 0]);
%         end
%     end
% 
%     % ---- Horizontal grid lines between rows ----
%     for i = 1:nRows
%         y = top - rowH*(i+1);
%         annotation('line', [left, right], [y, y], ...
%             'Color', colGrid, 'LineWidth', 1);
%     end
% 
%     % ---- Statistics box (LaTeX formatted) ----
%     % Find minimum error and its location
%     [min_err, min_idx] = min(errL2);
%     [m_min, e_min] = format_scientific(min_err);
% 
%     % Calculate average convergence order
%     if isempty(orders)
%         avg_order = NaN;
%     else
%         avg_order = mean(orders);
%     end
% 
%     % Format statistics text
%     if ~isnan(avg_order)
%         stats_text = sprintf(['Best performance (Newton)\n' ...
%             'Minimum L2 error: $%.2f \\times 10^{%d}$  (1/%d)\n' ...
%             'Average order: $%.2f$'], ...
%             m_min, e_min, nx_vals(min_idx), avg_order);
%     else
%         stats_text = sprintf(['Best performance (Newton)\n' ...
%             'Minimum L2 error: $%.2f \\times 10^{%d}$  (1/%d)\n' ...
%             'Average order: N/A'], ...
%             m_min, e_min, nx_vals(min_idx));
%     end
% 
%     % Add statistics box to figure
%     annotation('textbox', [0.22, 0.08, 0.56, 0.14], ...
%         'String', stats_text, ...
%         'FontName', fontNameBody, ...
%         'FontSize', 16, ...
%         'HorizontalAlignment', 'center', ...
%         'VerticalAlignment', 'middle', ...
%         'EdgeColor', colBorder, ...
%         'LineWidth', 2, ...
%         'BackgroundColor', colStatsBG, ...
%         'Interpreter', 'latex', ...
%         'Color', colTitle);
% 
%     % Console feedback
%     fprintf(' Elegant table displayed for λ = %.4f (Newton)\n', lambda_val);
%     fprintf('   - Number of mesh levels: %d\n', nRows);
%     fprintf('   - Average convergence order: %.2f\n', avg_order);
%     fprintf('   - Minimum L2 error: %.2e\n', min_err);
% end
% 
% function switch_lambda_and_refresh(figHandle, current_results_dir, current_lambda_val)
% %SWITCH_LAMBDA_AND_REFRESH Open a list of available λ folders and refresh the figure
% 
%     % Navigate up to Newton root directory
%     Newton_root = fileparts(fileparts(current_results_dir)); % .../Newton
%     if exist(Newton_root, 'dir') ~= 7
%         errordlg(sprintf('Folder not found:\n%s', Newton_root), 'Error');
%         return;
%     end
% 
%     % Find all lambda_* directories
%     lambda_dirs = dir(Newton_root);
%     lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
% 
%     % Collect all unique lambda values with their paths
%     lambda_values = [];
%     lambda_paths = {};
% 
%     for k = 1:length(lambda_dirs)
%         name = lambda_dirs(k).name;
%         tok = regexp(name, 'lambda_([0-9_]+)', 'tokens', 'once');
%         if ~isempty(tok)
%             lambda_str = strrep(tok{1}, '_', '.');
%             lambda_val = str2double(lambda_str);
% 
%             % Look for dt subdirectories
%             dt_path = fullfile(Newton_root, name);
%             dt_dirs = dir(dt_path);
%             dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
% 
%             for d = 1:length(dt_dirs)
%                 data_file = fullfile(dt_path, dt_dirs(d).name, 'resultats_complets', 'resultats_complets.mat');
%                 if exist(data_file, 'file') == 2
%                     lambda_values = [lambda_values; lambda_val];
%                     lambda_paths{end+1} = fullfile(dt_path, dt_dirs(d).name);
%                 end
%             end
%         end
%     end
% 
%     if isempty(lambda_values)
%         errordlg('No lambda folders with valid data found.', 'Error');
%         return;
%     end
% 
%     % Remove duplicates and sort
%     [lambda_values_unique, idx_unique] = unique(lambda_values);
%     lambda_paths_unique = lambda_paths(idx_unique);
% 
%     [lambda_values_sorted, idx_sorted] = sort(lambda_values_unique);
%     lambda_paths_sorted = lambda_paths_unique(idx_sorted);
% 
%     % Build list display
%     items = cell(numel(lambda_values_sorted), 1);
%     for k = 1:numel(lambda_values_sorted)
%         items{k} = sprintf('λ = %.6g', lambda_values_sorted(k));
%     end
% 
%     % Preselect current λ if possible
%     preSel = find(abs(lambda_values_sorted - current_lambda_val) < 1e-12, 1);
%     if isempty(preSel), preSel = 1; end
% 
%     [sel, okDlg] = listdlg( ...
%         'PromptString', 'Select λ value:', ...
%         'SelectionMode', 'single', ...
%         'ListString', items, ...
%         'InitialValue', preSel, ...
%         'ListSize', [300, 300], ...
%         'Name', 'Choose λ (Newton)');
% 
%     if ~okDlg || isempty(sel)
%         return;
%     end
% 
%     new_lambda = lambda_values_sorted(sel);
%     new_results_dir = lambda_paths_sorted{sel};
% 
%     % Close current figure and open the selected one
%     if isvalid(figHandle)
%         close(figHandle);
%     end
%     afficher_tableau_erreur_ameliore_Newton(new_results_dir, new_lambda);
% end
% 
% function [m, e] = format_scientific(x)
% %FORMAT_SCIENTIFIC Convert numeric value to mantissa-exponent representation
%     if x == 0
%         m = 0;
%         e = 0;
%         return;
%     end
%     e = floor(log10(abs(x)));
%     m = x / 10^e;
%     m = round(m * 100) / 100;
% end
% 
% function physical_case_t10_only()
% %PHYSICAL_CASE_T10_ONLY Interactive visualization of physical case results (NEWTON)
% %   Displays isosurface and cross-sectional cut at x=0.5 for the physical case.
% %   The user can select multiple time steps interactively from available solution files
% %   using a checkbox list interface.
% %
% %   MODIFIED FOR NEWTON SOLVER
% 
%     clc;
% 
%     FIG_POS = [100, 100, 1000, 800];
%     thisFileDir       = fileparts(mfilename('fullpath'));
%     base_results_dir   = fullfile(thisFileDir, 'results');  % absolute path
%     case_root          = fullfile(base_results_dir, 'physical_case');
% 
%     % ------------------------------------------------------------
%     % 1) Auto-detection of Newton folder with most recent solutions
%     % ------------------------------------------------------------
%     scheme_root = fullfile(case_root, 'Newton');
%     if exist(scheme_root,'dir') ~= 7
%         fprintf(' Missing: %s\n', scheme_root);
%         return;
%     end
% 
%     % Find all lambda_* directories
%     lambda_dirs = dir(scheme_root);
%     lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
% 
%     if isempty(lambda_dirs)
%         fprintf(' No lambda folder found in: %s\n', scheme_root);
%         return;
%     end
% 
%     bestIdx = [];
%     bestTime = -inf;
% 
%     for k = 1:numel(lambda_dirs)
%         cand = fullfile(scheme_root, lambda_dirs(k).name);
% 
%         % Look for dt subdirectories
%         dt_dirs = dir(cand);
%         dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
% 
%         for d = 1:numel(dt_dirs)
%             sol_dir_k = fullfile(cand, dt_dirs(d).name, 'solutions_temporelles');
%             if exist(sol_dir_k,'dir') ~= 7
%                 continue;
%             end
% 
%             fsol = dir(fullfile(sol_dir_k, 'solution_nx*_t*s.mat'));
%             if isempty(fsol)
%                 continue;
%             end
% 
%             newestFileTime = max([fsol.datenum]);
%             if newestFileTime > bestTime
%                 bestTime = newestFileTime;
%                 bestIdx = struct('lambda_dir', lambda_dirs(k).name, 'dt_dir', dt_dirs(d).name);
%             end
%         end
%     end
% 
%     if isempty(bestIdx)
%         fprintf(' No lambda folder with solution files found under: %s\n', scheme_root);
%         return;
%     end
% 
%     chosen_dir = fullfile(scheme_root, bestIdx.lambda_dir, bestIdx.dt_dir);
%     fprintf('\n Using physical_case Newton folder (with newest solutions):\n   %s\n', chosen_dir);
% 
%     results_dir = fullfile(chosen_dir, 'resultats_complets');
%     sol_dir     = fullfile(chosen_dir, 'solutions_temporelles');
% 
%     fprintf('\n--- PHYSICAL CASE (NEWTON) | INTERACTIVE TIME SELECTION ---\n');
% 
%     if exist(results_dir,'dir') ~= 7
%         fprintf(' Missing: %s\n', results_dir);
%         return;
%     end
%     if exist(sol_dir,'dir') ~= 7
%         fprintf(' Missing: %s\n', sol_dir);
%         return;
%     end
% 
%     % ------------------------------------------------------------
%     % 2) Determine finest available mesh resolution (maximum Nx)
%     % ------------------------------------------------------------
%     files = dir(fullfile(sol_dir, 'solution_nx*_t*s.mat'));
%     if isempty(files)
%         fprintf(' No solution_nx*_t*s.mat files in: %s\n', sol_dir);
%         return;
%     end
% 
%     nxVals = nan(numel(files),1);
%     for i = 1:numel(files)
%         tok = regexp(files(i).name, 'solution_nx(\d+)_', 'tokens', 'once');
%         if ~isempty(tok)
%             nxVals(i) = str2double(tok{1});
%         end
%     end
%     nxVals = nxVals(isfinite(nxVals));
%     if isempty(nxVals)
%         fprintf(' Unable to extract nx from filenames in: %s\n', sol_dir);
%         return;
%     end
%     nx = max(nxVals);
% 
%     % ------------------------------------------------------------
%     % 3) Get available times for the selected nx and let user choose
%     % ------------------------------------------------------------
%     pattern    = sprintf('solution_nx%d_t*.mat', nx);
%     time_files = dir(fullfile(sol_dir, pattern));
% 
%     if isempty(time_files)
%         fprintf(' No solution files found for nx=%d\n', nx);
%         return;
%     end
% 
%     time_values  = [];
%     time_strings = {};
% 
%     for i = 1:numel(time_files)
%         tok = regexp(time_files(i).name, '_t([0-9.eE+-]+)s\.mat', 'tokens', 'once');
%         if ~isempty(tok)
%             t_val = str2double(tok{1});
%             if isfinite(t_val)
%                 time_values  = [time_values; t_val];
%                 time_strings = [time_strings; {sprintf('t = %.6g h', t_val)}];
%             end
%         end
%     end
% 
%     if isempty(time_values)
%         fprintf(' Unable to extract time values from filenames\n');
%         return;
%     end
% 
%     % Sort ascending time
%     [time_values, sort_idx] = sort(time_values, 'ascend');
%     time_strings            = time_strings(sort_idx);
% 
%     % ------------------------------------------------------------
%     % 3b) Checkbox UI (FIXED so last time is NOT hidden by buttons)
%     % ------------------------------------------------------------
%     n            = length(time_strings);
%     rowH         = 30;
%     titleH       = 40;
%     bottomMargin = 90;
%     topMargin    = 20;
% 
%     figW = 520;
%     figH = bottomMargin + rowH*n + titleH + topMargin;
% 
%     sel_fig = figure('Name', 'Select Time Steps (Newton)', ...
%         'NumberTitle', 'off', ...
%         'Position', [500, 350, figW, figH], ...
%         'MenuBar', 'none', ...
%         'ToolBar', 'none', ...
%         'Resize', 'off', ...
%         'Color', [0.94 0.94 0.94]);
% 
%     % Title
%     uicontrol('Style', 'text', ...
%         'Position', [30, bottomMargin + rowH*n + 10, figW-60, titleH-10], ...
%         'String', sprintf('Select time steps to visualize (nx = %d - Newton):', nx), ...
%         'FontSize', 14, ...
%         'FontWeight', 'bold', ...
%         'BackgroundColor', [0.94 0.94 0.94]);
% 
%     % Checkboxes
%     checkboxes = gobjects(n,1);
%     for i = 1:n
%         y = bottomMargin + rowH*(n - i);
%         checkboxes(i) = uicontrol('Style', 'checkbox', ...
%             'Position', [40, y, figW-120, 28], ...
%             'String', time_strings{i}, ...
%             'FontSize', 12, ...
%             'Value', 0);
%     end
% 
%     % Buttons (in reserved bottom margin)
%     uicontrol('Style', 'pushbutton', ...
%         'Position', [150, 25, 100, 35], ...
%         'String', 'Select All', ...
%         'FontSize', 11, ...
%         'FontWeight', 'bold', ...
%         'Callback', @(~,~) set(checkboxes, 'Value', 1));
% 
%     uicontrol('Style', 'pushbutton', ...
%         'Position', [260, 25, 100, 35], ...
%         'String', 'Clear All', ...
%         'FontSize', 11, ...
%         'FontWeight', 'bold', ...
%         'Callback', @(~,~) set(checkboxes, 'Value', 0));
% 
%     uicontrol('Style', 'pushbutton', ...
%         'Position', [380, 25, 80, 35], ...
%         'String', 'OK', ...
%         'FontSize', 12, ...
%         'FontWeight', 'bold', ...
%         'Callback', 'uiresume(gcbf)');
% 
%     uicontrol('Style', 'pushbutton', ...
%         'Position', [40, 25, 80, 35], ...
%         'String', 'Cancel', ...
%         'FontSize', 12, ...
%         'Callback', @(~,~) close(sel_fig));
% 
%     uiwait(sel_fig);
% 
%     if ~isvalid(sel_fig)
%         fprintf(' Visualization cancelled by user.\n');
%         return;
%     end
% 
%     sel_indices = find([checkboxes.Value] == 1);
%     close(sel_fig);
% 
%     if isempty(sel_indices)
%         fprintf(' No time steps selected. Visualization cancelled.\n');
%         return;
%     end
% 
%     selected_times = time_values(sel_indices);
%     fprintf(' Selected %d time(s) for visualization (Newton)\n', length(selected_times));
%     for i = 1:length(selected_times)
%         fprintf('   - t = %.6g h\n', selected_times(i));
%     end
% 
%     % ------------------------------------------------------------
%     % 4) Cut parameters
%     % ------------------------------------------------------------
%     cut_mode = 2;   % x constant
%     cut_val  = 0.5;
% 
%     % ------------------------------------------------------------
%     % 5) Generate visualizations for each selected time
%     % ------------------------------------------------------------
%     for t_idx = 1:length(selected_times)
%         t_fixed = selected_times(t_idx);
% 
%         fprintf('\n Generating visualizations for t = %.6g h (%d/%d) - Newton\n', ...
%             t_fixed, t_idx, length(selected_times));
% 
%         % ISOSURFACE
%         figure('Position', FIG_POS, ...
%             'Name', sprintf('Isosurface (Newton) | t=%.6g h', t_fixed), ...
%             'Color','w');
%         show_isosurface_from_file(sol_dir, nx, t_fixed);
% 
%         title({sprintf('Isosurface at $t = %.4f$ h (Newton)', t_fixed); ...
%                sprintf('$\\mathit{h} = 1/(%d-1)$', nx)}, ...
%             'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
%         drawnow;
% 
%         % CUT
%         figure('Position', FIG_POS, ...
%             'Name', sprintf('Cross-section x=%.2f (Newton) | t=%.6g h', cut_val, t_fixed), ...
%             'Color','w');
%         show_cut_from_file(sol_dir, nx, t_fixed, cut_mode, cut_val);
% 
%         title({sprintf('Cross-section at $t = %.4f$ h (Newton)', t_fixed); ...
%                sprintf('$\\mathit{h} = 1/(%d-1)$', nx)}, ...
%             'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
%         drawnow;
%     end
% 
%     fprintf('\n Done: %d time(s) displayed for physical case (Newton).\n', length(selected_times));
% end
% 
% function run_comparison_fixed_3figs()
% %RUN_COMPARISON_FIXED_3FIGS Generate three standard comparison figures for numerical schemes
% %   This function loads precomputed data for all available numerical schemes and
% %   generates three fixed-format figures for performance analysis:
% %       1) CPU time comparison across mesh resolutions
% %       2) Nonlinear iteration counts comparison
% %       3) Matrix condition numbers comparison
% %
% %   DATA LOADING:
% %       Uses charger_toutes_donnees_comparaison() to load structured data containing:
% %           - CPU times for each scheme and mesh size
% %           - Iteration counts for each scheme
% %           - Condition numbers for each scheme
% %
% %   FIGURE GENERATION:
% %       Calls three dedicated figure functions (if available):
% %           - figure_cpu_comparaison_complete()
% %           - figure_iterations_comparaison_complete()
% %           - figure_conditionnement_comparaison_complete()
% 
%     fprintf('\n--- SCHEME COMPARISON (CPU+Iter+Cond only) ---\n');
% 
%     if exist('charger_toutes_donnees_comparaison','file') ~= 2
%         fprintf(' Missing function: charger_toutes_donnees_comparaison\n');
%         return;
%     end
% 
%     [donnees, noms_schemas] = charger_toutes_donnees_comparaison();
% 
%     if isempty(donnees)
%         fprintf(' No scheme data loaded.\n');
%         return;
%     end
% 
%     % CPU time comparison figure
%     if exist('figure_cpu_comparaison_complete','file') == 2
%         figure_cpu_comparaison_complete(donnees, noms_schemas);
%     else
%         fprintf(' Missing: figure_cpu_comparaison_complete\n');
%     end
% 
%     % Iteration count comparison figure
%     if exist('figure_iterations_comparaison_complete','file') == 2
%         figure_iterations_comparaison_complete(donnees, noms_schemas);
%     else
%         fprintf(' Missing: figure_iterations_comparaison_complete\n');
%     end
% 
%     % Matrix condition number comparison figure
%     if exist('figure_conditionnement_comparaison_complete','file') == 2
%         figure_conditionnement_comparaison_complete(donnees, noms_schemas);
%     else
%         fprintf(' Missing: figure_conditionnement_comparaison_complete\n');
%     end
% 
%     fprintf(' Comparison display done.\n');
% end
% 
% % function batch_view_rules_bat()
% % %BATCH_VIEW_RULES_BAT Automated post-processing for Richards 3D simulations
% % %   Executes a fixed sequence of visualization routines without user input.
% % 
% %     % === ADD NECESSARY PATHS ===
% %     root_dir = fileparts(mfilename('fullpath'));
% % 
% %     % Add all necessary subfolders to the path
% %     addpath(root_dir);
% %     addpath(fullfile(root_dir, 'FEM'));
% %     addpath(fullfile(root_dir, 'models'));
% %     addpath(fullfile(root_dir, 'solvers'));
% %     addpath(fullfile(root_dir, 'utils'));
% %     addpath(fullfile(root_dir, 'gui'));
% %     addpath(fullfile(root_dir, 'visualization'));  % NOUVEAU DOSSIER
% %     % === END PATH CONFIGURATION ===
% % 
% %     fprintf('\n============================================\n');
% %     fprintf(' BATCH VIEWER (AUTO-RUN) - NO INPUTS\n');
% %     fprintf('============================================\n');
% % 
% %     % --------- Option 1: Physical case (t=10, last nx) ----------
% %     physical_case_t10_only();
% % 
% %     % --------- Option 2: Scheme comparison (3 figs) -------------
% %    run_comparison_fixed_3figs(); %On désactive  vu qu'on utilise l'autre
% %    % interface graphique 
% % 
% %     % --------- Option 3: Scheme Errors (3 figs) -------------
% %     visualiser_tableau_erreur_L()
% % 
% %     fprintf('\n AUTO-RUN DONE (physical_case+comparison).\n');
% % end
% % 
% % 
% % function visualiser_tableau_erreur_L()
% % %VISUALISER_TABLEAU_ERREUR_L Interactive visualization of error tables for L-scheme values
% % %   This function provides a graphical interface to select and visualize
% % %   convergence error tables for different L parameter values.
% % %
% % %   WORKFLOW:
% % %       1) Scans the numerical_validation/L-scheme directory for L=* folders
% % %       2) Extracts and sorts available L values
% % %       3) Presents a dialog for single L selection or "VIEW ALL TABLES" option
% % %       4) Calls afficher_tableau_erreur_ameliore() to render LaTeX-quality tables
% % %
% % %   DEPENDENCIES:
% % %       - Requires results/numerical_validation/L-scheme/ structure
% % %       - Uses afficher_tableau_erreur_ameliore() for table rendering
% % %
% % %   OUTPUT:
% % %       Displays formatted error tables in figure windows
% % %
% % %   NOTE:
% % %       Designed to be called from batch_view_rules_bat() for automated
% % %       post-processing workflows.
% % 
% %     fprintf('\n--- Error Tables Visualization ---\n');
% % 
% %     % Path to results folder
% %     thisFileDir = fileparts(mfilename('fullpath'));
% %     base_results_dir = fullfile(thisFileDir, 'results');
% %     validation_dir = fullfile(base_results_dir, 'numerical_validation');
% % 
% %     if exist(validation_dir, 'dir') ~= 7
% %         fprintf(' Missing folder: %s\n', validation_dir);
% %         return;
% %     end
% % 
% %     % Find all L-scheme folders
% %     L_root = fullfile(validation_dir, 'L-scheme');
% %     if exist(L_root, 'dir') ~= 7
% %         fprintf(' Missing folder: %s\n', L_root);
% %         return;
% %     end
% % 
% %     L_dirs = dir(fullfile(L_root, 'L=*'));
% %     L_dirs = L_dirs([L_dirs.isdir]);
% % 
% %     if isempty(L_dirs)
% %         fprintf(' No L=* folders found\n');
% %         return;
% %     end
% % 
% %     % Extract available L values
% %     L_values = [];
% %     L_names = {};
% %     for k = 1:length(L_dirs)
% %         L_name = L_dirs(k).name;
% %         tok = regexp(L_name, 'L=([0-9.eE+-]+)', 'tokens', 'once');
% %         if ~isempty(tok)
% %             L_val = str2double(tok{1});
% %             L_values = [L_values; L_val];
% %             L_names{end+1} = sprintf('L = %.4f', L_val);
% %         end
% %     end
% % 
% %     % Sort by L value
% %     [L_values_sorted, sort_idx] = sort(L_values);
% %     L_names_sorted = L_names(sort_idx);
% % 
% %     % Add option to view all tables
% %     L_names_sorted{end+1} = 'VIEW ALL TABLES';
% % 
% %     % Dialog box to choose L value
% %     [selection_idx, ok] = listdlg(...
% %         'PromptString', 'Select L value to visualize:', ...
% %         'SelectionMode', 'single', ...
% %         'ListString', L_names_sorted, ...
% %         'Name', 'L Selection', ...
% %         'ListSize', [350, 350], ...
% %         'OKString', 'Visualize', ...
% %         'CancelString', 'Cancel');
% % 
% %     if ~ok || isempty(selection_idx)
% %         fprintf(' Visualization cancelled.\n');
% %         return;
% %     end
% % 
% %     % If user chose "VIEW ALL TABLES"
% %     if selection_idx == length(L_names_sorted)
% %         for i = 1:length(L_dirs)
% %             L_dir = fullfile(L_root, L_dirs(sort_idx(i)).name);
% %             afficher_tableau_erreur_ameliore(L_dir, L_values_sorted(i));
% %         end
% %     else
% %         % Display table for selected L value
% %         L_dir = fullfile(L_root, L_dirs(sort_idx(selection_idx)).name);
% %         afficher_tableau_erreur_ameliore(L_dir, L_values_sorted(selection_idx));
% %     end
% % 
% %     fprintf(' Visualization completed.\n');
% % end
% % 
% % function afficher_tableau_erreur_ameliore(L_dir, L_val)
% % %AFFICHER_TABLEAU_ERREUR_AMELIORE Publication-quality error table for Q1 journals
% % %   Generates a visually elegant table using MATLAB annotations to display
% % %   convergence errors for the L-scheme with a given L parameter.
% % %
% % %   INPUTS:
% % %       L_dir : string, path to the L-scheme directory containing results
% % %               Expected structure: L_dir/resultats_complets/resultats_complets.mat
% % %       L_val : double, numeric value of L for display purposes
% % %
% % %   DATA SOURCE:
% % %       Expects resultats_complets/resultats_complets.mat with fields:
% % %           - h_values   : vector, mesh sizes
% % %           - Erreur_L2  : vector, L2 errors
% % %           - Erreur_H1  : vector, H1 errors (optional)
% % %
% % %   OUTPUT:
% % %       Creates a publication-ready figure with:
% % %           - Formatted table showing 1/h, L2 error, H1 error, convergence order
% % %           - Statistical summary box with minimum error and average order
% % %           - Interactive "Change L" button for exploration
% % %
% % %   FEATURES:
% % %       - LaTeX interpretation for mathematical expressions
% % %       - Professional color scheme (soft, journal-like)
% % %       - Alternating row colors for readability
% % %       - Scientific notation formatting
% % %       - Automatic ordering by refinement level
% % %       - Convergence order calculation and display
% % %       - Dynamic layout based on number of rows
% % %
% % %   ALGORITHM:
% % %       1. Load data from resultats_complets.mat
% % %       2. Compute 1/h values and sort by refinement level
% % %       3. Calculate convergence orders between successive mesh levels
% % %       4. Create figure with annotation-based table
% % %       5. Add statistics box with minimum error and average order
% % %       6. Add interactive button for switching between L values
% % %
% % %   DEPENDENCIES:
% % %       - format_scientific() for number formatting
% % %       - switch_L_and_refresh() for interactive L selection
% % %
% % 
% % %
% % %   See also: FORMAT_SCIENTIFIC, SWITCH_L_AND_REFRESH
% % 
% %     % Construct full path to data file
% %     mat_file = fullfile(L_dir, 'resultats_complets', 'resultats_complets.mat');
% % 
% %     % Check if data file exists
% %     if exist(mat_file, 'file') ~= 2
% %         fprintf(' No data found for L = %.4f\n', L_val);
% %         return;
% %     end
% % 
% %     % Load the data
% %     data = load(mat_file);
% % 
% %     % Verify required fields are present
% %     if ~isfield(data, 'h_values') || ~isfield(data, 'Erreur_L2')
% %         fprintf(' Missing fields (h_values / Erreur_L2) for L = %.4f\n', L_val);
% %         return;
% %     end
% % 
% %     % ---- Figure creation (clean, publication-friendly) ----
% %     fig = figure('Position', [150, 150, 1100, 700], ...
% %         'Name', sprintf('Error Analysis - L = %.4f', L_val), ...
% %         'NumberTitle', 'off', ...
% %         'Color', [1 1 1]);
% % 
% %     % --- Button to switch L interactively (inside the figure) ---
% %     uicontrol('Parent', fig, ...
% %         'Style', 'pushbutton', ...
% %         'String', 'Change L', ...
% %         'Units', 'normalized', ...
% %         'Position', [0.82, 0.92, 0.14, 0.055], ... % top-right
% %         'FontSize', 12, ...
% %         'FontWeight', 'bold', ...
% %         'Callback', @(~,~) switch_L_and_refresh(fig, L_dir, L_val));
% % 
% %     % Global typography choices
% %     fontNameBody  = 'Times New Roman';
% %     fontSizeTitle = 24;
% %     fontSizeHead  = 18;
% %     fontSizeBody  = 16;
% % 
% %     % Color palette (soft, journal-like)
% %     colTitle   = [0.10 0.20 0.45];
% %     colBorder  = [0.55 0.62 0.78];
% %     colGrid    = [0.80 0.86 0.94];
% %     colHeader  = [0.92 0.95 1.00];
% %     colRowA    = [1.00 1.00 1.00];
% %     colRowB    = [0.97 0.985 1.00];
% %     colStatsBG = [0.95 0.98 1.00];
% % 
% %     % ---- Title (LaTeX for mathematical expressions) ----
% %     annotation('textbox', [0.12, 0.905, 0.76, 0.07], ...
% %         'String', sprintf('Error Analysis for $L = %.4f$', L_val), ...
% %         'FontSize', fontSizeTitle, ...
% %         'FontWeight', 'bold', ...
% %         'HorizontalAlignment', 'center', ...
% %         'VerticalAlignment', 'middle', ...
% %         'EdgeColor', 'none', ...
% %         'Interpreter', 'latex', ...
% %         'Color', colTitle);
% % 
% % 
% %         % ---- Compute x = h and ensure ordering (increasing refinement) ----
% %     un_sur_h = 1 ./ data.h_values(:);
% % 
% %     % Sort rows by h (ascending) to keep table consistent
% %     [un_sur_h, idx] = sort(un_sur_h, 'ascend');
% %     errL2 = data.Erreur_L2(:);
% %     errL2 = errL2(idx);
% % 
% %     % Check if H1 errors are available
% %     hasH1 = isfield(data, 'Erreur_H1');
% %     if hasH1
% %         errH1 = data.Erreur_H1(:);
% %         errH1 = errH1(idx);
% %     end
% % 
% %     nx_vals = round(un_sur_h);  % used for display "1/nx"
% % 
% %     % ---- Layout geometry (normalized coordinates) ----
% %     left   = 0.10;
% %     right  = 0.90;
% %     top    = 0.80;
% %     bottom = 0.30;
% % 
% %     W = right - left;
% %     H = top - bottom;
% % 
% %     nRows = numel(nx_vals);
% %     rowH  = H / (nRows+1);          % +1 for header row
% %     colW  = W / 4;                  % 4 columns: 1/h, L2, H1, Order
% % 
% %     % Column x positions (left edges)
% %     x0 = left;
% %     x1 = x0+colW;
% %     x2 = x1+colW;
% %     x3 = x2+colW;
% % 
% %     % Column centers for text alignment
% %     xCenters = [x0+colW/2, x1+colW/2, x2+colW/2, x3+colW/2];
% % 
% %     % ---- Outer table border ----
% %     annotation('rectangle', [left, bottom, W, H], ...
% %         'EdgeColor', colBorder, 'LineWidth', 2, 'FaceColor', 'none');
% % 
% %     % ---- Header background row ----
% %     annotation('rectangle', [left, top-rowH, W, rowH], ...
% %         'FaceColor', colHeader, 'EdgeColor', 'none');
% % 
% %     % ---- Header text ----
% %     headers = {'$1/h$', '$L_2$ error', '$H_1$ error', 'Order'};
% %     for c = 1:4
% %         annotation('textbox', [xCenters(c)-colW/2, top-rowH, colW, rowH], ...
% %             'String', headers{c}, ...
% %             'FontSize', fontSizeHead, ...
% %             'FontWeight', 'bold', ...
% %             'HorizontalAlignment', 'center', ...
% %             'VerticalAlignment', 'middle', ...
% %             'EdgeColor', 'none', ...
% %             'Interpreter', 'latex', ...
% %             'Color', [0 0 0]);
% %     end
% % 
% %     % ---- Vertical grid lines ----
% %     for x = [x1, x2, x3]
% %         annotation('line', [x, x], [bottom, top], ...
% %             'Color', colGrid, 'LineWidth', 1);
% %     end
% % 
% %     % Initialize array to store convergence orders for statistics
% %     orders = [];
% % 
% %     % ---- Fill table rows ----
% %     for i = 1:nRows
% %         % Calculate row y-position (from top)
% %         yRow = top - rowH*(i+1);
% % 
% %         % Alternate row background colors for better readability
% %         bg = colRowA;
% %         if mod(i,2) == 0
% %             bg = colRowB;
% %         end
% %         annotation('rectangle', [left, yRow, W, rowH], ...
% %             'FaceColor', bg, 'EdgeColor', 'none');
% % 
% %         % ---- Column 1: 1/h ----
% %         cell1 = sprintf('$1/%d$', nx_vals(i));
% % 
% %         % ---- Column 2: L2 error (scientific notation) ----
% %         [m2, e2] = format_scientific(errL2(i));
% %         cell2 = sprintf('$%.2f \\times 10^{%d}$', m2, e2);
% % 
% %         % ---- Column 3: H1 error (if available) ----
% %         if hasH1
% %             [m1, e1] = format_scientific(errH1(i));
% %             cell3 = sprintf('$%.2f \\times 10^{%d}$', m1, e1);
% %         else
% %             cell3 = '$-$';
% %         end
% % 
% %         % ---- Column 4: Convergence order ----
% %         if i < nRows
% %             % Calculate order between current and next mesh level
% %             % order = log(error_i/error_{i+1}) / log(2) for mesh refinement by factor 2
% %             ord = log10(errL2(i)/errL2(i+1)) / log10(2);
% %             orders = [orders, ord];  % Store for statistics
% %             cell4 = sprintf('$%.2f$', ord);
% %         else
% %             cell4 = '$-$';  % No order for last row
% %         end
% % 
% %         % Create cell array for this row
% %         rowCells = {cell1, cell2, cell3, cell4};
% % 
% %         % Place all four cells in this row
% %         for c = 1:4
% %             annotation('textbox', [xCenters(c)-colW/2, yRow, colW, rowH], ...
% %                 'String', rowCells{c}, ...
% %                 'FontName', fontNameBody, ...
% %                 'FontSize', fontSizeBody, ...
% %                 'HorizontalAlignment', 'center', ...
% %                 'VerticalAlignment', 'middle', ...
% %                 'EdgeColor', 'none', ...
% %                 'Interpreter', 'latex', ...
% %                 'Color', [0 0 0]);
% %         end
% %     end
% % 
% %     % ---- Horizontal grid lines between rows ----
% %     for i = 1:nRows
% %         y = top - rowH*(i+1);
% %         annotation('line', [left, right], [y, y], ...
% %             'Color', colGrid, 'LineWidth', 1);
% %     end
% % 
% %     % ---- Statistics box (LaTeX formatted) ----
% %     % Find minimum error and its location
% %     [min_err, min_idx] = min(errL2);
% %     [m_min, e_min] = format_scientific(min_err);
% % 
% %     % Calculate average convergence order
% %     if isempty(orders)
% %         avg_order = NaN;
% %     else
% %         avg_order = mean(orders);
% %     end
% % 
% %     % Format statistics text
% %     if ~isnan(avg_order)
% %         stats_text = sprintf(['Best performance\n' ...
% %             'Minimum L2 error: $%.2f \\times 10^{%d}$  (1/%d)\n' ...
% %             'Average order: $%.2f$'], ...
% %             m_min, e_min, nx_vals(min_idx), avg_order);
% %     else
% %         stats_text = sprintf(['Best performance\n' ...
% %             'Minimum L2 error: $%.2f \\times 10^{%d}$  (1/%d)\n' ...
% %             'Average order: N/A'], ...
% %             m_min, e_min, nx_vals(min_idx));
% %     end
% % 
% %     % Add statistics box to figure
% %     annotation('textbox', [0.22, 0.08, 0.56, 0.14], ...
% %         'String', stats_text, ...
% %         'FontName', fontNameBody, ...
% %         'FontSize', 16, ...
% %         'HorizontalAlignment', 'center', ...
% %         'VerticalAlignment', 'middle', ...
% %         'EdgeColor', colBorder, ...
% %         'LineWidth', 2, ...
% %         'BackgroundColor', colStatsBG, ...
% %         'Interpreter', 'latex', ...
% %         'Color', colTitle);
% % 
% %     % Console feedback
% %     fprintf(' Elegant table displayed for L = %.4f\n', L_val);
% %     fprintf('   - Number of mesh levels: %d\n', nRows);
% %     fprintf('   - Average convergence order: %.2f\n', avg_order);
% %     fprintf('   - Minimum L2 error: %.2e\n', min_err);
% % 
% % end
% % 
% % function [m, e] = format_scientific(x)
% % %FORMAT_SCIENTIFIC Convert numeric value to mantissa-exponent representation
% % %   [m, e] = format_scientific(x) converts input x to scientific notation
% % %   of the form m × 10^e, where m is rounded to 2 decimal places.
% % %
% % %   INPUT:
% % %       x : scalar numeric value (can be zero, positive, or negative)
% % %
% % %   OUTPUT:
% % %       m : mantissa rounded to 2 decimal places (1 ≤ |m| < 10 for non-zero x)
% % %       e : exponent (base 10) as integer
% % %
% % %   EXAMPLES:
% % %       [m, e] = format_scientific(123.456)  -> m = 1.23, e = 2
% % %       [m, e] = format_scientific(0.00123)   -> m = 1.23, e = -3
% % %       [m, e] = format_scientific(0)         -> m = 0,   e = 0
% % %
% % %   NOTE:
% % %       Used primarily for formatting error values in publication-quality tables.
% % 
% %     if x == 0
% %         m = 0;
% %         e = 0;
% %         return;
% %     end
% %     e = floor(log10(abs(x)));
% %     m = x / 10^e;
% %     m = round(m * 100) / 100;
% % end
% % 
% % function switch_L_and_refresh(figHandle, current_L_dir, current_L_val)
% % % Open a list of available L folders and refresh the figure with selection.
% % 
% %     % validation_dir = .../results/numerical_validation
% %     % current_L_dir  = .../results/numerical_validation/L-scheme/L=...
% %     L_root = fileparts(current_L_dir); % .../L-scheme
% % 
% %     if exist(L_root,'dir') ~= 7
% %         errordlg(sprintf('Folder not found:\n%s', L_root), 'Error');
% %         return;
% %     end
% % 
% %     % List all L=* folders
% %     L_dirs = dir(fullfile(L_root, 'L=*'));
% %     L_dirs = L_dirs([L_dirs.isdir]);
% %     L_dirs = L_dirs(~ismember({L_dirs.name},{'.','..'}));
% % 
% %     if isempty(L_dirs)
% %         errordlg('No L=* folders found.', 'Error');
% %         return;
% %     end
% % 
% %     % Extract numeric L values
% %     L_values = nan(numel(L_dirs),1);
% %     for k = 1:numel(L_dirs)
% %         tok = regexp(L_dirs(k).name, 'L=([0-9.eE+\-]+)', 'tokens', 'once');
% %         if ~isempty(tok)
% %             L_values(k) = str2double(tok{1});
% %         end
% %     end
% % 
% %     ok = isfinite(L_values);
% %     L_dirs = L_dirs(ok);
% %     L_values = L_values(ok);
% % 
% %     if isempty(L_values)
% %         errordlg('Could not parse numeric L values from folder names.', 'Error');
% %         return;
% %     end
% % 
% %     % Sort by L
% %     [L_values, idx] = sort(L_values);
% %     L_dirs = L_dirs(idx);
% % 
% %     % Build list display
% %     items = cell(numel(L_values),1);
% %     for k = 1:numel(L_values)
% %         items{k} = sprintf('L = %.6g', L_values(k));
% %     end
% % 
% %     % Preselect current L if possible
% %     preSel = find(abs(L_values - current_L_val) < 1e-12, 1);
% %     if isempty(preSel), preSel = 1; end
% % 
% %     [sel, okDlg] = listdlg( ...
% %         'PromptString', 'Select L value:', ...
% %         'SelectionMode', 'single', ...
% %         'ListString', items, ...
% %         'InitialValue', preSel, ...
% %         'ListSize', [300, 300], ...
% %         'Name', 'Choose L');
% % 
% %     if ~okDlg || isempty(sel)
% %         return; % cancelled
% %     end
% % 
% %     newL = L_values(sel);
% %     newLdir = fullfile(L_root, L_dirs(sel).name);
% % 
% %     % Close current figure and open the selected one
% %     if isvalid(figHandle)
% %         close(figHandle);
% %     end
% %     afficher_tableau_erreur_ameliore(newLdir, newL);
% % end
% % 
% % 
% % 
% % function physical_case_t10_only()
% % %PHYSICAL_CASE_T10_ONLY Interactive visualization of physical case results
% % %   Displays isosurface and cross-sectional cut at x=0.5 for the physical case.
% % %   The user can select multiple time steps interactively from available solution files
% % %   using a checkbox list interface.
% % %
% % %   FIX (IMPORTANT):
% % %   The last checkbox (often t_final) was being hidden by the bottom buttons,
% % %   making it look like the final time was missing. This version reserves
% % %   a bottom margin so ALL time checkboxes remain visible.
% % 
% %     clc;
% % 
% %     FIG_POS = [100, 100, 1000, 800];
% %     thisFileDir       = fileparts(mfilename('fullpath'));
% %     base_results_dir   = fullfile(thisFileDir, 'results');  % absolute path
% %     case_root          = fullfile(base_results_dir, 'physical_case');
% % 
% %     % ------------------------------------------------------------
% %     % 1) Auto-detection of L-scheme folder with most recent solutions
% %     % ------------------------------------------------------------
% %     scheme_root = fullfile(case_root, 'L-scheme');
% %     if exist(scheme_root,'dir') ~= 7
% %         fprintf(' Missing: %s\n', scheme_root);
% %         return;
% %     end
% % 
% %     Ldirs = dir(fullfile(scheme_root,'L=*'));
% %     Ldirs = Ldirs([Ldirs.isdir]);
% %     Ldirs = Ldirs(~ismember({Ldirs.name},{'.','..'}));
% % 
% %     if isempty(Ldirs)
% %         fprintf(' No L=* folder found in: %s\n', scheme_root);
% %         return;
% %     end
% % 
% %     bestIdx  = [];
% %     bestTime = -inf;
% % 
% %     for k = 1:numel(Ldirs)
% %         cand = fullfile(scheme_root, Ldirs(k).name);
% % 
% %         sol_dir_k = fullfile(cand, 'solutions_temporelles');
% %         if exist(sol_dir_k,'dir') ~= 7
% %             continue;
% %         end
% % 
% %         fsol = dir(fullfile(sol_dir_k,'solution_nx*_t*s.mat'));
% %         if isempty(fsol)
% %             continue;
% %         end
% % 
% %         newestFileTime = max([fsol.datenum]);
% %         if newestFileTime > bestTime
% %             bestTime = newestFileTime;
% %             bestIdx  = k;
% %         end
% %     end
% % 
% %     if isempty(bestIdx)
% %         fprintf(' No L=* folder with solution files found under: %s\n', scheme_root);
% %         return;
% %     end
% % 
% %     chosen_L_dir = fullfile(scheme_root, Ldirs(bestIdx).name);
% %     fprintf('\n Using physical_case scheme folder (with newest solutions):\n   %s\n', chosen_L_dir);
% % 
% %     results_dir = fullfile(chosen_L_dir, 'resultats_complets');
% %     sol_dir     = fullfile(chosen_L_dir, 'solutions_temporelles');
% % 
% %     fprintf('\n--- PHYSICAL CASE | INTERACTIVE TIME SELECTION ---\n');
% % 
% %     if exist(results_dir,'dir') ~= 7
% %         fprintf(' Missing: %s\n', results_dir);
% %         return;
% %     end
% %     if exist(sol_dir,'dir') ~= 7
% %         fprintf(' Missing: %s\n', sol_dir);
% %         return;
% %     end
% % 
% %     % ------------------------------------------------------------
% %     % 2) Determine finest available mesh resolution (maximum Nx)
% %     % ------------------------------------------------------------
% %     files = dir(fullfile(sol_dir,'solution_nx*_t*s.mat'));
% %     if isempty(files)
% %         fprintf(' No solution_nx*_t*s.mat files in: %s\n', sol_dir);
% %         return;
% %     end
% % 
% %     nxVals = nan(numel(files),1);
% %     for i = 1:numel(files)
% %         tok = regexp(files(i).name,'solution_nx(\d+)_','tokens','once');
% %         if ~isempty(tok)
% %             nxVals(i) = str2double(tok{1});
% %         end
% %     end
% %     nxVals = nxVals(isfinite(nxVals));
% %     if isempty(nxVals)
% %         fprintf(' Unable to extract nx from filenames in: %s\n', sol_dir);
% %         return;
% %     end
% %     nx = max(nxVals);
% % 
% %     % Mesh size fraction h = 1/(nx-1)
% %     numerator   = 1;
% %     denominator = nx - 1;
% % 
% %     % ------------------------------------------------------------
% %     % 3) Get available times for the selected nx and let user choose
% %     % ------------------------------------------------------------
% %     pattern    = sprintf('solution_nx%d_t*.mat', nx);
% %     time_files = dir(fullfile(sol_dir, pattern));
% % 
% %     if isempty(time_files)
% %         fprintf(' No solution files found for nx=%d\n', nx);
% %         return;
% %     end
% % 
% %     time_values  = [];
% %     time_strings = {};
% % 
% %     for i = 1:numel(time_files)
% %         tok = regexp(time_files(i).name, '_t([0-9.eE+-]+)s\.mat', 'tokens', 'once');
% %         if ~isempty(tok)
% %             t_val = str2double(tok{1});
% %             if isfinite(t_val)
% %                 time_values  = [time_values; t_val];
% %                 time_strings = [time_strings; {sprintf('t = %.6g h', t_val)}];
% %             end
% %         end
% %     end
% % 
% %     if isempty(time_values)
% %         fprintf(' Unable to extract time values from filenames\n');
% %         return;
% %     end
% % 
% %     % Sort ascending time
% %     [time_values, sort_idx] = sort(time_values, 'ascend');
% %     time_strings            = time_strings(sort_idx);
% % 
% %     % ------------------------------------------------------------
% %     % 3b) Checkbox UI (FIXED so last time is NOT hidden by buttons)
% %     % ------------------------------------------------------------
% %     n            = length(time_strings);
% %     rowH         = 30;
% %     titleH       = 40;
% %     bottomMargin = 90;      % RESERVED area for buttons (important)
% %     topMargin    = 20;
% % 
% %     figW = 520;
% %     figH = bottomMargin + rowH*n + titleH + topMargin;
% % 
% %     sel_fig = figure('Name', 'Select Time Steps', ...
% %         'NumberTitle', 'off', ...
% %         'Position', [500, 350, figW, figH], ...
% %         'MenuBar', 'none', ...
% %         'ToolBar', 'none', ...
% %         'Resize', 'off', ...
% %         'Color', [0.94 0.94 0.94]);
% % 
% %     % Title
% %     uicontrol('Style', 'text', ...
% %         'Position', [30, bottomMargin + rowH*n + 10, figW-60, titleH-10], ...
% %         'String', sprintf('Select time steps to visualize (nx = %d):', nx), ...
% %         'FontSize', 14, ...
% %         'FontWeight', 'bold', ...
% %         'BackgroundColor', [0.94 0.94 0.94]);
% % 
% %     % Checkboxes
% %     checkboxes = gobjects(n,1);
% %     for i = 1:n
% %         y = bottomMargin + rowH*(n - i);  % <-- starts above button area
% %         checkboxes(i) = uicontrol('Style', 'checkbox', ...
% %             'Position', [40, y, figW-120, 28], ...
% %             'String', time_strings{i}, ...
% %             'FontSize', 12, ...
% %             'Value', 0);
% %     end
% % 
% %     % Buttons (in reserved bottom margin)
% %     uicontrol('Style', 'pushbutton', ...
% %         'Position', [150, 25, 100, 35], ...
% %         'String', 'Select All', ...
% %         'FontSize', 11, ...
% %         'FontWeight', 'bold', ...
% %         'Callback', @(~,~) set(checkboxes, 'Value', 1));
% % 
% %     uicontrol('Style', 'pushbutton', ...
% %         'Position', [260, 25, 100, 35], ...
% %         'String', 'Clear All', ...
% %         'FontSize', 11, ...
% %         'FontWeight', 'bold', ...
% %         'Callback', @(~,~) set(checkboxes, 'Value', 0));
% % 
% %     uicontrol('Style', 'pushbutton', ...
% %         'Position', [380, 25, 80, 35], ...
% %         'String', 'OK', ...
% %         'FontSize', 12, ...
% %         'FontWeight', 'bold', ...
% %         'Callback', 'uiresume(gcbf)');
% % 
% %     uicontrol('Style', 'pushbutton', ...
% %         'Position', [40, 25, 80, 35], ...
% %         'String', 'Cancel', ...
% %         'FontSize', 12, ...
% %         'Callback', @(~,~) close(sel_fig));
% % 
% %     uiwait(sel_fig);
% % 
% %     if ~isvalid(sel_fig)
% %         fprintf(' Visualization cancelled by user.\n');
% %         return;
% %     end
% % 
% %     sel_indices = find([checkboxes.Value] == 1);
% %     close(sel_fig);
% % 
% %     if isempty(sel_indices)
% %         fprintf(' No time steps selected. Visualization cancelled.\n');
% %         return;
% %     end
% % 
% %     selected_times = time_values(sel_indices);
% %     fprintf(' Selected %d time(s) for visualization\n', length(selected_times));
% %     for i = 1:length(selected_times)
% %         fprintf('   - t = %.6g h\n', selected_times(i));
% %     end
% % 
% %     % ------------------------------------------------------------
% %     % 4) Cut parameters
% %     % ------------------------------------------------------------
% %     cut_mode = 2;   % x constant
% %     cut_val  = 0.5;
% % 
% %     % ------------------------------------------------------------
% %     % 5) Generate visualizations for each selected time
% %     % ------------------------------------------------------------
% %     for t_idx = 1:length(selected_times)
% %         t_fixed = selected_times(t_idx);
% % 
% %         fprintf('\n Generating visualizations for t = %.6g h (%d/%d)\n', ...
% %             t_fixed, t_idx, length(selected_times));
% % 
% %         % ISOSURFACE
% %         figure('Position', FIG_POS, ...
% %             'Name', sprintf('Isosurface | t=%.6g h', t_fixed), ...
% %             'Color','w');
% %         show_isosurface_from_file(sol_dir, nx, t_fixed);
% % 
% %         title({sprintf('Isosurface at $t = %.4f$ h', t_fixed); ...
% %                sprintf('$\\mathit{h} = \\frac{%d}{%d}$', numerator, denominator)}, ...
% %             'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
% %         drawnow;
% % 
% %         % CUT
% %         figure('Position', FIG_POS, ...
% %             'Name', sprintf('Cross-section x=%.2f | t=%.6g h', cut_val, t_fixed), ...
% %             'Color','w');
% %         show_cut_from_file(sol_dir, nx, t_fixed, cut_mode, cut_val);
% % 
% %         title({sprintf('Cross-section at $t = %.4f$ h', t_fixed); ...
% %                sprintf('$\\mathit{h} = \\frac{%d}{%d}$', numerator, denominator)}, ...
% %             'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
% %         drawnow;
% %     end
% % 
% %     fprintf('\n Done: %d time(s) displayed for physical case.\n', length(selected_times));
% % end
% % 
% % 
% % function run_comparison_fixed_3figs()
% % %RUN_COMPARISON_FIXED_3FIGS Generate three standard comparison figures for numerical schemes
% % %   This function loads precomputed data for all available numerical schemes and
% % %   generates three fixed-format figures for performance analysis:
% % %       1) CPU time comparison across mesh resolutions
% % %       2) Nonlinear iteration counts comparison
% % %       3) Matrix condition numbers comparison
% % %
% % %   DATA LOADING:
% % %       Uses charger_toutes_donnees_comparaison() to load structured data containing:
% % %           - CPU times for each scheme and mesh size
% % %           - Iteration counts for each scheme
% % %           - Condition numbers for each scheme
% % %
% % %   FIGURE GENERATION:
% % %       Calls three dedicated figure functions (if available):
% % %           - figure_cpu_comparaison_complete()
% % %           - figure_iterations_comparaison_complete()
% % %           - figure_conditionnement_comparaison_complete()
% % %
% % %   DEPENDENCIES:
% % %       Requires the following functions in MATLAB path:
% % %           - charger_toutes_donnees_comparaison.m
% % %           - figure_cpu_comparaison_complete.m
% % %           - figure_iterations_comparaison_complete.m
% % %           - figure_conditionnement_comparaison_complete.m
% % %
% % %   OUTPUT:
% % %       Three figures displayed on screen; no data saved to disk.
% % 
% %     fprintf('\n--- SCHEME COMPARISON (CPU+Iter+Cond only) ---\n');
% % 
% %     if exist('charger_toutes_donnees_comparaison','file') ~= 2
% %         fprintf(' Missing function: charger_toutes_donnees_comparaison\n');
% %         return;
% %     end
% % 
% %     [donnees, noms_schemas] = charger_toutes_donnees_comparaison();
% % 
% %     if isempty(donnees)
% %         fprintf(' No scheme data loaded.\n');
% %         return;
% %     end
% % 
% %     % CPU time comparison figure
% %     if exist('figure_cpu_comparaison_complete','file') == 2
% %         figure_cpu_comparaison_complete(donnees, noms_schemas);
% %     else
% %         fprintf(' Missing: figure_cpu_comparaison_complete\n');
% %     end
% % 
% %     % Iteration count comparison figure
% %     if exist('figure_iterations_comparaison_complete','file') == 2
% %         figure_iterations_comparaison_complete(donnees, noms_schemas);
% %     else
% %         fprintf(' Missing: figure_iterations_comparaison_complete\n');
% %     end
% % 
% %     % Matrix condition number comparison figure
% %     if exist('figure_conditionnement_comparaison_complete','file') == 2
% %         figure_conditionnement_comparaison_complete(donnees, noms_schemas);
% %     else
% %         fprintf(' Missing: figure_conditionnement_comparaison_complete\n');
% %     end
% % 
% %     fprintf(' Comparison display done.\n');
% % end
% % 
% % 
% function show_isosurface_from_file(sol_dir, nx, t)
% %SHOW_ISOSURFACE_FROM_FILE Display 3D isosurface from saved solution data
% %   Creates a publication-quality isosurface visualization of the solution field
% %   at a specified time step, with formatting consistent with the cut visualization.
% %
% %   INPUTS:
% %       sol_dir : Directory containing solution files (solutions_temporelles)
% %       nx      : Mesh resolution parameter (number of points in each direction)
% %       t       : Target time for visualization
% %
% %   DATA LOADING:
% %       Uses charger_donnees_temps() to load:
% %           - P : Node coordinates matrix [x,y,z]
% %           - U : Solution values at nodes
% %           - tm: Actual time loaded (may differ from requested t)
% %
% %   INTERPOLATION:
% %       Creates a structured grid (mx×mx×mx) with mx adaptively chosen between
% %       17 and 129 based on nx. Uses scatteredInterpolant with natural neighbor
% %       interpolation, falling back to griddata if needed.
% %
% %   ISOSURFACE GENERATION:
% %       Computes isosurface at value = umin+0.475*(umax-umin) to capture
% %       mid-range features. Colors the surface by z-coordinate.
% %
% %   VISUALIZATION STYLE:
% %       - Axis equal with tight limits [0,1] for all coordinates
% %       - View angle: azimuth=60°, elevation=20°
% %       - Camlight and gouraud lighting for enhanced 3D perception
% %       - Font sizes: axis numbers 22, labels 24, colorbar 18
% %       - Line width: 1.5 for axes, 0.35 for patch edges
% %       - Jet colormap with colorbar
% %
% %   OUTPUT:
% %       Creates a figure with the formatted isosurface visualization.
% 
%     [P, ~, U, tm] = charger_donnees_temps(sol_dir, nx, t);
%     if isempty(P), return; end
%     if isempty(tm), tm = t; end
% 
%     mx = max(17, min(129, nx+1));
%     [X,Y,Z] = meshgrid(linspace(0,1,mx), linspace(0,1,mx), linspace(0,1,mx));
% 
%     try
%         Fint  = scatteredInterpolant(P(:,1),P(:,2),P(:,3),U,'natural','none');
%         Ugrid = Fint(X,Y,Z);
%     catch
%         Ugrid = griddata(P(:,1),P(:,2),P(:,3),U,X,Y,Z,'linear');
%     end
% 
%     umin = min(Ugrid(:)); umax = max(Ugrid(:));
%     if ~isfinite(umin) || ~isfinite(umax) || umax <= umin
%         fprintf('Iso: invalid Ugrid range.\n');
%         return;
%     end
% 
%     iso_value = umin+0.475*(umax-umin);
%     [F,V] = isosurface(X,Y,Z,Ugrid,iso_value);
%     if isempty(V)
%         fprintf('Iso: no surface.\n');
%         return;
%     end
% 
%     Cvert = V(:,3); % color by z
%     patch('Faces',F,'Vertices',V, ...
%         'FaceVertexCData',Cvert, ...
%         'FaceColor','interp', ...
%         'EdgeColor','k', ...
%         'LineWidth',0.35, ...
%         'FaceAlpha',1.0);
% 
%     % ===================== Formatting like "cut" =====================
%     axis equal tight;
%     axis on; box off; grid off;
%     xlim([0 1]); ylim([0 1]); zlim([0 1]);
%     view(60,20);
%     camlight headlight; lighting gouraud;
% 
%     ax = gca;
%     ax.FontSize   = 22;
%     ax.LineWidth  = 1.5;
%     ax.FontWeight = 'bold';
% 
%     xlabel('x','FontSize',24,'FontWeight','bold');
%     ylabel('y','FontSize',24,'FontWeight','bold');
%     zlabel('z','FontSize',24,'FontWeight','bold');
% 
%     title(sprintf('Isosurface (t=%.3f)', tm), 'FontWeight','bold');
% 
%     colormap(jet);
%     cb = colorbar;
%     cb.FontSize = 18;
% end
% 
% 
% 
% function show_cut_from_file(sol_dir, nx, t, cut_mode, cut_val)
% %SHOW_CUT_FROM_FILE Display 2D cross-sectional cut from saved solution data
% %   Creates a publication-quality contour plot of the solution field on a specified
% %   planar cut (constant x, y, or z), with formatting consistent with the
% %   visualisation_coupe_temps style.
% %
% %   INPUTS:
% %       sol_dir  : Directory containing solution files (solutions_temporelles)
% %       nx       : Mesh resolution parameter (number of points in each direction)
% %       t        : Target time for visualization
% %       cut_mode : Integer specifying cut plane orientation:
% %                  1 = constant z (horizontal plane)
% %                  2 = constant x (vertical plane, y-z view)
% %                  3 = constant y (vertical plane, x-z view)
% %       cut_val  : Coordinate value for the cut plane (should be between 0 and 1)
% %
% %   DATA LOADING:
% %       Uses charger_donnees_temps() to load:
% %           - p : Node coordinates matrix [x,y,z]
% %           - u : Solution values at nodes
% %           - tm: Actual time loaded (may differ from requested t)
% %
% %   INTERPOLATION:
% %       Creates a regular nx×nx×nx grid using griddata with linear interpolation.
% %       The cut plane is extracted by finding the grid index closest to cut_val.
% %
% %   VISUALIZATION STYLE:
% %       - Filled contour plot with 20 levels, no contour lines
% %       - Axis equal with tight limits
% %       - Font sizes: axis numbers 22, labels 24, colorbar 18, title 26
% %       - Line width: 1.5 for axes
% %       - Jet colormap with colorbar
% %       - Minimal margins for maximum plot area
% %
% %   OUTPUT:
% %       Creates a figure with the formatted cut visualization and prints
% %       min/max value information to console.
% 
%     [p, ~, u, tm] = charger_donnees_temps(sol_dir, nx, t);
%     if isempty(p), return; end
%     if isempty(tm), tm = t; end
% 
%     % Regular grid (same idea as your code)
%     [Xg,Yg,Zg] = meshgrid(linspace(0,1,nx), linspace(0,1,nx), linspace(0,1,nx));
%     Ug = griddata(p(:,1),p(:,2),p(:,3),u,Xg,Yg,Zg,'linear');
%     if all(isnan(Ug(:)))
%         fprintf('Cut: only NaN.\n');
%         return;
%     end
% 
%     cut_val = max(0.01, min(0.99, cut_val));
% 
%     % Use a big figure feel (like your code)
%     set(gcf,'Renderer','opengl');
% 
%     switch cut_mode
%         case 1 % z constant
%             [~,iz] = min(abs(Zg(1,1,:) - cut_val));
%             Xc = squeeze(Xg(:,:,iz)); Yc = squeeze(Yg(:,:,iz)); Uc = squeeze(Ug(:,:,iz));
%             contourf(Xc,Yc,Uc,20,'LineStyle','none');
%             xlabel('x','FontSize',24,'FontWeight','bold');
%             ylabel('y','FontSize',24,'FontWeight','bold');
%             ttl = sprintf('Cut z=%.2f', cut_val);
% 
%         case 2 % x constant
%             [~,ix] = min(abs(Xg(1,:,1) - cut_val));
%             Yc = squeeze(Yg(:,ix,:)); Zc = squeeze(Zg(:,ix,:)); Uc = squeeze(Ug(:,ix,:));
%             contourf(Yc,Zc,Uc,20,'LineStyle','none');
%             xlabel('y','FontSize',24,'FontWeight','bold');
%             ylabel('z','FontSize',24,'FontWeight','bold');
%             ttl = sprintf('Cut x=%.2f', cut_val);
% 
%         case 3 % y constant
%             [~,iy] = min(abs(Yg(:,1,1) - cut_val));
%             Xc = squeeze(Xg(iy,:,:)); Zc = squeeze(Zg(iy,:,:)); Uc = squeeze(Ug(iy,:,:));
%             contourf(Xc,Zc,Uc,20,'LineStyle','none');
%             xlabel('x','FontSize',24,'FontWeight','bold');
%             ylabel('z','FontSize',24,'FontWeight','bold');
%             ttl = sprintf('Cut y=%.2f', cut_val);
% 
%         otherwise
%             fprintf('Invalid cut_mode.\n');
%             return;
%     end
% 
%     % ---- Common formatting (copied from your visualisation_coupe_temps style) ----
%     ax = gca;
%     ax.FontSize   = 22;
%     ax.LineWidth  = 1.5;
%     ax.FontWeight = 'bold';
% 
%     axis equal tight;
%     axis on; box off; grid off;
% 
%     colormap(jet);
%     cb = colorbar;
%     cb.FontSize = 18;
% 
%     % Make the plot fill the window (less margins)
%     set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
% 
%     % Title big like your screenshot
%     title(sprintf('%s (t=%.3f)', ttl, tm), 'FontSize', 26, 'FontWeight','bold');
% 
%     % Print range info (like your logs)
%     umin = min(Uc(:)); umax = max(Uc(:));
%     fprintf('Coupe t=%.3f : min(Uc)=%.3e, max(Uc)=%.3e\n', tm, umin, umax);
%     fprintf('Plage des valeurs dans la coupe: min=%.3e, max=%.3e\n', umin, umax);
% end
% 
% function [donnees, noms_schemas] = charger_toutes_donnees_comparaison(base_results_dir)
% %CHARGER_TOUTES_DONNEES_COMPARAISON Load comparison data for all numerical schemes
% %   Scans the results directory and loads data from all available numerical schemes
% %   (L-scheme with various L values, Picard, Newton) for performance comparison.
% %
% %   INPUT:
% %       base_results_dir : Optional path to results directory.
% %                          If not provided, uses 'results' in the current file's directory.
% %
% %   OUTPUT:
% %       donnees       : Cell array containing loaded data structures from each scheme
% %       noms_schemas  : Cell array of scheme names for legend/display
% %
% %   DATA STRUCTURE EXPECTED:
% %       For each scheme, loads 'resultats_complets.mat' containing:
% %           - h_values   : mesh sizes
% %           - CPU_times  : computation times
% %           - iterations : iteration counts
% %           - cond_numbers: matrix condition numbers
% %
% %   DIRECTORY STRUCTURE SCANNED:
% %       base_results_dir/
% %           numerical_validation/
% %               L-scheme/
% %                   L=*/
% %                       resultats_complets/
% %                           resultats_complets.mat
% %               Picard/
% %                   resultats_complets/
% %                       resultats_complets.mat
% %               Newton/
% %                   resultats_complets/
% %                       resultats_complets.mat
% 
% %     if nargin < 1 || isempty(base_results_dir)
% %         base_results_dir = 'results';
% %     end
%     if nargin < 1 || isempty(base_results_dir)
%         thisFileDir = fileparts(mfilename('fullpath'));
%         base_results_dir = fullfile(thisFileDir, 'results');  % absolute path
%     end
% 
%     donnees = {};
%     noms_schemas = {};
% 
%     validation_dir = fullfile(base_results_dir, 'numerical_validation');
%     if exist(validation_dir,'dir') ~= 7
%         fprintf(' Missing: %s\n', validation_dir);
%         return;
%     end
% 
%     % --------- 1) L-scheme : LOAD ALL L=* automatically ----------
%     Lroot = fullfile(validation_dir,'L-scheme');
%     if exist(Lroot,'dir') == 7
%         Ldirs = dir(fullfile(Lroot,'L=*'));
%         Ldirs = Ldirs([Ldirs.isdir]);
% 
%         % Sort by numerical L value when possible
%         Lvals = nan(numel(Ldirs),1);
%         for k=1:numel(Ldirs)
%             tok = regexp(Ldirs(k).name,'L=([0-9eE\.\-\+]+)','tokens','once');
%             if ~isempty(tok), Lvals(k)=str2double(tok{1}); end
%         end
%         [~,idx] = sort(Lvals);  % NaN at the end
%         Ldirs = Ldirs(idx);
% 
%         for k=1:numel(Ldirs)
%             data_file = fullfile(Lroot, Ldirs(k).name, 'resultats_complets','resultats_complets.mat');
%             if exist(data_file,'file')==2
%                 S = load(data_file);
%                 donnees{end+1} = S;
%                 noms_schemas{end+1} = sprintf('L-scheme (%s)', Ldirs(k).name); % e.g., L=0.5
%                 fprintf(' Loaded: %s\n', noms_schemas{end});
%             else
%                 fprintf('Missing: %s\n', data_file);
%             end
%         end
%     else
%         fprintf('No folder: %s\n', Lroot);
%     end
% 
%     % --------- 2) Picard ----------
%     pic_file = fullfile(validation_dir,'Picard','resultats_complets','resultats_complets.mat');
%     if exist(pic_file,'file')==2
%         donnees{end+1} = load(pic_file);
%         noms_schemas{end+1} = 'Picard';
%         fprintf(' Loaded: Picard\n');
%     end
% 
%     % (optional) Newton if available
%     newt_file = fullfile(validation_dir,'Newton','resultats_complets','resultats_complets.mat');
%     if exist(newt_file,'file')==2
%         donnees{end+1} = load(newt_file);
%         noms_schemas{end+1} = 'Newton';
%         fprintf(' Loaded: Newton\n');
%     end
% end
% 
% 
% 
% function figure_cpu_comparaison_complete(donnees, noms_schemas)
% %FIGURE_CPU_COMPARAISON_COMPLETE Create CPU time comparison figure with 1/h axis
% %   Generates a publication-quality figure comparing computation times across
% %   different numerical schemes (L-scheme with various L values, Picard, Newton).
% %   Features dynamic axis scaling based on loaded data.
% %
% %   INPUTS:
% %       donnees      : Cell array of data structures from charger_toutes_donnees_comparaison
% %       noms_schemas : Cell array of scheme names for legend labels
% %
% %   VISUALIZATION FEATURES:
% %       - Each scheme plotted with distinct color and marker style
% %       - CPU time values displayed as labels near each data point
% %       - Dynamic X-axis based on 1/h values
% %       - Logarithmic Y-axis with dynamic scaling
% %       - Drag-and-drop functionality for legend and text labels
% %       - LaTeX-formatted legend entries
% %
% %   DATA REQUIREMENTS:
% %       Each data structure must contain:
% %           - h_values   : vector of mesh sizes
% %           - CPU_times  : vector of computation times
% %
% %   OUTPUT:
% %       Creates a figure with all schemes plotted and formatted axes.
% 
%     % FIGURE_CPU_COMPARAISON_COMPLETE - Figure CPU avec axe 1/h
%     % Version avec gestion dynamique des valeurs de L et axes dynamiques
% 
%     figure('Position', [100, 100, 1000, 800], 'Name', 'Computation Time');
% 
%     % ---- Extended color palette ----
%     couleurs_base = [
%         0, 0.4470, 0.7410;     % blue
%         0.4660, 0.6740, 0.1880; % green
%         0.9290, 0.6940, 0.1250; % yellow/orange
%         0.4940, 0.1840, 0.5560; % purple
%         0.3010, 0.7450, 0.9330; % cyan
%         0.6350, 0.0780, 0.1840; % dark red
%         0.2, 0.2, 0.2;          % gray/black
%         0.8500, 0.3250, 0.0980  % bright orange
%     ];
% 
%     styles = {'-o', '-s', '-^', '-d', '-v', '-p', '-h', '--s'};
% 
%     hold on;
% 
%     text_handles = [];
% 
%     % ---- Collect all 1/h and CPU values for dynamic axis scaling ----
%     all_un_sur_h = [];
%     all_cpu_times = [];
% 
%     % ---- Extract and sort L values ----
%     L_values = [];
%     indices_L = [];
% 
%     for i = 1:numel(noms_schemas)
%         nom = noms_schemas{i};
%         if contains(nom, 'L=')
%             tok = regexp(nom, 'L=([0-9.eE+-]+)', 'tokens', 'once');
%             if ~isempty(tok)
%                 L_val = str2double(tok{1});
%                 L_values = [L_values, L_val];
%                 indices_L = [indices_L, i];
%             end
%         end
% 
%         % Collect data for axis scaling
%         if isfield(donnees{i}, 'h_values') && isfield(donnees{i}, 'CPU_times')
%             un_sur_h = 1 ./ donnees{i}.h_values;
%             cpu_times = donnees{i}.CPU_times;
%             n_points = min(length(un_sur_h), length(cpu_times));
%             if n_points > 0
%                 all_un_sur_h = [all_un_sur_h; un_sur_h(1:n_points)];
%                 all_cpu_times = [all_cpu_times; cpu_times(1:n_points)];
%             end
%         end
%     end
% 
%     % Sort L values in ascending order
%     [L_values_sorted, sort_idx] = sort(L_values);
%     indices_L_sorted = indices_L(sort_idx);
% 
%     % Create color mapping for each L value
%     couleur_map = containers.Map();
%     for k = 1:length(L_values_sorted)
%         couleur_map(num2str(L_values_sorted(k))) = couleurs_base(mod(k-1, size(couleurs_base,1))+1, :);
%     end
% 
%     % ---- Plot all L-scheme data in sorted order ----
%     for idx = indices_L_sorted
%         data = donnees{idx};
%         nom = noms_schemas{idx};
% 
%         % Extract L value
%         tok = regexp(nom, 'L=([0-9.eE+-]+)', 'tokens', 'once');
%         L_val = str2double(tok{1});
% 
%         % Assign color based on L value
%         couleur = couleur_map(num2str(L_val));
% 
%         if isfield(data, 'h_values') && isfield(data, 'CPU_times')
%             un_sur_h = 1 ./ data.h_values;
%             cpu_times = data.CPU_times;
% 
%             n_points = min(length(un_sur_h), length(cpu_times));
%             un_sur_h = un_sur_h(1:n_points);
%             cpu_times = cpu_times(1:n_points);
% 
%             % Style based on position in sorted list
%             style_idx = find(L_values_sorted == L_val, 1);
% 
%             plot(un_sur_h, cpu_times, styles{mod(style_idx-1, length(styles))+1}, ...
%                  'Color', couleur, ...
%                  'LineWidth', 3.5, ...
%                  'MarkerSize', 8, ...
%                  'MarkerFaceColor', couleur, ...
%                  'DisplayName', formatLegende(nom, L_val));
% 
%             % Display CPU time values as labels
%             for j = 1:n_points
%                 if cpu_times(j) >= 1000
%                     label_text = sprintf('(%.0f)', cpu_times(j));
%                 else
%                     label_text = sprintf('(%.1f)', cpu_times(j));
%                 end
% 
%                 text(un_sur_h(j), cpu_times(j), label_text, ...
%                      'FontSize', 20, 'FontWeight', 'bold', ...
%                      'HorizontalAlignment', 'center', ...
%                      'VerticalAlignment', 'bottom', ...
%                      'Color', couleur, ...
%                      'ButtonDownFcn', @startDrag);
%             end
%         end
%     end
% 
%     % ---- Plot Picard if available ----
%     picard_idx = find(cellfun(@(x) contains(x, 'Picard') && ~contains(x, 'L='), noms_schemas));
%     if ~isempty(picard_idx)
%         for idx = picard_idx'
%             data = donnees{idx};
%             nom = noms_schemas{idx};
% 
%             couleur = [0.8500, 0.3250, 0.0980]; % bright orange for Picard
% 
%             if isfield(data, 'h_values') && isfield(data, 'CPU_times')
%                 un_sur_h = 1 ./ data.h_values;
%                 cpu_times = data.CPU_times;
% 
%                 n_points = min(length(un_sur_h), length(cpu_times));
%                 un_sur_h = un_sur_h(1:n_points);
%                 cpu_times = cpu_times(1:n_points);
% 
%                 plot(un_sur_h, cpu_times, '-d', ...
%                      'Color', couleur, ...
%                      'LineWidth', 3.5, ...
%                      'MarkerSize', 8, ...
%                      'MarkerFaceColor', couleur, ...
%                      'DisplayName', '$\mathbf{Picard}$');
% 
%                 for j = 1:n_points
%                     if cpu_times(j) >= 1000
%                         label_text = sprintf('(%.0f)', cpu_times(j));
%                     else
%                         label_text = sprintf('(%.1f)', cpu_times(j));
%                     end
% 
%                     text(un_sur_h(j), cpu_times(j), label_text, ...
%                          'FontSize', 20, 'FontWeight', 'bold', ...
%                          'HorizontalAlignment', 'center', ...
%                          'VerticalAlignment', 'bottom', ...
%                          'Color', couleur, ...
%                          'ButtonDownFcn', @startDrag);
%                 end
%             end
%         end
%     end
% 
%     % ---- Plot Newton if available ----
%     newton_idx = find(cellfun(@(x) contains(x, 'Newton'), noms_schemas));
%     if ~isempty(newton_idx)
%         for idx = newton_idx'
%             data = donnees{idx};
%             nom = noms_schemas{idx};
% 
%             couleur = [0.2, 0.2, 0.2]; % gray/black for Newton
% 
%             if isfield(data, 'h_values') && isfield(data, 'CPU_times')
%                 un_sur_h = 1 ./ data.h_values;
%                 cpu_times = data.CPU_times;
% 
%                 n_points = min(length(un_sur_h), length(cpu_times));
%                 un_sur_h = un_sur_h(1:n_points);
%                 cpu_times = cpu_times(1:n_points);
% 
%                 plot(un_sur_h, cpu_times, '--s', ...
%                      'Color', couleur, ...
%                      'LineWidth', 3.5, ...
%                      'MarkerSize', 9, ...
%                      'MarkerFaceColor', couleur, ...
%                      'DisplayName', '$\mathbf{Newton}$');
% 
%                 for j = 1:n_points
%                     if cpu_times(j) >= 1000
%                         label_text = sprintf('(%.0f)', cpu_times(j));
%                     else
%                         label_text = sprintf('(%.1f)', cpu_times(j));
%                     end
% 
%                     text(un_sur_h(j), cpu_times(j), label_text, ...
%                          'FontSize', 20, 'FontWeight', 'bold', ...
%                          'HorizontalAlignment', 'center', ...
%                          'VerticalAlignment', 'bottom', ...
%                          'Color', couleur, ...
%                          'ButtonDownFcn', @startDrag);
%                 end
%             end
%         end
%     end
% 
%     % Axis configuration
%     ax = gca;
%     ax.FontSize   = 22;
%     ax.LineWidth  = 1.5;
%     ax.FontWeight = 'bold';
%     ax.Box        = 'off';
%     ax.TickDir    = 'out';
% 
%     xlabel('1/h', 'FontSize', 20, 'FontWeight', 'bold');
% 
%     % Legend
%     h_legend = legend('Location', 'northwest', 'FontSize', 22, 'Box', 'on', ...
%                       'Interpreter', 'latex');
%     set(h_legend, 'ButtonDownFcn', @legendButtonDown);
% 
%     % ===== DYNAMIC AXES =====
% 
%     % --- Dynamic X axis ---
%     if ~isempty(all_un_sur_h)
%         all_un_sur_h = unique(all_un_sur_h);
%         x_min = min(all_un_sur_h);
%         x_max = max(all_un_sur_h);
% 
%         % Add 5% margin
%         x_range = x_max - x_min;
%         x_min = max(0, x_min - 0.05 * x_range);
%         x_max = x_max+0.05 * x_range;
% 
%         xlim([x_min, x_max]);
% 
%         % Create appropriate ticks (between 4 and 6 ticks)
%         if length(all_un_sur_h) <= 6
%             xticks(all_un_sur_h);
%             xticklabels(cellstr(num2str(all_un_sur_h(:))));
%         else
%             % Keep approximately 5 ticks
%             step = ceil(length(all_un_sur_h) / 5);
%             tick_indices = 1:step:length(all_un_sur_h);
%             xticks(all_un_sur_h(tick_indices));
%             xticklabels(cellstr(num2str(all_un_sur_h(tick_indices)')));
%         end
%     end
% 
%     % --- Dynamic Y axis ---
%     if ~isempty(all_cpu_times)
%         all_cpu_times = all_cpu_times(all_cpu_times > 0);
%         if ~isempty(all_cpu_times)
%             y_min = min(all_cpu_times);
%             y_max = max(all_cpu_times);
% 
%             % 10% margin in logarithmic scale
%             log_min = log10(y_min);
%             log_max = log10(y_max);
%             log_range = log_max - log_min;
% 
%             log_min = log_min - 0.05 * log_range;
%             log_max = log_max+0.05 * log_range;
% 
%             ylim(10.^[log_min, log_max]);
% 
%             % Generate ticks as powers of 10
%             pow_min = floor(log_min);
%             pow_max = ceil(log_max);
% 
%             if (pow_max - pow_min) > 6
%                 step = 2;
%             else
%                 step = 1;
%             end
% 
%             y_ticks = 10.^(pow_min:step:pow_max);
%             yticks(y_ticks);
% 
%             y_labels = arrayfun(@(x) sprintf('10^{%d}', round(log10(x))), y_ticks, 'UniformOutput', false);
%             yticklabels(y_labels);
% 
%             % Logarithmic Y scale
%             set(gca, 'YScale', 'log');
%         end
%     else
%         % Fallback if no data
%         ylim([0, 1e4]);
%         yticks(10.^(0:4));
%         yticklabels({'10^0','10^1','10^2','10^3','10^4'});
%         set(gca, 'YScale', 'log');
%     end
% 
%     grid off;
%     set(gcf, 'Color', 'white');
%     hold off;
% 
%     % === FUNCTION FOR FORMATTING LEGENDS ===
%     function legende_formatee = formatLegende(nom, L_val)
%         if contains(nom, 'Newton')
%             legende_formatee = '$\mathbf{Newton}$';
%         elseif contains(nom, 'Picard') && ~contains(nom, 'L=')
%             legende_formatee = '$\mathbf{Picard}$';
%         else
%             if abs(L_val - round(L_val)) < 1e-10
%                 legende_formatee = sprintf('$\\mathbf{L-scheme\\ (L=%d)}$', round(L_val));
%             else
%                 legende_formatee = sprintf('$\\mathbf{L-scheme\\ (L=%.2f)}$', L_val);
%             end
%         end
%     end
% 
%     % === DRAG-AND-DROP FUNCTIONS ===
%     function legendButtonDown(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', @legendDrag, ...
%                  'WindowButtonUpFcn',      @stopLegendDrag);
%     end
% 
%     function legendDrag(~, ~)
%         currentPoint = get(gcf, 'CurrentPoint');
%         fig_pos      = get(gcf, 'Position');
%         legend_pos   = [currentPoint(1)/fig_pos(3), currentPoint(2)/fig_pos(4), 0.2, 0.2];
%         set(h_legend, 'Units','normalized', 'Position', legend_pos);
%     end
% 
%     function stopLegendDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', '', ...
%                  'WindowButtonUpFcn',      '');
%     end
% 
%     function startDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', @dragText, ...
%                  'WindowButtonUpFcn',      @stopDrag);
%     end
% 
%     function dragText(~, ~)
%         currentPoint = get(gca, 'CurrentPoint');
%         h_text       = gco;
%         if isgraphics(h_text, 'text')
%             newPos = [currentPoint(1,1), currentPoint(1,2), 0];
%             set(h_text, 'Position', newPos);
%         end
%     end
% 
%     function stopDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', '', ...
%                  'WindowButtonUpFcn',      '');
%     end
% 
%     fprintf(' Figure Computation Time avec axes dynamiques.\n');
% end
% 
% function figure_iterations_comparaison_complete(donnees, noms_schemas)
% %FIGURE_ITERATIONS_COMPARAISON_COMPLETE Create iteration count comparison figure with 1/h axis
% %   Generates a publication-quality figure comparing iteration counts across
% %   different numerical schemes (L-scheme with various L values, Picard, Newton).
% %   Styling is identical to figure_cpu_comparaison_complete for consistency in articles.
% %
% %   INPUTS:
% %       donnees      : Cell array of data structures from charger_toutes_donnees_comparaison
% %       noms_schemas : Cell array of scheme names for legend labels
% %
% %   DATA REQUIREMENTS:
% %       Each data structure must contain:
% %           - h_values               : vector of mesh sizes
% %           - Picard_iters_moyenne    : average Picard iterations (for L-scheme and Picard)
% %           - Newton_iters_moyenne    : average Newton iterations (for Newton, optional)
% %
% %   VISUALIZATION FEATURES:
% %       - Each scheme plotted with distinct color and marker style
% %       - Iteration counts displayed as labels near each data point
% %       - Dynamic X-axis based on 1/h values
% %       - Linear Y-axis with dynamic scaling
% %       - Drag-and-drop functionality for legend and text labels
% %       - LaTeX-formatted legend entries with exact L values
% %
% %   COLOR PALETTE:
% %       - L-scheme: Extended MATLAB default colors, assigned by sorted L value
% %       - Picard: Bright orange [0.8500, 0.3250, 0.0980]
% %       - Newton: Gray/black [0.2, 0.2, 0.2]
% %
% %   OUTPUT:
% %       Creates a figure with all schemes plotted and formatted axes.
% 
%     % FIGURE_ITERATIONS_COMPARAISON_COMPLETE - Figure itérations avec axe 1/h
%     % Style 100% identique à figure_cpu_comparaison_complete (article)
%     % Champ utilisé : Picard_iters_moyenne (pour tous les L-scheme / Picard)
%     % Version avec axes dynamiques
% 
%     figure('Position', [100, 100, 1000, 800], 'Name', 'Number of iterations');
% 
%     % ---- Extended color palette ----
%     % Base colors (MATLAB default)
%     couleurs_base = [
%         0, 0.4470, 0.7410;     % blue
%         0.4660, 0.6740, 0.1880; % green
%         0.9290, 0.6940, 0.1250; % yellow/orange
%         0.4940, 0.1840, 0.5560; % purple
%         0.3010, 0.7450, 0.9330; % cyan
%         0.6350, 0.0780, 0.1840; % dark red
%         0.2, 0.2, 0.2;          % gray/black
%         0.8500, 0.3250, 0.0980  % bright orange
%     ];
% 
%     styles = {'-o', '-s', '-^', '-d', '-v', '-p', '-h', '--s'};
% 
%     hold on;
% 
%     % Store text handles for drag functionality
%     text_handles = []; 
% 
%     % ---- Collect all 1/h and iteration values for dynamic axis scaling ----
%     all_un_sur_h = [];
%     all_iterations = [];
% 
%     % ---- Extract and sort L values ----
%     L_values = [];
%     indices_L = [];
% 
%     for i = 1:numel(noms_schemas)
%         nom = noms_schemas{i};
%         if contains(nom, 'L=')
%             tok = regexp(nom, 'L=([0-9.eE+-]+)', 'tokens', 'once');
%             if ~isempty(tok)
%                 L_val = str2double(tok{1});
%                 L_values = [L_values, L_val];
%                 indices_L = [indices_L, i];
%             end
%         end
% 
%         % Collect data for axis scaling
%         if isfield(donnees{i}, 'h_values')
%             if isfield(donnees{i}, 'Picard_iters_moyenne')
%                 un_sur_h = 1 ./ donnees{i}.h_values;
%                 iterations = donnees{i}.Picard_iters_moyenne;
%                 n_points = min(length(un_sur_h), length(iterations));
%                 if n_points > 0
%                     all_un_sur_h = [all_un_sur_h; un_sur_h(1:n_points)];
%                     all_iterations = [all_iterations; iterations(1:n_points)];
%                 end
%             elseif isfield(donnees{i}, 'Newton_iters_moyenne')
%                 un_sur_h = 1 ./ donnees{i}.h_values;
%                 iterations = donnees{i}.Newton_iters_moyenne;
%                 n_points = min(length(un_sur_h), length(iterations));
%                 if n_points > 0
%                     all_un_sur_h = [all_un_sur_h; un_sur_h(1:n_points)];
%                     all_iterations = [all_iterations; iterations(1:n_points)];
%                 end
%             end
%         end
%     end
% 
%     % Sort L values in ascending order
%     [L_values_sorted, sort_idx] = sort(L_values);
%     indices_L_sorted = indices_L(sort_idx);
% 
%     % Create color mapping for each L value
%     couleur_map = containers.Map();
%     for k = 1:length(L_values_sorted)
%         couleur_map(num2str(L_values_sorted(k))) = couleurs_base(mod(k-1, size(couleurs_base,1))+1, :);
%     end
% 
%     % ---- Plot schemes in order: sorted L first, then Picard, then Newton ----
%     % First plot L-scheme sorted by L value
%     for idx = indices_L_sorted
%         data = donnees{idx};
%         nom = noms_schemas{idx};
% 
%         % Extract L value
%         tok = regexp(nom, 'L=([0-9.eE+-]+)', 'tokens', 'once');
%         L_val = str2double(tok{1});
% 
%         % Assign color based on L value
%         couleur = couleur_map(num2str(L_val));
% 
%         % Plot
%         if ~isfield(data,'h_values')
%             fprintf('Missing fields for %s\n', nom);
%             continue;
%         end
% 
%         un_sur_h = 1 ./ data.h_values;
% 
%         % Retrieve iterations
%         if isfield(data,'Picard_iters_moyenne')
%             iterations = data.Picard_iters_moyenne;
%         else
%             fprintf('Missing iteration fields for %s\n', nom);
%             continue;
%         end
% 
%         n_points = min(length(un_sur_h), length(iterations));
%         un_sur_h = un_sur_h(1:n_points);
%         iterations = iterations(1:n_points);
% 
%         % Plot with appropriate style
%         style_idx = find(L_values_sorted == L_val, 1);
%         plot(un_sur_h, iterations, styles{mod(style_idx-1, length(styles))+1}, ...
%              'Color', couleur, ...
%              'LineWidth', 3.5, ...
%              'MarkerSize', 8, ...
%              'MarkerFaceColor', couleur, ...
%              'DisplayName', formatLegende(nom, L_val));
% 
%         % Add iteration labels
%         for j = 1:n_points
%             label_text = formatIterations(iterations(j));
%             text(un_sur_h(j), iterations(j), label_text, ...
%                  'FontSize', 20, 'FontWeight', 'bold', ...
%                  'HorizontalAlignment', 'center', ...
%                  'VerticalAlignment', 'bottom', ...
%                  'Color', couleur, ...
%                  'ButtonDownFcn', @startDrag);
%         end
%     end
% 
%     % Then plot Picard (if available)
%     picard_idx = find(cellfun(@(x) contains(x, 'Picard') && ~contains(x, 'L='), noms_schemas));
%     if ~isempty(picard_idx)
%         for idx = picard_idx'
%             data = donnees{idx};
%             nom = noms_schemas{idx};
% 
%             % Specific color for Picard
%             couleur = [0.8500, 0.3250, 0.0980]; % bright orange
% 
%             if isfield(data,'h_values') && isfield(data,'Picard_iters_moyenne')
%                 un_sur_h = 1 ./ data.h_values;
%                 iterations = data.Picard_iters_moyenne;
% 
%                 n_points = min(length(un_sur_h), length(iterations));
%                 un_sur_h = un_sur_h(1:n_points);
%                 iterations = iterations(1:n_points);
% 
%                 plot(un_sur_h, iterations, '-d', ...
%                      'Color', couleur, ...
%                      'LineWidth', 3.5, ...
%                      'MarkerSize', 8, ...
%                      'MarkerFaceColor', couleur, ...
%                      'DisplayName', '$\mathbf{Picard}$');
% 
%                 for j = 1:n_points
%                     label_text = formatIterations(iterations(j));
%                     text(un_sur_h(j), iterations(j), label_text, ...
%                          'FontSize', 20, 'FontWeight', 'bold', ...
%                          'HorizontalAlignment', 'center', ...
%                          'VerticalAlignment', 'bottom', ...
%                          'Color', couleur, ...
%                          'ButtonDownFcn', @startDrag);
%                 end
%             end
%         end
%     end
% 
%     % Finally plot Newton (if available)
%     newton_idx = find(cellfun(@(x) contains(x, 'Newton'), noms_schemas));
%     if ~isempty(newton_idx)
%         for idx = newton_idx'
%             data = donnees{idx};
%             nom = noms_schemas{idx};
% 
%             % Specific color for Newton
%             couleur = [0.2, 0.2, 0.2]; % gray/black
% 
%             if isfield(data,'h_values')
%                 un_sur_h = 1 ./ data.h_values;
% 
%                 % Look for Newton iterations
%                 if isfield(data,'Newton_iters_moyenne')
%                     iterations = data.Newton_iters_moyenne;
%                 elseif isfield(data,'Newton_iters')
%                     iterations = data.Newton_iters;
%                 else
%                     fprintf('Missing Newton fields for %s\n', nom);
%                     continue;
%                 end
% 
%                 n_points = min(length(un_sur_h), length(iterations));
%                 un_sur_h = un_sur_h(1:n_points);
%                 iterations = iterations(1:n_points);
% 
%                 plot(un_sur_h, iterations, '--s', ...
%                      'Color', couleur, ...
%                      'LineWidth', 3.5, ...
%                      'MarkerSize', 9, ...
%                      'MarkerFaceColor', couleur, ...
%                      'DisplayName', '$\mathbf{Newton}$');
% 
%                 for j = 1:n_points
%                     label_text = formatIterations(iterations(j));
%                     text(un_sur_h(j), iterations(j), label_text, ...
%                          'FontSize', 20, 'FontWeight', 'bold', ...
%                          'HorizontalAlignment', 'center', ...
%                          'VerticalAlignment', 'bottom', ...
%                          'Color', couleur, ...
%                          'ButtonDownFcn', @startDrag);
%                 end
%             end
%         end
%     end
% 
%     % ---- Axis configuration ----
%     ax = gca;
%     ax.FontSize   = 20;
%     ax.LineWidth  = 1.5;
%     ax.FontWeight = 'bold';
%     ax.Box        = 'off';
%     ax.TickDir    = 'out';
% 
%     xlabel('1/h', 'FontSize', 20, 'FontWeight', 'bold');
% 
%     % Draggable legend
%     h_legend = legend('Location', 'northwest', 'FontSize', 20, 'Box', 'on', ...
%                       'Interpreter', 'latex');
%     set(h_legend, 'ButtonDownFcn', @legendButtonDown);
% 
%     % ===== DYNAMIC AXES =====
% 
%     % --- Dynamic X axis ---
%     if ~isempty(all_un_sur_h)
%         all_un_sur_h = unique(all_un_sur_h);
%         x_min = min(all_un_sur_h);
%         x_max = max(all_un_sur_h);
% 
%         % Add 5% margin
%         x_range = x_max - x_min;
%         x_min = max(0, x_min - 0.05 * x_range);
%         x_max = x_max+0.05 * x_range;
% 
%         xlim([x_min, x_max]);
% 
%         % Create appropriate ticks (between 4 and 6 ticks)
%         if length(all_un_sur_h) <= 6
%             xticks(all_un_sur_h);
%             xticklabels(cellstr(num2str(all_un_sur_h(:))));
%         else
%             % Keep approximately 5 ticks
%             step = ceil(length(all_un_sur_h) / 5);
%             tick_indices = 1:step:length(all_un_sur_h);
%             xticks(all_un_sur_h(tick_indices));
%             xticklabels(cellstr(num2str(all_un_sur_h(tick_indices)')));
%         end
%     else
%         % Fallback if no data
%         xticks([0, 4, 8, 16, 32, 64]);
%         xticklabels({'0', '4', '8', '16', '32', '64'});
%         xlim([0, 65]);
%     end
% 
%     % --- Dynamic Y axis ---
%     if ~isempty(all_iterations)
%         all_iterations = all_iterations(all_iterations > 0);
%         if ~isempty(all_iterations)
%             y_min = min(all_iterations);
%             y_max = max(all_iterations);
% 
%             % Add 10% margin
%             y_range = y_max - y_min;
%             y_min = max(0, y_min - 0.1 * y_range);
%             y_max = y_max+0.1 * y_range;
% 
%             ylim([y_min, y_max]);
% 
%             % Create appropriate ticks
%             if length(all_iterations) <= 6
%                 % Use unique values as ticks
%                 y_ticks = unique(round(all_iterations));
%                 y_ticks = y_ticks(y_ticks >= y_min & y_ticks <= y_max);
%                 if length(y_ticks) > 6
%                     step = ceil(length(y_ticks) / 5);
%                     y_ticks = y_ticks(1:step:end);
%                 end
%                 yticks(y_ticks);
%             end
%         end
%     end
% 
%     % Linear Y scale
%     set(gca, 'YScale', 'linear');
% 
%     grid off;
%     set(gcf, 'Color', 'white');
%     hold off;
% 
%     % ====== ENHANCED LEGEND FUNCTION ======
%     function legende_formatee = formatLegende(nom_, L_val)
%         if contains(nom_, 'Newton')
%             legende_formatee = '$\mathbf{Newton}$';
%         elseif contains(nom_, 'Picard') && ~contains(nom_, 'L=')
%             legende_formatee = '$\mathbf{Picard}$';
%         else
%             % For all L-scheme, format with exact L value
%             if abs(L_val - round(L_val)) < 1e-10
%                 legende_formatee = sprintf('$\\mathbf{L-scheme\\ (L=%d)}$', round(L_val));
%             else
%                 legende_formatee = sprintf('$\\mathbf{L-scheme\\ (L=%.2f)}$', L_val);
%             end
%         end
%     end
% 
%     % ====== ITERATION TEXT FORMATTING ======
%     function str = formatIterations(val)
%         if abs(val - round(val)) < 1e-12
%             str = sprintf('(%d)', round(val));
%         else
%             if val < 10
%                 str = sprintf('(%.1f)', val);
%             else
%                 str = sprintf('(%.2f)', val);
%             end
%             str = regexprep(str, '\.0+\)$', ')');
%         end
%     end
% 
%     % ====== Drag functions ======
%     function legendButtonDown(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', @legendDrag, ...
%                  'WindowButtonUpFcn',      @stopLegendDrag);
%     end
% 
%     function legendDrag(~, ~)
%         currentPoint = get(gcf, 'CurrentPoint');
%         fig_pos      = get(gcf, 'Position');
%         legend_pos   = [currentPoint(1)/fig_pos(3), currentPoint(2)/fig_pos(4), 0.2, 0.2];
%         set(h_legend, 'Units','normalized', 'Position', legend_pos);
%     end
% 
%     function stopLegendDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', '', ...
%                  'WindowButtonUpFcn',      '');
%     end
% 
%     function startDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', @dragText, ...
%                  'WindowButtonUpFcn',      @stopDrag);
%     end
% 
%     function dragText(~, ~)
%         currentPoint = get(gca, 'CurrentPoint');
%         h_text       = gco;
%         if isgraphics(h_text, 'text')
%             newPos = [currentPoint(1,1), currentPoint(1,2), 0];
%             set(h_text, 'Position', newPos);
%         end
%     end
% 
%     function stopDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', '', ...
%                  'WindowButtonUpFcn',      '');
%     end
% 
%     fprintf(' Figure Iterations créée avec gestion dynamique des valeurs de L et axes dynamiques.\n');
% end
% 
% function figure_conditionnement_comparaison_complete(donnees, noms_schemas)
% %FIGURE_CONDITIONNEMENT_COMPARAISON_COMPLETE Create condition number comparison figure
% %   Generates a publication-quality figure comparing matrix condition numbers across
% %   different numerical schemes (L-scheme with various L values, Picard, Newton).
% %   Uses logarithmic scales with optimized margins to avoid excessive white space.
% %
% %   INPUTS:
% %       donnees      : Cell array of data structures from charger_toutes_donnees_comparaison
% %       noms_schemas : Cell array of scheme names for legend labels
% %
% %   DATA REQUIREMENTS:
% %       Each data structure must contain:
% %           - h_values   : vector of mesh sizes
% %           - Cond_max   : maximum condition numbers for each mesh
% %
% %   VISUALIZATION FEATURES:
% %       - Log-log plot (both axes logarithmic)
% %       - Each scheme plotted with distinct color and marker style
% %       - Condition number values displayed in parentheses near each data point
% %       - Dynamic axis limits with logarithmic margins to avoid empty space
% %       - Minor grid ticks on both axes
% %       - Drag-and-drop functionality for legend and text labels
% %       - LaTeX-formatted legend entries with exact L values
% %
% %   COLOR PALETTE:
% %       - L-scheme: Extended MATLAB default colors, assigned by sorted L value
% %       - Picard: Bright orange [0.8500, 0.3250, 0.0980]
% %       - Newton: Gray/black [0.2, 0.2, 0.2]
% %
% %   OUTPUT:
% %       Creates a figure with all schemes plotted and dynamically scaled axes.
% 
%     % FIGURE_CONDITIONNEMENT_COMPARAISON_COMPLETE - Figure conditionnement
%     % Version avec marges logarithmiques (pas de grand vide)
% 
%     figure('Position', [400, 100, 1000, 800], 'Name', 'Condition Numbers');
%     drawnow;
% 
%     % ---- Extended color palette ----
%     couleurs_base = [
%         0, 0.4470, 0.7410;     % blue
%         0.4660, 0.6740, 0.1880; % green
%         0.9290, 0.6940, 0.1250; % yellow/orange
%         0.4940, 0.1840, 0.5560; % purple
%         0.3010, 0.7450, 0.9330; % cyan
%         0.6350, 0.0780, 0.1840; % dark red
%         0.2, 0.2, 0.2;          % gray/black
%         0.8500, 0.3250, 0.0980  % bright orange
%     ];
% 
%     styles = {'-o', '-s', '-^', '-d', '-v', '-p', '-h', '--s'};
% 
%     hold on;
% 
%     % Store text handles for drag functionality
%     text_handles = [];
% 
%     % ---- Collect all values for dynamic axis scaling ----
%     all_un_sur_h = [];
%     all_y_values = [];
% 
%     for i = 1:length(donnees)
%         if isfield(donnees{i}, 'h_values') && isfield(donnees{i}, 'Cond_max')
%             un_sur_h = 1 ./ donnees{i}.h_values;
%             cond_max = donnees{i}.Cond_max;
% 
%             n_points = min(length(un_sur_h), length(cond_max));
%             if n_points > 0
%                 all_un_sur_h = [all_un_sur_h; un_sur_h(1:n_points)];
%                 all_y_values = [all_y_values; cond_max(1:n_points)];
%             end
%         end
%     end
% 
%     % ---- Extract and sort L values ----
%     L_values = [];
%     indices_L = [];
% 
%     for i = 1:numel(noms_schemas)
%         nom = noms_schemas{i};
%         if contains(nom, 'L=')
%             tok = regexp(nom, 'L=([0-9.eE+-]+)', 'tokens', 'once');
%             if ~isempty(tok)
%                 L_val = str2double(tok{1});
%                 L_values = [L_values, L_val];
%                 indices_L = [indices_L, i];
%             end
%         end
%     end
% 
%     % Sort L values in ascending order
%     if ~isempty(L_values)
%         [L_values_sorted, sort_idx] = sort(L_values);
%         indices_L_sorted = indices_L(sort_idx);
% 
%         % Create color mapping for each L value
%         couleur_map = containers.Map();
%         for k = 1:length(L_values_sorted)
%             couleur_map(num2str(L_values_sorted(k))) = couleurs_base(mod(k-1, size(couleurs_base,1))+1, :);
%         end
% 
%         % ---- Plot all L-scheme in sorted order ----
%         for idx = indices_L_sorted
%             data = donnees{idx};
%             nom = noms_schemas{idx};
% 
%             tok = regexp(nom, 'L=([0-9.eE+-]+)', 'tokens', 'once');
%             L_val = str2double(tok{1});
%             couleur = couleur_map(num2str(L_val));
% 
%             if isfield(data, 'h_values') && isfield(data, 'Cond_max')
%                 un_sur_h = 1 ./ data.h_values;
%                 cond_max = data.Cond_max;
% 
%                 n_points = min(length(un_sur_h), length(cond_max));
%                 un_sur_h = un_sur_h(1:n_points);
%                 cond_max = cond_max(1:n_points);
% 
%                 style_idx = find(L_values_sorted == L_val, 1);
% 
%                 loglog(un_sur_h, cond_max, styles{mod(style_idx-1, length(styles))+1}, ...
%                      'Color', couleur, ...
%                      'LineWidth', 3.5, ...
%                      'MarkerSize', 8, ...
%                      'MarkerFaceColor', couleur, ...
%                      'DisplayName', formatLegende(nom, L_val));
% 
%                 % Add labels in parentheses
%                 for j = 1:n_points
%                     label_text = sprintf('(%d)', round(cond_max(j)));
%                     h_text = text(un_sur_h(j), cond_max(j), label_text, ...
%                         'FontSize', 20, 'FontWeight', 'bold', ...
%                         'Color', couleur, ...
%                         'HorizontalAlignment', 'center', ...
%                         'VerticalAlignment', 'bottom', ...
%                         'ButtonDownFcn', @startDrag);
% 
%                     text_handles = [text_handles, h_text];
%                 end
% 
%                 drawnow;
%             end
%         end
%     end
% 
%     % ---- Plot Picard ----
%     picard_idx = find(cellfun(@(x) contains(x, 'Picard') && ~contains(x, 'L='), noms_schemas));
%     if ~isempty(picard_idx)
%         for idx = picard_idx'
%             data = donnees{idx};
%             if isfield(data, 'h_values') && isfield(data, 'Cond_max')
%                 un_sur_h = 1 ./ data.h_values;
%                 cond_max = data.Cond_max;
% 
%                 n_points = min(length(un_sur_h), length(cond_max));
%                 un_sur_h = un_sur_h(1:n_points);
%                 cond_max = cond_max(1:n_points);
% 
%                 loglog(un_sur_h, cond_max, '-d', ...
%                      'Color', [0.8500, 0.3250, 0.0980], ...
%                      'LineWidth', 3.5, ...
%                      'MarkerSize', 8, ...
%                      'MarkerFaceColor', [0.8500, 0.3250, 0.0980], ...
%                      'DisplayName', '$\mathbf{Picard}$');
% 
%                 % Add labels in parentheses for Picard
%                 for j = 1:n_points
%                     label_text = sprintf('(%d)', round(cond_max(j)));
%                     h_text = text(un_sur_h(j), cond_max(j), label_text, ...
%                         'FontSize', 20, 'FontWeight', 'bold', ...
%                         'Color', [0.8500, 0.3250, 0.0980], ...
%                         'HorizontalAlignment', 'center', ...
%                         'VerticalAlignment', 'bottom', ...
%                         'ButtonDownFcn', @startDrag);
% 
%                     text_handles = [text_handles, h_text];
%                 end
% 
%                 drawnow;
%             end
%         end
%     end
% 
%     % ---- Plot Newton ----
%     newton_idx = find(cellfun(@(x) contains(x, 'Newton'), noms_schemas));
%     if ~isempty(newton_idx)
%         for idx = newton_idx'
%             data = donnees{idx};
%             if isfield(data, 'h_values') && isfield(data, 'Cond_max')
%                 un_sur_h = 1 ./ data.h_values;
%                 cond_max = data.Cond_max;
% 
%                 n_points = min(length(un_sur_h), length(cond_max));
%                 un_sur_h = un_sur_h(1:n_points);
%                 cond_max = cond_max(1:n_points);
% 
%                 loglog(un_sur_h, cond_max, '--s', ...
%                      'Color', [0.2, 0.2, 0.2], ...
%                      'LineWidth', 3.5, ...
%                      'MarkerSize', 9, ...
%                      'MarkerFaceColor', [0.2, 0.2, 0.2], ...
%                      'DisplayName', '$\mathbf{Newton}$');
% 
%                 % Add labels in parentheses for Newton
%                 for j = 1:n_points
%                     label_text = sprintf('(%d)', round(cond_max(j)));
%                     h_text = text(un_sur_h(j), cond_max(j), label_text, ...
%                         'FontSize', 20, 'FontWeight', 'bold', ...
%                         'Color', [0.2, 0.2, 0.2], ...
%                         'HorizontalAlignment', 'center', ...
%                         'VerticalAlignment', 'bottom', ...
%                         'ButtonDownFcn', @startDrag);
% 
%                     text_handles = [text_handles, h_text];
%                 end
% 
%                 drawnow;
%             end
%         end
%     end
% 
%     % Axis configuration
%     ax = gca;
%     ax.FontSize = 20;
%     ax.LineWidth = 1.5;
%     ax.FontWeight = 'bold';
%     ax.Box = 'off';
%     ax.TickDir = 'out';
% 
%     xlabel('1/h', 'FontSize', 20, 'FontWeight', 'bold');
% 
%     % Logarithmic scales
%     set(gca, 'XScale', 'log', 'YScale', 'log');
% 
%     % === DYNAMIC X AXIS ===
%     if ~isempty(all_un_sur_h)
%         all_un_sur_h = unique(all_un_sur_h);
% 
%         log_min = log10(min(all_un_sur_h));
%         log_max = log10(max(all_un_sur_h));
% 
%         % Logarithmic margin
%         log_min = log_min - 0.02;
%         log_max = log_max+0.1;
% 
%         xlim(10.^[log_min, log_max]);
% 
%         pow_min = floor(log_min);
%         pow_max = ceil(log_max);
% 
%         if (pow_max - pow_min) > 5
%             step = 2;
%         else
%             step = 1;
%         end
% 
%         x_ticks = 10.^(pow_min:step:pow_max);
%         xticks(x_ticks);
% 
%         x_labels = arrayfun(@(x) sprintf('10^{%d}', round(log10(x))), x_ticks, 'UniformOutput', false);
%         xticklabels(x_labels);
% 
%         ax.XMinorTick = 'on';
%     end
% 
%     % === DYNAMIC Y AXIS (CORRECTED - logarithmic margins) ===
%     if ~isempty(all_y_values)
%         all_y_values = unique(all_y_values);
%         all_y_values = all_y_values(all_y_values > 0);  % Keep only positive values
% 
%         if ~isempty(all_y_values)
%             log_min = log10(min(all_y_values));
%             log_max = log10(max(all_y_values));
% 
%             % CORRECTION: Logarithmic margin (0.1 in log ≈ 25% in linear)
%             % But not too large to avoid excessive white space
%             if (log_max - log_min) < 0.5
%                 % If values are very close, use smaller margin
%                 log_min = log_min - 0.05;
%                 log_max = log_max+0.05;
%             else
%                 log_min = log_min - 0.1;
%                 log_max = log_max+0.1;
%             end
% 
%             y_min_pow = 10^log_min;
%             y_max_pow = 10^log_max;
% 
%             ylim([y_min_pow, y_max_pow]);
% 
%             pow_min = floor(log_min);
%             pow_max = ceil(log_max);
% 
%             if (pow_max - pow_min) > 5
%                 step = 2;
%             else
%                 step = 1;
%             end
% 
%             y_ticks = 10.^(pow_min:step:pow_max);
%             yticks(y_ticks);
% 
%             y_labels = arrayfun(@(x) sprintf('10^{%d}', round(log10(x))), y_ticks, 'UniformOutput', false);
%             yticklabels(y_labels);
% 
%             ax.YMinorTick = 'on';
%         end
%     end
% 
%     % Legend
%     h_legend = legend('Location', 'northwest', 'FontSize', 20, 'Box', 'on', ...
%                       'Interpreter', 'latex');
%     set(h_legend, 'ButtonDownFcn', @legendButtonDown);
% 
%     grid off;
%     set(gcf, 'Color', 'white');
%     hold off;
%     drawnow;
% 
%     % === HELPER FUNCTIONS ===
%     function legende_formatee = formatLegende(nom, L_val)
%         if contains(nom, 'Newton')
%             legende_formatee = '$\mathbf{Newton}$';
%         elseif contains(nom, 'Picard') && ~contains(nom, 'L=')
%             legende_formatee = '$\mathbf{Picard}$';
%         else
%             if abs(L_val - round(L_val)) < 1e-10
%                 legende_formatee = sprintf('$\\mathbf{L-scheme\\ (L=%d)}$', round(L_val));
%             else
%                 legende_formatee = sprintf('$\\mathbf{L-scheme\\ (L=%.2f)}$', L_val);
%             end
%         end
%     end
% 
%     function legendButtonDown(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', @legendDrag, ...
%                  'WindowButtonUpFcn', @stopLegendDrag);
%     end
% 
%     function legendDrag(~, ~)
%         cp = get(gcf, 'CurrentPoint');
%         fp = get(gcf, 'Position');
%         set(h_legend, 'Units','normalized', 'Position', [cp(1)/fp(3), cp(2)/fp(4), 0.2, 0.2]);
%         drawnow;
%     end
% 
%     function stopLegendDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
%     end
% 
%     % === FUNCTIONS FOR DRAGGING TEXT LABELS ===
%     function startDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', @dragText, ...
%                  'WindowButtonUpFcn', @stopDrag);
%     end
% 
%     function dragText(~, ~)
%         try
%             currentPoint = get(gca, 'CurrentPoint');
%             h_text = gco;
%             if isgraphics(h_text, 'text')
%                 newPos = [currentPoint(1,1), currentPoint(1,2), 0];
%                 set(h_text, 'Position', newPos);
%             end
%         catch
%         end
%     end
% 
%     function stopDrag(~, ~)
%         set(gcf, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
%     end
% 
%     fprintf(' Figure Condition Numbers avec marges logarithmiques (pas de grand vide) et labels entre parenthèses.\n');
% end
% 
% function [p, tmesh, u, tm, file_path] = charger_donnees_temps(output_folder, nx, temps)
% %CHARGER_DONNEES_TEMPS Robust time-dependent solution loader
% %   Loads solution data for a specified mesh resolution and time from the
% %   solutions_temporelles directory. Handles missing parameters intelligently:
% %       - If time is empty, loads the latest available time for given nx
% %       - If nx is empty, uses the finest available mesh resolution
% %
% %   INPUTS:
% %       output_folder : Path to solutions_temporelles directory
% %       nx            : Mesh resolution (number of points) - can be empty
% %       temps         : Requested time - can be empty (loads latest)
% %
% %   OUTPUTS:
% %       p         : Node coordinates matrix [x,y,z]
% %       tmesh     : Mesh connectivity/topology
% %       u         : Solution values at nodes
% %       tm        : Actual time loaded (may differ from requested temps)
% %       file_path : Full path to loaded file (useful for debugging)
% %
% %   FILE NAMING CONVENTION:
% %       solution_nx{value}_t{value}s.mat
% %       Example: solution_nx17_t10s.mat
% %
% %   BEHAVIOR:
% %       - Scans directory for all solution_nx*_t*.mat files
% %       - Parses nx and t values from filenames
% %       - If nx not provided, uses maximum available nx
% %       - If temps provided, finds closest available time
% %       - If temps empty, loads the latest time for chosen nx
% %
% %   OUTPUT:
% %       Loaded data structure containing p, t, and solution field.
% 
%     p = []; tmesh = []; u = []; tm = []; file_path = '';
% 
%     if nargin < 2, nx = []; end
%     if nargin < 3, temps = []; end
% 
%     if exist(output_folder,'dir') ~= 7
%         fprintf(' Directory does not exist: %s\n', output_folder);
%         return;
%     end
% 
%     files = dir(fullfile(output_folder,'solution_nx*_t*s.mat'));
%     if isempty(files)
%         fprintf(' No solution_nx*_t*s.mat files in: %s\n', output_folder);
%         return;
%     end
% 
%     % ---- Extract (nx, t) from filenames
%     NX = nan(numel(files),1);
%     TT = nan(numel(files),1);
% 
%     for i=1:numel(files)
%         name = files(i).name;
% 
%         tokNx = regexp(name,'solution_nx(\d+)_','tokens','once');
%         tokT  = regexp(name,'_t([^s]+)s\.mat$','tokens','once'); % captures 10, 10.0, 1e-1, etc.
% 
%         if ~isempty(tokNx), NX(i) = str2double(tokNx{1}); end
%         if ~isempty(tokT),  TT(i) = str2double(tokT{1});  end
%     end
% 
%     ok = isfinite(NX) & isfinite(TT);
%     NX = NX(ok); TT = TT(ok); files = files(ok);
% 
%     if isempty(files)
%         fprintf(' Unable to parse nx/t from filenames in: %s\n', output_folder);
%         return;
%     end
% 
%     % ---- Select nx if not provided
%     if isempty(nx)
%         nx = max(NX);
%     end
% 
%     idxNx = find(NX == nx);
%     if isempty(idxNx)
%         fprintf(' No files for nx=%d in: %s\n', nx, output_folder);
%         return;
%     end
% 
%     % ---- Select time
%     TTnx = TT(idxNx);
% 
%     if isempty(temps)
%         % Latest time
%         [~,k] = max(TTnx);
%         pick = idxNx(k);
%     else
%         % Closest time
%         [~,k] = min(abs(TTnx - temps));
%         pick = idxNx(k);
%     end
% 
%     file_path = fullfile(output_folder, files(pick).name);
% 
%     if exist(file_path,'file') ~= 2
%         fprintf(' File not found: %s\n', file_path);
%         return;
%     end
% 
%     data = load(file_path);
% 
%     % --- Solution field (u or u0) ---
%     if isfield(data, 'u')
%         u = data.u;
%     elseif isfield(data, 'u0')
%         u = data.u0;
%     else
%         fprintf(' Solution variable missing in: %s\n', file_path);
%         return;
%     end
% 
%     if isfield(data,'p'), p = data.p; else, fprintf(' p missing\n'); return; end
%     if isfield(data,'t'), tmesh = data.t; else, fprintf(' t missing\n'); return; end
% 
%     % --- Actual time ---
%     if isfield(data,'tm')
%         tm = data.tm;
%     else
%         tm = TT(pick); % time extracted from filename
%     end
% 
%     fprintf(' Loaded: nx=%d | t=%.6g | %s\n', nx, tm, files(pick).name);
% end
function batch_view_rules_bat()
%BATCH_VIEW_RULES_BAT Automated post-processing for Richards 3D simulations (NEWTON)
%   Executes a fixed sequence of visualization routines without user input.
%   ADAPTED FOR NEWTON SOLVER.

    % === ADD NECESSARY PATHS ===
    root_dir = fileparts(mfilename('fullpath'));
    
    % Add all necessary subfolders to the path
    addpath(root_dir);
    addpath(fullfile(root_dir, 'FEM'));
    addpath(fullfile(root_dir, 'models'));
    addpath(fullfile(root_dir, 'solvers'));
    addpath(fullfile(root_dir, 'utils'));
    addpath(fullfile(root_dir, 'gui'));
    addpath(fullfile(root_dir, 'visualization'));
    % === END PATH CONFIGURATION ===

    fprintf('\n============================================\n');
    fprintf(' BATCH VIEWER (AUTO-RUN) - NEWTON SOLVER\n');
    fprintf('============================================\n');

    % --------- Option 1: Physical case (Newton) ----------
    physical_case_t10_only();

    % --------- Option 2: Scheme comparison (3 figs) -------------
    run_comparison_fixed_3figs();
    
    % --------- Option 3: Error tables for Newton (λ values) -------------
    visualiser_tableau_erreur_Newton()

    fprintf('\n AUTO-RUN DONE (physical_case+comparison+Newton).\n');
end

%% ==================== ERROR TABLES FOR NEWTON ====================

function visualiser_tableau_erreur_Newton()
%VISUALISER_TABLEAU_ERREUR_NEWTON Interactive visualization of error tables for Newton method
%   Scans the numerical_validation/Newton directory for lambda_* folders
%   and displays error tables.

    fprintf('\n--- Error Tables Visualization (Newton) ---\n');

    thisFileDir = fileparts(mfilename('fullpath'));
    base_results_dir = fullfile(thisFileDir, 'results');
    validation_dir = fullfile(base_results_dir, 'numerical_validation');

    if exist(validation_dir, 'dir') ~= 7
        fprintf(' Missing folder: %s\n', validation_dir);
        return;
    end

    Newton_root = fullfile(validation_dir, 'Newton');
    if exist(Newton_root, 'dir') ~= 7
        fprintf(' Missing folder: %s\n', Newton_root);
        return;
    end

    lambda_dirs = dir(Newton_root);
    lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
    
    lambda_values = [];
    lambda_paths = {};
    
    for k = 1:length(lambda_dirs)
        lambda_name = lambda_dirs(k).name;
        tok = regexp(lambda_name, 'lambda_([0-9_]+)', 'tokens', 'once');
        if ~isempty(tok)
            lambda_str = strrep(tok{1}, '_', '.');
            lambda_val = str2double(lambda_str);
            
            dt_path = fullfile(Newton_root, lambda_name);
            dt_dirs = dir(dt_path);
            dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
            
            for d = 1:length(dt_dirs)
                data_file = fullfile(dt_path, dt_dirs(d).name, 'resultats_complets', 'resultats_complets.mat');
                if exist(data_file, 'file') == 2
                    lambda_values = [lambda_values; lambda_val];
                    lambda_paths{end+1} = fullfile(dt_path, dt_dirs(d).name);
                end
            end
        end
    end
    
    if isempty(lambda_values)
        fprintf(' No lambda folders with valid data found\n');
        return;
    end
    
    [lambda_values_unique, idx_unique] = unique(lambda_values);
    lambda_paths_unique = lambda_paths(idx_unique);
    
    [lambda_values_sorted, sort_idx] = sort(lambda_values_unique);
    lambda_paths_sorted = lambda_paths_unique(sort_idx);
    
    lambda_names = {};
    for k = 1:length(lambda_values_sorted)
        lambda_names{end+1} = sprintf('\x03BB = %.4f', lambda_values_sorted(k));
    end
    lambda_names{end+1} = 'VIEW ALL TABLES';

    [selection_idx, ok] = listdlg(...
        'PromptString', 'Select \x03BB value to visualize:', ...
        'SelectionMode', 'single', ...
        'ListString', lambda_names, ...
        'Name', '\x03BB Selection (Newton)', ...
        'ListSize', [350, 350], ...
        'OKString', 'Visualize', ...
        'CancelString', 'Cancel');

    if ~ok || isempty(selection_idx)
        fprintf(' Visualization cancelled.\n');
        return;
    end

    if selection_idx == length(lambda_names)
        for i = 1:length(lambda_paths_sorted)
            afficher_tableau_erreur_ameliore_Newton(lambda_paths_sorted{i}, lambda_values_sorted(i));
        end
    else
        afficher_tableau_erreur_ameliore_Newton(lambda_paths_sorted{selection_idx}, lambda_values_sorted(selection_idx));
    end

    fprintf(' Visualization completed.\n');
end

function afficher_tableau_erreur_ameliore_Newton(results_dir, lambda_val)
%AFFICHER_TABLEAU_ERREUR_AMELIORE_NEWTON Publication-quality error table for Newton

    data_file = fullfile(results_dir, 'resultats_complets', 'resultats_complets.mat');

    if exist(data_file, 'file') ~= 2
        fprintf(' No data found for \x03BB = %.4f\n', lambda_val);
        return;
    end

    data = load(data_file);

    if ~isfield(data, 'h_values') || ~isfield(data, 'Erreur_L2')
        fprintf(' Missing fields (h_values / Erreur_L2) for \x03BB = %.4f\n', lambda_val);
        return;
    end

    fig = figure('Position', [150, 150, 1100, 700], ...
        'Name', sprintf('Error Analysis - Newton \x03BB = %.4f', lambda_val), ...
        'NumberTitle', 'off', ...
        'Color', [1 1 1]);
    
    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Change \x03BB', ...
        'Units', 'normalized', ...
        'Position', [0.82, 0.92, 0.14, 0.055], ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', @(~,~) switch_lambda_and_refresh(fig, results_dir, lambda_val));

    fontNameBody  = 'Times New Roman';
    fontSizeTitle = 24;
    fontSizeHead  = 18;
    fontSizeBody  = 16;

    colTitle   = [0.10 0.20 0.45];
    colBorder  = [0.55 0.62 0.78];
    colGrid    = [0.80 0.86 0.94];
    colHeader  = [0.92 0.95 1.00];
    colRowA    = [1.00 1.00 1.00];
    colRowB    = [0.97 0.985 1.00];
    colStatsBG = [0.95 0.98 1.00];

    annotation('textbox', [0.12, 0.905, 0.76, 0.07], ...
        'String', sprintf('Error Analysis for Newton method: $\\lambda = %.4f$', lambda_val), ...
        'FontSize', fontSizeTitle, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'EdgeColor', 'none', ...
        'Interpreter', 'latex', ...
        'Color', colTitle);

    un_sur_h = 1 ./ data.h_values(:);
    [un_sur_h, idx] = sort(un_sur_h, 'ascend');
    errL2 = data.Erreur_L2(:);
    errL2 = errL2(idx);

    hasH1 = isfield(data, 'Erreur_H1');
    if hasH1
        errH1 = data.Erreur_H1(:);
        errH1 = errH1(idx);
    end

    nx_vals = round(un_sur_h);

    left   = 0.10;
    right  = 0.90;
    top    = 0.80;
    bottom = 0.30;

    W = right - left;
    H = top - bottom;

    nRows = numel(nx_vals);
    rowH  = H / (nRows+1);
    colW  = W / 4;

    x0 = left;
    x1 = x0+colW;
    x2 = x1+colW;
    x3 = x2+colW;
    xCenters = [x0+colW/2, x1+colW/2, x2+colW/2, x3+colW/2];

    annotation('rectangle', [left, bottom, W, H], ...
        'EdgeColor', colBorder, 'LineWidth', 2, 'FaceColor', 'none');

    annotation('rectangle', [left, top-rowH, W, rowH], ...
        'FaceColor', colHeader, 'EdgeColor', 'none');

    headers = {'$1/h$', '$L_2$ error', '$H_1$ error', 'Order'};
    for c = 1:4
        annotation('textbox', [xCenters(c)-colW/2, top-rowH, colW, rowH], ...
            'String', headers{c}, ...
            'FontSize', fontSizeHead, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'EdgeColor', 'none', ...
            'Interpreter', 'latex', ...
            'Color', [0 0 0]);
    end

    for x = [x1, x2, x3]
        annotation('line', [x, x], [bottom, top], ...
            'Color', colGrid, 'LineWidth', 1);
    end

    orders = [];

    for i = 1:nRows
        yRow = top - rowH*(i+1);

        bg = colRowA;
        if mod(i,2) == 0
            bg = colRowB;
        end
        annotation('rectangle', [left, yRow, W, rowH], ...
            'FaceColor', bg, 'EdgeColor', 'none');

        cell1 = sprintf('$1/%d$', nx_vals(i));

        [m2, e2] = format_scientific(errL2(i));
        cell2 = sprintf('$%.2f \\times 10^{%d}$', m2, e2);

        if hasH1
            [m1, e1] = format_scientific(errH1(i));
            cell3 = sprintf('$%.2f \\times 10^{%d}$', m1, e1);
        else
            cell3 = '$-$';
        end

        if i < nRows
            ord = log10(errL2(i)/errL2(i+1)) / log10(2);
            orders = [orders, ord];
            cell4 = sprintf('$%.2f$', ord);
        else
            cell4 = '$-$';
        end

        rowCells = {cell1, cell2, cell3, cell4};

        for c = 1:4
            annotation('textbox', [xCenters(c)-colW/2, yRow, colW, rowH], ...
                'String', rowCells{c}, ...
                'FontName', fontNameBody, ...
                'FontSize', fontSizeBody, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'EdgeColor', 'none', ...
                'Interpreter', 'latex', ...
                'Color', [0 0 0]);
        end
    end

    for i = 1:nRows
        y = top - rowH*(i+1);
        annotation('line', [left, right], [y, y], ...
            'Color', colGrid, 'LineWidth', 1);
    end

    [min_err, min_idx] = min(errL2);
    [m_min, e_min] = format_scientific(min_err);

    if isempty(orders)
        avg_order = NaN;
    else
        avg_order = mean(orders);
    end

    if ~isnan(avg_order)
        stats_text = sprintf(['Best performance (Newton)\n' ...
            'Minimum L2 error: $%.2f \\times 10^{%d}$  (1/%d)\n' ...
            'Average order: $%.2f$'], ...
            m_min, e_min, nx_vals(min_idx), avg_order);
    else
        stats_text = sprintf(['Best performance (Newton)\n' ...
            'Minimum L2 error: $%.2f \\times 10^{%d}$  (1/%d)\n' ...
            'Average order: N/A'], ...
            m_min, e_min, nx_vals(min_idx));
    end

    annotation('textbox', [0.22, 0.08, 0.56, 0.14], ...
        'String', stats_text, ...
        'FontName', fontNameBody, ...
        'FontSize', 16, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'EdgeColor', colBorder, ...
        'LineWidth', 2, ...
        'BackgroundColor', colStatsBG, ...
        'Interpreter', 'latex', ...
        'Color', colTitle);

    fprintf(' Table displayed for \x03BB = %.4f (Newton)\n', lambda_val);
    fprintf('   - Number of mesh levels: %d\n', nRows);
    fprintf('   - Average convergence order: %.2f\n', avg_order);
    fprintf('   - Minimum L2 error: %.2e\n', min_err);
end

function switch_lambda_and_refresh(figHandle, current_results_dir, current_lambda_val)
%SWITCH_LAMBDA_AND_REFRESH Open a list of available λ folders and refresh the figure

    Newton_root = fileparts(fileparts(current_results_dir));
    if exist(Newton_root, 'dir') ~= 7
        errordlg(sprintf('Folder not found:\n%s', Newton_root), 'Error');
        return;
    end

    lambda_dirs = dir(Newton_root);
    lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
    
    lambda_values = [];
    lambda_paths = {};
    
    for k = 1:length(lambda_dirs)
        name = lambda_dirs(k).name;
        tok = regexp(name, 'lambda_([0-9_]+)', 'tokens', 'once');
        if ~isempty(tok)
            lambda_str = strrep(tok{1}, '_', '.');
            lambda_val = str2double(lambda_str);
            
            dt_path = fullfile(Newton_root, name);
            dt_dirs = dir(dt_path);
            dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
            
            for d = 1:length(dt_dirs)
                data_file = fullfile(dt_path, dt_dirs(d).name, 'resultats_complets', 'resultats_complets.mat');
                if exist(data_file, 'file') == 2
                    lambda_values = [lambda_values; lambda_val];
                    lambda_paths{end+1} = fullfile(dt_path, dt_dirs(d).name);
                end
            end
        end
    end
    
    if isempty(lambda_values)
        errordlg('No lambda folders with valid data found.', 'Error');
        return;
    end
    
    [lambda_values_unique, idx_unique] = unique(lambda_values);
    lambda_paths_unique = lambda_paths(idx_unique);
    
    [lambda_values_sorted, idx_sorted] = sort(lambda_values_unique);
    lambda_paths_sorted = lambda_paths_unique(idx_sorted);

    items = cell(numel(lambda_values_sorted), 1);
    for k = 1:numel(lambda_values_sorted)
        items{k} = sprintf('\x03BB = %.6g', lambda_values_sorted(k));
    end

    preSel = find(abs(lambda_values_sorted - current_lambda_val) < 1e-12, 1);
    if isempty(preSel), preSel = 1; end

    [sel, okDlg] = listdlg( ...
        'PromptString', 'Select \x03BB value:', ...
        'SelectionMode', 'single', ...
        'ListString', items, ...
        'InitialValue', preSel, ...
        'ListSize', [300, 300], ...
        'Name', 'Choose \x03BB (Newton)');

    if ~okDlg || isempty(sel)
        return;
    end

    new_lambda = lambda_values_sorted(sel);
    new_results_dir = lambda_paths_sorted{sel};

    if isvalid(figHandle)
        close(figHandle);
    end
    afficher_tableau_erreur_ameliore_Newton(new_results_dir, new_lambda);
end

function [m, e] = format_scientific(x)
%FORMAT_SCIENTIFIC Convert numeric value to mantissa-exponent representation
    if x == 0
        m = 0;
        e = 0;
        return;
    end
    e = floor(log10(abs(x)));
    m = x / 10^e;
    m = round(m * 100) / 100;
end

%% ==================== PHYSICAL CASE VISUALIZATION ====================

function physical_case_t10_only()
%PHYSICAL_CASE_T10_ONLY Interactive visualization of physical case results (NEWTON)

    clc;

    FIG_POS = [100, 100, 1000, 800];
    thisFileDir = fileparts(mfilename('fullpath'));
    base_results_dir = fullfile(thisFileDir, 'results');
    case_root = fullfile(base_results_dir, 'physical_case');

    scheme_root = fullfile(case_root, 'Newton');
    if exist(scheme_root,'dir') ~= 7
        fprintf(' Missing: %s\n', scheme_root);
        return;
    end

    lambda_dirs = dir(scheme_root);
    lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));

    if isempty(lambda_dirs)
        fprintf(' No lambda folder found in: %s\n', scheme_root);
        return;
    end

    bestIdx = [];
    bestTime = -inf;

    for k = 1:numel(lambda_dirs)
        cand = fullfile(scheme_root, lambda_dirs(k).name);
        
        dt_dirs = dir(cand);
        dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
        
        for d = 1:numel(dt_dirs)
            sol_dir_k = fullfile(cand, dt_dirs(d).name, 'solutions_temporelles');
            if exist(sol_dir_k,'dir') ~= 7
                continue;
            end

            fsol = dir(fullfile(sol_dir_k, 'solution_nx*_t*s.mat'));
            if isempty(fsol)
                continue;
            end

            newestFileTime = max([fsol.datenum]);
            if newestFileTime > bestTime
                bestTime = newestFileTime;
                bestIdx = struct('lambda_dir', lambda_dirs(k).name, 'dt_dir', dt_dirs(d).name);
            end
        end
    end

    if isempty(bestIdx)
        fprintf(' No lambda folder with solution files found under: %s\n', scheme_root);
        return;
    end

    chosen_dir = fullfile(scheme_root, bestIdx.lambda_dir, bestIdx.dt_dir);
    fprintf('\n Using physical_case Newton folder (with newest solutions):\n   %s\n', chosen_dir);

    sol_dir = fullfile(chosen_dir, 'solutions_temporelles');

    fprintf('\n--- PHYSICAL CASE (NEWTON) | INTERACTIVE TIME SELECTION ---\n');

    if exist(sol_dir,'dir') ~= 7
        fprintf(' Missing: %s\n', sol_dir);
        return;
    end

    files = dir(fullfile(sol_dir, 'solution_nx*_t*s.mat'));
    if isempty(files)
        fprintf(' No solution_nx*_t*s.mat files in: %s\n', sol_dir);
        return;
    end

    nxVals = nan(numel(files),1);
    for i = 1:numel(files)
        tok = regexp(files(i).name, 'solution_nx(\d+)_', 'tokens', 'once');
        if ~isempty(tok)
            nxVals(i) = str2double(tok{1});
        end
    end
    nxVals = nxVals(isfinite(nxVals));
    if isempty(nxVals)
        fprintf(' Unable to extract nx from filenames in: %s\n', sol_dir);
        return;
    end
    nx = max(nxVals);

    pattern = sprintf('solution_nx%d_t*.mat', nx);
    time_files = dir(fullfile(sol_dir, pattern));

    if isempty(time_files)
        fprintf(' No solution files found for nx=%d\n', nx);
        return;
    end

    time_values = [];
    time_strings = {};

    for i = 1:numel(time_files)
        tok = regexp(time_files(i).name, '_t([0-9.eE+-]+)s\.mat', 'tokens', 'once');
        if ~isempty(tok)
            t_val = str2double(tok{1});
            if isfinite(t_val)
                time_values = [time_values; t_val];
                time_strings = [time_strings; {sprintf('t = %.6g h', t_val)}];
            end
        end
    end

    if isempty(time_values)
        fprintf(' Unable to extract time values from filenames\n');
        return;
    end

    [time_values, sort_idx] = sort(time_values, 'ascend');
    time_strings = time_strings(sort_idx);

    n = length(time_strings);
    rowH = 30;
    titleH = 40;
    bottomMargin = 90;
    topMargin = 20;

    figW = 520;
    figH = bottomMargin + rowH*n + titleH + topMargin;

    sel_fig = figure('Name', 'Select Time Steps (Newton)', ...
        'NumberTitle', 'off', ...
        'Position', [500, 350, figW, figH], ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Resize', 'off', ...
        'Color', [0.94 0.94 0.94]);

    uicontrol('Style', 'text', ...
        'Position', [30, bottomMargin + rowH*n + 10, figW-60, titleH-10], ...
        'String', sprintf('Select time steps to visualize (nx = %d - Newton):', nx), ...
        'FontSize', 14, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', [0.94 0.94 0.94]);

    checkboxes = gobjects(n,1);
    for i = 1:n
        y = bottomMargin + rowH*(n - i);
        checkboxes(i) = uicontrol('Style', 'checkbox', ...
            'Position', [40, y, figW-120, 28], ...
            'String', time_strings{i}, ...
            'FontSize', 12, ...
            'Value', 0);
    end

    uicontrol('Style', 'pushbutton', ...
        'Position', [150, 25, 100, 35], ...
        'String', 'Select All', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'Callback', @(~,~) set(checkboxes, 'Value', 1));

    uicontrol('Style', 'pushbutton', ...
        'Position', [260, 25, 100, 35], ...
        'String', 'Clear All', ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'Callback', @(~,~) set(checkboxes, 'Value', 0));

    uicontrol('Style', 'pushbutton', ...
        'Position', [380, 25, 80, 35], ...
        'String', 'OK', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Callback', 'uiresume(gcbf)');

    uicontrol('Style', 'pushbutton', ...
        'Position', [40, 25, 80, 35], ...
        'String', 'Cancel', ...
        'FontSize', 12, ...
        'Callback', @(~,~) close(sel_fig));

    uiwait(sel_fig);

    if ~isvalid(sel_fig)
        fprintf(' Visualization cancelled by user.\n');
        return;
    end

    sel_indices = find([checkboxes.Value] == 1);
    close(sel_fig);

    if isempty(sel_indices)
        fprintf(' No time steps selected. Visualization cancelled.\n');
        return;
    end

    selected_times = time_values(sel_indices);
    fprintf(' Selected %d time(s) for visualization (Newton)\n', length(selected_times));
    for i = 1:length(selected_times)
        fprintf('   - t = %.6g h\n', selected_times(i));
    end

    cut_mode = 2;
    cut_val = 0.5;

    for t_idx = 1:length(selected_times)
        t_fixed = selected_times(t_idx);

        fprintf('\n Generating visualizations for t = %.6g h (%d/%d) - Newton\n', ...
            t_fixed, t_idx, length(selected_times));

        figure('Position', FIG_POS, ...
            'Name', sprintf('Isosurface (Newton) | t=%.6g h', t_fixed), ...
            'Color','w');
        show_isosurface_from_file(sol_dir, nx, t_fixed);

        title({sprintf('Isosurface at $t = %.4f$ h (Newton)', t_fixed); ...
               sprintf('$\\mathit{h} = 1/(%d-1)$', nx)}, ...
            'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        drawnow;

        figure('Position', FIG_POS, ...
            'Name', sprintf('Cross-section x=%.2f (Newton) | t=%.6g h', cut_val, t_fixed), ...
            'Color','w');
        show_cut_from_file(sol_dir, nx, t_fixed, cut_mode, cut_val);

        title({sprintf('Cross-section at $t = %.4f$ h (Newton)', t_fixed); ...
               sprintf('$\\mathit{h} = 1/(%d-1)$', nx)}, ...
            'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        drawnow;
    end

    fprintf('\n Done: %d time(s) displayed for physical case (Newton).\n', length(selected_times));
end

%% ==================== SCHEME COMPARISON ====================

function run_comparison_fixed_3figs()
%RUN_COMPARISON_FIXED_3FIGS Generate three standard comparison figures for numerical schemes

    fprintf('\n--- SCHEME COMPARISON (CPU+Iter+Cond only) ---\n');

    if exist('charger_toutes_donnees_comparaison','file') ~= 2
        fprintf(' Missing function: charger_toutes_donnees_comparaison\n');
        return;
    end

    [donnees, noms_schemas] = charger_toutes_donnees_comparaison();

    if isempty(donnees)
        fprintf(' No scheme data loaded.\n');
        return;
    end

    if exist('figure_cpu_comparaison_complete','file') == 2
        figure_cpu_comparaison_complete(donnees, noms_schemas);
    else
        fprintf(' Missing: figure_cpu_comparaison_complete\n');
    end

    if exist('figure_iterations_comparaison_complete','file') == 2
        figure_iterations_comparaison_complete(donnees, noms_schemas);
    else
        fprintf(' Missing: figure_iterations_comparaison_complete\n');
    end

    if exist('figure_conditionnement_comparaison_complete','file') == 2
        figure_conditionnement_comparaison_complete(donnees, noms_schemas);
    else
        fprintf(' Missing: figure_conditionnement_comparaison_complete\n');
    end

    fprintf(' Comparison display done.\n');
end

function [donnees, noms_schemas] = charger_toutes_donnees_comparaison(base_results_dir)
%CHARGER_TOUTES_DONNEES_COMPARAISON Load comparison data for all numerical schemes

    if nargin < 1 || isempty(base_results_dir)
        thisFileDir = fileparts(mfilename('fullpath'));
        base_results_dir = fullfile(thisFileDir, 'results');
    end

    donnees = {};
    noms_schemas = {};

    validation_dir = fullfile(base_results_dir, 'numerical_validation');
    if exist(validation_dir,'dir') ~= 7
        fprintf(' Missing: %s\n', validation_dir);
        return;
    end

    % L-scheme
    Lroot = fullfile(validation_dir, 'L-scheme');
    if exist(Lroot,'dir') == 7
        Ldirs = dir(fullfile(Lroot,'L=*'));
        Ldirs = Ldirs([Ldirs.isdir]);

        Lvals = nan(numel(Ldirs),1);
        for k = 1:numel(Ldirs)
            tok = regexp(Ldirs(k).name, 'L=([0-9eE\.\-\+]+)', 'tokens', 'once');
            if ~isempty(tok), Lvals(k) = str2double(tok{1}); end
        end
        [~,idx] = sort(Lvals);
        Ldirs = Ldirs(idx);

        for k = 1:numel(Ldirs)
            data_file = fullfile(Lroot, Ldirs(k).name, 'resultats_complets', 'resultats_complets.mat');
            if exist(data_file,'file') == 2
                S = load(data_file);
                donnees{end+1} = S;
                noms_schemas{end+1} = sprintf('L-scheme (%s)', Ldirs(k).name);
                fprintf(' Loaded: %s\n', noms_schemas{end});
            end
        end
    end

    % Newton
    Newton_root = fullfile(validation_dir, 'Newton');
    if exist(Newton_root,'dir') == 7
        lambda_dirs = dir(Newton_root);
        lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
        
        for k = 1:length(lambda_dirs)
            lambda_name = lambda_dirs(k).name;
            tok = regexp(lambda_name, 'lambda_([0-9_]+)', 'tokens', 'once');
            if ~isempty(tok)
                lambda_str = strrep(tok{1}, '_', '.');
                lambda_val = str2double(lambda_str);
                
                dt_path = fullfile(Newton_root, lambda_name);
                dt_dirs = dir(dt_path);
                dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
                
                for d = 1:length(dt_dirs)
                    data_file = fullfile(dt_path, dt_dirs(d).name, 'resultats_complets', 'resultats_complets.mat');
                    if exist(data_file,'file') == 2
                        S = load(data_file);
                        donnees{end+1} = S;
                        noms_schemas{end+1} = sprintf('Newton (\x03BB=%.4f)', lambda_val);
                        fprintf(' Loaded: Newton \x03BB=%.4f\n', lambda_val);
                        break;
                    end
                end
            end
        end
    end

    % Picard
    pic_file = fullfile(validation_dir, 'Picard', 'resultats_complets', 'resultats_complets.mat');
    if exist(pic_file,'file') == 2
        donnees{end+1} = load(pic_file);
        noms_schemas{end+1} = 'Picard';
        fprintf(' Loaded: Picard\n');
    end
end

%% ==================== CORE VISUALIZATION FUNCTIONS ====================

function show_isosurface_from_file(sol_dir, nx, t)
%SHOW_ISOSURFACE_FROM_FILE Display 3D isosurface from saved solution data

    [P, ~, U, tm] = charger_donnees_temps(sol_dir, nx, t);
    if isempty(P), return; end
    if isempty(tm), tm = t; end

    mx = max(17, min(129, nx+1));
    [X,Y,Z] = meshgrid(linspace(0,1,mx), linspace(0,1,mx), linspace(0,1,mx));

    try
        Fint = scatteredInterpolant(P(:,1),P(:,2),P(:,3),U,'natural','none');
        Ugrid = Fint(X,Y,Z);
    catch
        Ugrid = griddata(P(:,1),P(:,2),P(:,3),U,X,Y,Z,'linear');
    end

    umin = min(Ugrid(:)); umax = max(Ugrid(:));
    if ~isfinite(umin) || ~isfinite(umax) || umax <= umin
        fprintf('Iso: invalid Ugrid range.\n');
        return;
    end

    iso_value = umin + 0.475*(umax-umin);
    [F,V] = isosurface(X,Y,Z,Ugrid,iso_value);
    if isempty(V)
        fprintf('Iso: no surface.\n');
        return;
    end

    Cvert = V(:,3);
    patch('Faces',F,'Vertices',V, ...
        'FaceVertexCData',Cvert, ...
        'FaceColor','interp', ...
        'EdgeColor','k', ...
        'LineWidth',0.35, ...
        'FaceAlpha',1.0);

    axis equal tight;
    axis on; box off; grid off;
    xlim([0 1]); ylim([0 1]); zlim([0 1]);
    view(60,20);
    camlight headlight; lighting gouraud;

    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';

    xlabel('x','FontSize',24,'FontWeight','bold');
    ylabel('y','FontSize',24,'FontWeight','bold');
    zlabel('z','FontSize',24,'FontWeight','bold');

    title(sprintf('Isosurface (t=%.3f)', tm), 'FontWeight','bold');

    colormap(jet);
    cb = colorbar;
    cb.FontSize = 18;
end

function show_cut_from_file(sol_dir, nx, t, cut_mode, cut_val)
%SHOW_CUT_FROM_FILE Display 2D cross-sectional cut from saved solution data

    [p, ~, u, tm] = charger_donnees_temps(sol_dir, nx, t);
    if isempty(p), return; end
    if isempty(tm), tm = t; end

    [Xg,Yg,Zg] = meshgrid(linspace(0,1,nx), linspace(0,1,nx), linspace(0,1,nx));
    Ug = griddata(p(:,1),p(:,2),p(:,3),u,Xg,Yg,Zg,'linear');
    if all(isnan(Ug(:)))
        fprintf('Cut: only NaN.\n');
        return;
    end

    cut_val = max(0.01, min(0.99, cut_val));
    set(gcf,'Renderer','opengl');

    switch cut_mode
        case 1
            [~,iz] = min(abs(Zg(1,1,:) - cut_val));
            Xc = squeeze(Xg(:,:,iz)); Yc = squeeze(Yg(:,:,iz)); Uc = squeeze(Ug(:,:,iz));
            contourf(Xc,Yc,Uc,20,'LineStyle','none');
            xlabel('x','FontSize',24,'FontWeight','bold');
            ylabel('y','FontSize',24,'FontWeight','bold');
            ttl = sprintf('Cut z=%.2f', cut_val);
        case 2
            [~,ix] = min(abs(Xg(1,:,1) - cut_val));
            Yc = squeeze(Yg(:,ix,:)); Zc = squeeze(Zg(:,ix,:)); Uc = squeeze(Ug(:,ix,:));
            contourf(Yc,Zc,Uc,20,'LineStyle','none');
            xlabel('y','FontSize',24,'FontWeight','bold');
            ylabel('z','FontSize',24,'FontWeight','bold');
            ttl = sprintf('Cut x=%.2f', cut_val);
        case 3
            [~,iy] = min(abs(Yg(:,1,1) - cut_val));
            Xc = squeeze(Xg(iy,:,:)); Zc = squeeze(Zg(iy,:,:)); Uc = squeeze(Ug(iy,:,:));
            contourf(Xc,Zc,Uc,20,'LineStyle','none');
            xlabel('x','FontSize',24,'FontWeight','bold');
            ylabel('z','FontSize',24,'FontWeight','bold');
            ttl = sprintf('Cut y=%.2f', cut_val);
    end

    ax = gca;
    ax.FontSize = 22;
    ax.LineWidth = 1.5;
    ax.FontWeight = 'bold';
    axis equal tight;
    axis on; box off; grid off;

    colormap(jet);
    cb = colorbar;
    cb.FontSize = 18;
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    title(sprintf('%s (t=%.3f)', ttl, tm), 'FontSize', 26, 'FontWeight','bold');

    umin = min(Uc(:)); umax = max(Uc(:));
    fprintf('Coupe t=%.3f : min(Uc)=%.3e, max(Uc)=%.3e\n', tm, umin, umax);
end

function [p, tmesh, u, tm, file_path] = charger_donnees_temps(output_folder, nx, temps)
%CHARGER_DONNEES_TEMPS Robust time-dependent solution loader

    p = []; tmesh = []; u = []; tm = []; file_path = '';

    if nargin < 2, nx = []; end
    if nargin < 3, temps = []; end

    if exist(output_folder,'dir') ~= 7
        fprintf(' Directory does not exist: %s\n', output_folder);
        return;
    end

    files = dir(fullfile(output_folder, 'solution_nx*_t*s.mat'));
    if isempty(files)
        fprintf(' No solution_nx*_t*s.mat files in: %s\n', output_folder);
        return;
    end

    NX = nan(numel(files),1);
    TT = nan(numel(files),1);

    for i = 1:numel(files)
        name = files(i).name;
        tokNx = regexp(name, 'solution_nx(\d+)_', 'tokens', 'once');
        tokT = regexp(name, '_t([^s]+)s\.mat$', 'tokens', 'once');

        if ~isempty(tokNx), NX(i) = str2double(tokNx{1}); end
        if ~isempty(tokT), TT(i) = str2double(tokT{1}); end
    end

    ok = isfinite(NX) & isfinite(TT);
    NX = NX(ok); TT = TT(ok); files = files(ok);

    if isempty(files)
        fprintf(' Unable to parse nx/t from filenames in: %s\n', output_folder);
        return;
    end

    if isempty(nx)
        nx = max(NX);
    end

    idxNx = find(NX == nx);
    if isempty(idxNx)
        fprintf(' No files for nx=%d in: %s\n', nx, output_folder);
        return;
    end

    TTnx = TT(idxNx);

    if isempty(temps)
        [~,k] = max(TTnx);
        pick = idxNx(k);
    else
        [~,k] = min(abs(TTnx - temps));
        pick = idxNx(k);
    end

    file_path = fullfile(output_folder, files(pick).name);

    if exist(file_path,'file') ~= 2
        fprintf(' File not found: %s\n', file_path);
        return;
    end

    data = load(file_path);

    if isfield(data, 'u')
        u = data.u;
    elseif isfield(data, 'u0')
        u = data.u0;
    else
        fprintf(' Solution variable missing in: %s\n', file_path);
        return;
    end

    if isfield(data,'p'), p = data.p; else, fprintf(' p missing\n'); return; end
    if isfield(data,'t'), tmesh = data.t; else, fprintf(' t missing\n'); return; end

    if isfield(data,'tm')
        tm = data.tm;
    else
        tm = TT(pick);
    end

    fprintf(' Loaded: nx=%d | t=%.6g | %s\n', nx, tm, files(pick).name);
end

%% ==================== COMPARISON FIGURES (WRAPPER) ====================
% These functions call the original figure functions from your code
% They are kept as-is from your original implementation

function figure_cpu_comparaison_complete(donnees, noms_schemas)
%FIGURE_CPU_COMPARAISON_COMPLETE - Calls the original implementation
% The full implementation is in your original code, kept here as wrapper
    
    % Call the original function - make sure it's in your path
    if exist('figure_cpu_comparaison_complete_impl', 'file')
        figure_cpu_comparaison_complete_impl(donnees, noms_schemas);
    else
        % Simple fallback plot
        figure('Position', [100, 100, 1000, 800], 'Name', 'Computation Time');
        hold on;
        colors = lines(length(donnees));
        for i = 1:length(donnees)
            if isfield(donnees{i}, 'h_values') && isfield(donnees{i}, 'CPU_times')
                x = 1 ./ donnees{i}.h_values;
                y = donnees{i}.CPU_times;
                loglog(x, y, '-o', 'Color', colors(i,:), 'LineWidth', 2, 'MarkerSize', 8);
            end
        end
        xlabel('1/h', 'FontSize', 14);
        ylabel('CPU Time (s)', 'FontSize', 14);
        legend(noms_schemas, 'Location', 'best', 'FontSize', 12);
        grid on;
        hold off;
        fprintf(' CPU comparison figure (fallback).\n');
    end
end

function figure_iterations_comparaison_complete(donnees, noms_schemas)
%FIGURE_ITERATIONS_COMPARAISON_COMPLETE - Calls the original implementation
    
    if exist('figure_iterations_comparaison_complete_impl', 'file')
        figure_iterations_comparaison_complete_impl(donnees, noms_schemas);
    else
        figure('Position', [100, 100, 1000, 800], 'Name', 'Number of iterations');
        hold on;
        colors = lines(length(donnees));
        for i = 1:length(donnees)
            if isfield(donnees{i}, 'h_values')
                x = 1 ./ donnees{i}.h_values;
                if isfield(donnees{i}, 'Picard_iters_moyenne')
                    y = donnees{i}.Picard_iters_moyenne;
                elseif isfield(donnees{i}, 'Newton_iters_moyenne')
                    y = donnees{i}.Newton_iters_moyenne;
                else
                    continue;
                end
                plot(x, y, '-o', 'Color', colors(i,:), 'LineWidth', 2, 'MarkerSize', 8);
            end
        end
        xlabel('1/h', 'FontSize', 14);
        ylabel('Iterations', 'FontSize', 14);
        legend(noms_schemas, 'Location', 'best', 'FontSize', 12);
        grid on;
        hold off;
        fprintf(' Iterations comparison figure (fallback).\n');
    end
end

function figure_conditionnement_comparaison_complete(donnees, noms_schemas)
%FIGURE_CONDITIONNEMENT_COMPARAISON_COMPLETE - Calls the original implementation
    
    if exist('figure_conditionnement_comparaison_complete_impl', 'file')
        figure_conditionnement_comparaison_complete_impl(donnees, noms_schemas);
    else
        figure('Position', [400, 100, 1000, 800], 'Name', 'Condition Numbers');
        hold on;
        colors = lines(length(donnees));
        for i = 1:length(donnees)
            if isfield(donnees{i}, 'h_values') && isfield(donnees{i}, 'Cond_max')
                x = 1 ./ donnees{i}.h_values;
                y = donnees{i}.Cond_max;
                loglog(x, y, '-o', 'Color', colors(i,:), 'LineWidth', 2, 'MarkerSize', 8);
            end
        end
        xlabel('1/h', 'FontSize', 14);
        ylabel('Condition Number', 'FontSize', 14);
        legend(noms_schemas, 'Location', 'best', 'FontSize', 12);
        grid on;
        hold off;
        fprintf(' Conditioning comparison figure (fallback).\n');
    end
end