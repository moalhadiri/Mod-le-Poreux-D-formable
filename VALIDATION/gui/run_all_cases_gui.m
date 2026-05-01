function run_all_cases_gui()
%RUN_ALL_CASES_GUI Richards 3D-Professional Launcher Interface (uifigure)
%   This function creates the main graphical user interface for configuring
%   and launching Richards 3D simulations using the NEWTON nonlinear solver.
%
%   KEY FEATURES:
%      -Auto-jump from vector fields after first number (Space or Enter)
%      -Hide/Show Physical/Validation panels with automatic layout collapse
%      -Real-time input validation with visual feedback 
%      -Visual chips displaying parsed vector values
%      -Interactive run log and results summary tabs
%      -Direct integration with main.m execution engine
%      -Live progress monitor with animated progress bar
%      -Integrated visualization with scrollable figure panels
%      -Dedicated tabs for CPU, iteration, conditioning, and cross-section plots
%
%   INTERFACE STRUCTURE:
%       Left panel (3 sections):
%           - Case type selection (Physical/Validation)
%           - Physical case parameters (collapsible)
%           - Validation case parameters (collapsible)
%       Right panel:
%           - Header with run button and status
%           - Tab group with 5 tabs:
%               * Run log: Real-time execution output
%               * Results summary: Text summary of last run
%               * visualization 1: CPU time and iteration plots
%               * visualization 2: Conditioning number plots
%               * visualization 3: Physical case cross-sections
%               * visualization 4: Convergence table
%       Bottom monitor:
%           - Live progress bar
%           - Real-time status messages
%
%   INPUT VALIDATION:
%       - Numeric vectors: parsed with auto-jump after first value
%       - Range checking: L values between 0 and 1, time steps positive
%       - Visual feedback: green checkmark for valid, red cross for invalid
%       - Chip display: shows parsed vector values as interactive chips
%
%   DEPENDENCIES:
%       - main.m in project root directory
%       - Proper directory structure with src/, FEM/, models/, solvers/
%       - Visualization functions for plots and cross-sections
%
%   See also: MAIN, BATCH_VIEW_RULES_BAT, PHYSICAL_CASE_T10_ONLY

    close all;
% ===================== PARAMETRES GENERAUX =====================
% These values will be overridden based on case type
test_id = 1;
test_cond = 1;
eps1 = 1e-8;
save_interval = 0.2;
    % Locate main.m in the parent directory (project root)
    baseDir = fileparts(mfilename('fullpath'));     % gui/
    rootDir = fileparts(baseDir);                   % parent directory (root)
    mainScript = fullfile(rootDir,'main.m');       % main.m at root

    if exist(mainScript,'file') ~= 2
        uialert(uifigure,...
            sprintf('main.m not found at:\n%s\nPlease check project structure.',mainScript),...
            'Missing file');
        return;
    end

    % ========================= THEME =========================
    bg      = [1 1 1];
    fg      = [0.10 0.10 0.10];
    sub     = [0.35 0.35 0.35];
    accent  = [0.00 0.45 0.74];
    success = [0.16 0.58 0.18];
    errorC  = [0.78 0.20 0.20];
    lineCol = [0.88 0.88 0.88];
    chipBg  = [0.965 0.965 0.965];
    monitorBg = [0.97 0.97 0.98];
    progressBarBg = [0.88 0.88 0.90];
    progressBarFill = [0.35 0.35 0.38];

    % ========================= WINDOW =========================
    fig = uifigure( ...
        'Name','Launcher: Richards 3D - Newton Solver',...
        'Color',bg,...
        'Position',[200 80 1200 860],...
        'Resize','on');
    try,fig.FontName = 'Segoe UI'; catch,end

    % --- key handler for vector auto-jump
    fig.WindowKeyPressFcn = @onWindowKeyPress;

    % Main layout-now 2 rows (top content + bottom monitor)
    root = uigridlayout(fig,[2 1]);
    root.RowHeight     = {'1x',240};
    root.Padding       = [20 20 20 20];
    root.RowSpacing    = 15;

    % ========================= TOP CONTENT =========================
    topContent = uigridlayout(root,[1 2]);
    topContent.Layout.Row = 1;
    topContent.ColumnWidth     = {450,'1x'};
    topContent.Padding         = [0 0 0 0];
    topContent.ColumnSpacing   = 20;

    % ========================= LEFT =========================
    left = uigridlayout(topContent,[3 1]);
    left.Layout.Row = 1;
    left.Layout.Column = 1;

    % (we will dynamically update these heights when toggling)
    H_cases = 120;
    H_phys  = 270;
    H_val   = 370;

    left.RowHeight       = {H_cases,H_phys,'1x'};
    left.Padding         = [0 0 0 0];
    left.RowSpacing      = 12;

    % ========================= RIGHT =========================
    right = uigridlayout(topContent,[3 1]);
    right.RowHeight      = {165,'1x',72};
    right.Padding        = [0 0 0 0];
    right.RowSpacing     = 12;

    % ===================== RIGHT: TABS =========================
    tabs = uitabgroup(right);
    tabs.Layout.Row = 2;

    tabLog = uitab(tabs,'Title','Run log');
    tabSum = uitab(tabs,'Title','Results summary');
    tabVis1 = uitab(tabs,'Title','visualization 1');
    tabVis2 = uitab(tabs,'Title','visualization 2');
    tabVis3 = uitab(tabs,'Title','visualization 3');
    tabVis4 = uitab(tabs,'Title','visualization 4');

    % ========================= HEADER =========================
    header = makePanel(right,1,'Run configuration',fg,bg,lineCol);
    headerGrid = uigridlayout(header,[4 1]);
    headerGrid.RowHeight = {48,22,22,'1x'};
    headerGrid.Padding   = [16 12 16 10];

    uilabel(headerGrid,...
        'Text',sprintf('Coupled Richards Equation in Deformable Porous Media - NEWTON SOLVER'),...
        'FontSize',18,...
        'FontWeight','bold',...
        'FontColor',fg);

    uilabel(headerGrid,'Text','',...
        'FontSize',11,'FontColor',sub);
    uilabel(headerGrid,'Text','Set simulation parameters (physical time in hours), then click RUN.',...
        'FontSize',11,'FontColor',fg);
    uilabel(headerGrid,'Text',sprintf('main.m: %s',mainScript),...
        'FontSize',9,'FontColor',sub,'FontAngle','italic');

    % ===================== CASES =====================
    pCases = makePanel(left,1,'Cases',fg,bg,lineCol);

    gCases = uigridlayout(pCases,[1 2]);
    gCases.Padding        = [16 12 16 12];
    gCases.RowHeight      = {28};
    gCases.ColumnWidth    = {'1x','1x'};
    gCases.ColumnSpacing  = 18;

    cbPhysical = uicheckbox(gCases,'Text','Reference physical simulation (Newton)','Value',true,...
        'FontSize',12,'FontColor',fg,...
        'ValueChangedFcn',@refreshEnable,...
        'Tooltip','Run Reference physical simulation (single Nx).');
    cbPhysical.Layout.Row = 1; cbPhysical.Layout.Column = 1;

    cbValidation = uicheckbox(gCases,'Text','Numerical validation (Newton)','Value',true,...
        'FontSize',12,'FontColor',fg,...
        'ValueChangedFcn',@refreshEnable,...
        'Tooltip','Run validation (Nx_list + lambda).');
    cbValidation.Layout.Row = 1; cbValidation.Layout.Column = 2;

    % ===================== PHYSICAL CASE PANEL =====================
    pPhys = makePanel(left,2,'Reference physical simulation',fg,bg,lineCol);

    gPhys = uigridlayout(pPhys,[7 2]);
    gPhys.Padding       = [16 12 16 12];
    gPhys.ColumnWidth   = {190,170};
    gPhys.RowHeight     = {24,30,22,26,22,26,34};
    gPhys.RowSpacing    = 8;
    gPhys.ColumnSpacing = 10;

    % Mode
    uilabel(gPhys,'Text','Vertisol mode','FontColor',fg,'FontSize',12,'FontWeight','bold');
    ddMode = uidropdown(gPhys,...
        'Items',{'deformable','non_deformable'},...
        'Value','deformable',...
        'FontSize',12,...
        'Tooltip','deformable: coupled hydromechanical | non_deformable: flow only');

    % Mesh Nx
    uilabel(gPhys,'Text','Spatial discretization level','FontColor',fg,'FontSize',12,'FontWeight','bold');

    nxPhysContainer = uigridlayout(gPhys,[1 2]);
    nxPhysContainer.ColumnWidth     = {50,24};
    nxPhysContainer.Padding         = [0 0 0 0];
    nxPhysContainer.ColumnSpacing   = 6;

    edNxPhys = uieditfield(nxPhysContainer,'text','Value','17','FontSize',12,...
        'FontName','Consolas',...
        'Tooltip','Integer Nx >= 3');
    edNxPhys.ValueChangedFcn = @validateAll;

    nxPhysValid = uilabel(nxPhysContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    % h label
    hLabel = uilabel(gPhys,'Text','h = 1/(Nx-1)',...
        'FontColor',sub,'FontSize',12,'FontAngle','italic');
    hLabel.Layout.Row = 3; hLabel.Layout.Column = [1 2];

    % dt0 phys
    uilabel(gPhys,'Text','Time step (physical) (dt) [h]','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edDt0Phys = uieditfield(gPhys,'numeric',...
        'Value',0.25,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Initial time step for the physical case (hours).');

    % T_final phys
    uilabel(gPhys,'Text','Final time T (physical) [h]','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edTfPhys = uieditfield(gPhys,'numeric',...
        'Value',8,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Final simulation time for the physical case (hours).');

    % Lambda scalar phys (NEWTON parameter)
    uilabel(gPhys,'Text','λ (Newton damping parameter)','FontColor',fg,'FontSize',12,'FontWeight','bold');

    lambdaScalarContainer = uigridlayout(gPhys,[1 2]);
    lambdaScalarContainer.ColumnWidth     = {'1x',24};
    lambdaScalarContainer.Padding         = [0 0 0 0];
    lambdaScalarContainer.ColumnSpacing   = 6;

    edLambdaScalar = uieditfield(lambdaScalarContainer,'numeric',...
        'Value',0.5,'LowerLimit',0,'UpperLimit',1,'FontSize',12,...
        'Tooltip','Newton damping parameter (0 < λ ≤ 1)');
    edLambdaScalar.ValueChangedFcn = @validateAll;

    lambdaScalarValid = uilabel(lambdaScalarContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    % --- Physical chips ---
    physPreviewHost = uipanel(gPhys,'BackgroundColor',bg,'BorderType','none');
    physPreviewHost.Layout.Row = 7;
    physPreviewHost.Layout.Column = [1 2];

    physPreviewGrid = uigridlayout(physPreviewHost,[1 4]);
    physPreviewGrid.Padding       = [0 0 0 0];
    physPreviewGrid.ColumnSpacing = 8;
    physPreviewGrid.RowHeight     = 30;

    % ===================== NUMERICAL VALIDATION PANEL =====================
    pVal = makePanel(left,3,'Numerical validation',fg,bg,lineCol);

    gVal = uigridlayout(pVal,[8 2]);
    gVal.Padding       = [16 12 16 12];
    gVal.ColumnWidth   = {190,'1x'};
    gVal.RowHeight     = {24,30,34,24,30,24,30,34};
    gVal.RowSpacing    = 8;
    gVal.ColumnSpacing = 10;

    % Nx_list
    uilabel(gVal,'Text','Spatial discretization levels (Nx)','FontColor',fg,'FontSize',12,'FontWeight','bold');

    nxMainContainer = uigridlayout(gVal,[1 2]);
    nxMainContainer.ColumnWidth     = {100,'fit'};
    nxMainContainer.Padding         = [0 0 0 0];
    nxMainContainer.ColumnSpacing   = 10;

    nxEditContainer = uigridlayout(nxMainContainer,[1 2]);
    nxEditContainer.ColumnWidth     = {'1x',24};
    nxEditContainer.Padding         = [0 0 0 0];
    nxEditContainer.ColumnSpacing   = 6;

    edNxListVal = uieditfield(nxEditContainer,'text','Value','5 9 17',...
        'FontSize',12,'FontName','Consolas',...
        'Tooltip','Space-separated integers, e.g. 5 9 17 33');
    edNxListVal.ValueChangedFcn = @validateAll;

    nxListValid = uilabel(nxEditContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    nxHintLabel = uilabel(nxMainContainer,'Text','Nx(coarse → fine)',...
        'FontSize',10,...
        'FontColor',sub,...
        'FontAngle','italic',...
        'HorizontalAlignment','left');

    % Nx chips
    nxPreviewHost = uipanel(gVal,'BackgroundColor',bg,'BorderType','none');
    nxPreviewHost.Layout.Row = 3;
    nxPreviewHost.Layout.Column = [1 2];
    nxPreviewGrid = uigridlayout(nxPreviewHost,[1 1]);
    nxPreviewGrid.Padding = [0 0 0 0];

    % dt0 validation
    uilabel(gVal,'Text','Time step (validation) (dt)','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edDt0 = uieditfield(gVal,'numeric','Value',0.025,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Initial time step for numerical validation (hours).');

    % t_final validation
    uilabel(gVal,'Text','Final time T (validation)','FontColor',fg,'FontSize',12,'FontWeight','bold');
    edTf  = uieditfield(gVal,'numeric','Value',0.5,'LowerLimit',eps,'FontSize',12,...
        'Tooltip','Final time for numerical validation (hours).');

    % Lambda vector validation (NEWTON parameter)
    uilabel(gVal,'Text','λ values [vector] (validation)','FontColor',fg,'FontSize',12,'FontWeight','bold');

    lambdaVecContainer = uigridlayout(gVal,[1 2]);
    lambdaVecContainer.ColumnWidth     = {'1x',24};
    lambdaVecContainer.Padding         = [0 0 0 0];
    lambdaVecContainer.ColumnSpacing   = 6;

    edLambdaVec = uieditfield(lambdaVecContainer,'text','Value','0.5 0.75 1.0',...
        'FontSize',12,'FontName','Consolas',...
        'Tooltip','Space-separated numbers, e.g. 0.5 0.75 1.0');
    edLambdaVec.ValueChangedFcn = @validateAll;

    lambdaVecValid = uilabel(lambdaVecContainer,'Text','',...
        'FontSize',15,'FontColor',success,...
        'HorizontalAlignment','center');

    % Lambda chips
    lambdaPreviewHost = uipanel(gVal,'BackgroundColor',bg,'BorderType','none');
    lambdaPreviewHost.Layout.Row = 7;
    lambdaPreviewHost.Layout.Column = [1 2];
    lambdaPreviewGrid = uigridlayout(lambdaPreviewHost,[1 1]);
    lambdaPreviewGrid.Padding = [0 0 0 0];

    % ===================== RUN LOG TAB =========================
    glog = uigridlayout(tabLog,[1 1]);
    glog.Padding = [12 12 12 12];
    logArea = uitextarea(glog,'Editable','off','FontName','Consolas','FontSize',11,...
        'Value',{ ...
            '" This launcher injects variables in the BASE workspace, then runs main.m (NEWTON).'; ...
            '" After RUN, click VIEW RESULTS.' ...
        });

    % ===================== RESULTS SUMMARY TAB =========================
    gsum = uigridlayout(tabSum,[2 1]);
    gsum.RowHeight = {22,'1x'};
    gsum.Padding = [12 12 12 12];

    uilabel(gsum,'Text','Simulation summary (updated after RUN)',...
        'FontColor',sub,'FontSize',11,'FontAngle','italic');

    sumArea = uitextarea(gsum,'Editable','off','FontName','Consolas','FontSize',11,...
        'Value',{' '});

    % ===================== VISUALIZATION TAB 1 (CPU + Iterations) =========================
    visTab1 = tabVis1;
    
    visMainGrid1 = uigridlayout(visTab1, [2, 1]);
    visMainGrid1.RowHeight = {'1x', 60};
    visMainGrid1.Padding = [10 10 10 10];
    visMainGrid1.RowSpacing = 10;
    
    visPlotPanel1 = uipanel(visMainGrid1, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Performance Metrics - Newton', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');
    
    visGrid1 = uigridlayout(visPlotPanel1, [1, 2]);
    visGrid1.RowHeight = {280};
    visGrid1.ColumnWidth = {'1x', '1x'};
    visGrid1.Padding = [10 10 10 10];
    visGrid1.RowSpacing = 15;
    visGrid1.ColumnSpacing = 15;
    
    cpuPanel = uipanel(visGrid1, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'CPU Time Comparison', ...
        'FontSize', 11, 'FontWeight', 'bold');
    cpuAxes = axes('Parent', cpuPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);
    title(cpuAxes, 'CPU Time - Newton', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(cpuAxes, '1/h', 'FontSize', 10);
    ylabel(cpuAxes, 'Time (s)', 'FontSize', 10);
    set(cpuAxes, 'YScale', 'log', 'FontSize', 9, 'Box', 'on');
    
    iterPanel = uipanel(visGrid1, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Iterations Comparison', ...
        'FontSize', 11, 'FontWeight', 'bold');
    iterAxes = axes('Parent', iterPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);
    title(iterAxes, 'Newton Iterations', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(iterAxes, '1/h', 'FontSize', 10);
    ylabel(iterAxes, 'Iterations', 'FontSize', 10);
    set(iterAxes, 'FontSize', 9, 'Box', 'on');
    
    visControlPanel1 = uipanel(visMainGrid1, 'BackgroundColor', [0.95 0.98 1.00], ...
        'BorderType', 'line', 'Title', 'Controls - Performance Metrics', ...
        'FontSize', 12, 'FontWeight', 'bold');
    
    controlGrid1 = uigridlayout(visControlPanel1, [1, 5]);
    controlGrid1.ColumnWidth = {'1x', 150, 150, 150, '1x'};
    controlGrid1.Padding = [10 5 10 5];
    
    uilabel(controlGrid1, 'Text', '');
    
    btnLoadVis1 = uibutton(controlGrid1, 'push', ...
        'Text', 'Load Data', ...
        'BackgroundColor', accent, ...
        'FontColor', [1 1 1], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) loadVisualisationData());
    
    btnRefreshVis1 = uibutton(controlGrid1, 'push', ...
        'Text', 'Refresh', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) refreshVisualisation());
    
    btnExportVis1 = uibutton(controlGrid1, 'push', ...
        'Text', 'Export', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) exportVisualisation());
    
    uilabel(controlGrid1, 'Text', '');

    % ===================== VISUALIZATION TAB 2 (Conditioning) =========================
    visTab2 = tabVis2;

    visMainGrid2 = uigridlayout(visTab2, [2, 1]);
    visMainGrid2.RowHeight = {'1x', 60};
    visMainGrid2.Padding = [10 10 10 10];
    visMainGrid2.RowSpacing = 10;

    visPlotPanel2 = uipanel(visMainGrid2, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Conditioning Analysis - Newton', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');

    visGrid2 = uigridlayout(visPlotPanel2, [1, 1]);
    visGrid2.Padding = [10 10 10 10];

    condPanel = uipanel(visGrid2, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Condition Number', ...
        'FontSize', 11, 'FontWeight', 'bold');

    condAxes = axes('Parent', condPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);  
    title(condAxes, 'Condition Number - Newton', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(condAxes, '1/h', 'FontSize', 10);
    ylabel(condAxes, 'Condition', 'FontSize', 10);
    set(condAxes, 'YScale', 'log', 'FontSize', 9, 'Box', 'on');

    visControlPanel2 = uipanel(visMainGrid2, 'BackgroundColor', [0.95 0.98 1.00], ...
        'BorderType', 'line', 'Title', 'Controls - Conditioning', ...
        'FontSize', 12, 'FontWeight', 'bold');

    controlGrid2 = uigridlayout(visControlPanel2, [1, 5]); 
    controlGrid2.ColumnWidth = {'1x', 150, 150, 150, '1x'};
    controlGrid2.Padding = [10 5 10 5];

    uilabel(controlGrid2, 'Text', '');

    btnLoadVis2 = uibutton(controlGrid2, 'push', ...
        'Text', 'Load Data', ...
        'BackgroundColor', accent, ...
        'FontColor', [1 1 1], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) loadVisualisationData());

    btnRefreshVis2 = uibutton(controlGrid2, 'push', ...
        'Text', 'Refresh', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) refreshVisualisation());

    btnExportVis2 = uibutton(controlGrid2, 'push', ...
        'Text', 'Export', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 12, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) exportVisualisation());

    uilabel(controlGrid2, 'Text', '');
    
    % ===================== VISUALIZATION TAB 3 (Cross-section + Isosurface) =========================
    visTab3 = tabVis3;

    visMainGrid3 = uigridlayout(visTab3, [2, 1]);
    visMainGrid3.RowHeight = {'1x', 80};
    visMainGrid3.Padding = [10 10 10 10];
    visMainGrid3.RowSpacing = 10;

    visPlotPanel3 = uipanel(visMainGrid3, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Physical Case Visualizations - Newton', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');

    visGrid3 = uigridlayout(visPlotPanel3, [1, 2]);
    visGrid3.RowHeight = {280};
    visGrid3.ColumnWidth = {'1x', '1x'};
    visGrid3.Padding = [10 10 10 10];
    visGrid3.RowSpacing = 15;
    visGrid3.ColumnSpacing = 15;

    sectionPanel = uipanel(visGrid3, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Cross-section', ...
        'FontSize', 11, 'FontWeight', 'bold');

    sectionAxes = axes('Parent', sectionPanel, 'Units', 'normalized', ...
        'Position', [0.12 0.17 0.75 0.6]);
    title(sectionAxes, '', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(sectionAxes, 'y', 'FontSize', 10);
    ylabel(sectionAxes, 'z', 'FontSize', 10);
    set(sectionAxes, 'FontSize', 9, 'Box', 'on');

    isoPanel = uipanel(visGrid3, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Isosurface', ...
        'FontSize', 11, 'FontWeight', 'bold');

    isoAxes = axes('Parent', isoPanel, 'Units', 'normalized', ...
        'Position', [0.15 0.2 0.75 0.7]);
    title(isoAxes, '', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel(isoAxes, 'x', 'FontSize', 10);
    ylabel(isoAxes, 'y', 'FontSize', 10);
    zlabel(isoAxes, 'z', 'FontSize', 10);
    set(isoAxes, 'FontSize', 9, 'Box', 'on');
    view(isoAxes, 45, 30);

    visControlPanel3 = uipanel(visMainGrid3, 'BackgroundColor', [0.95 0.98 1.00], ...
        'BorderType', 'line', 'Title', 'Controls - Physical Case', ...
        'FontSize', 12, 'FontWeight', 'bold');

    controlGrid3 = uigridlayout(visControlPanel3, [1, 9]);
    controlGrid3.ColumnWidth = {'1x', 140, 100, 80, 100, 80, 100, 80, '1x'};
    controlGrid3.Padding = [10 5 10 5];

    uilabel(controlGrid3, 'Text', '');

    btnLoadVis3 = uibutton(controlGrid3, 'push', ...
        'Text', 'Load Physical Data', ...
        'BackgroundColor', accent, ...
        'FontColor', [1 1 1], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) loadPhysicalCrossSectionData());

    uilabel(controlGrid3, 'Text', 'Time (h):', 'FontSize', 11, 'FontWeight', 'bold');
    popupTime = uidropdown(controlGrid3, ...
        'Items', {'Select time...'}, ...
        'Value', 'Select time...', ...
        'FontSize', 11);

    uilabel(controlGrid3, 'Text', 'Plane:', 'FontSize', 11, 'FontWeight', 'bold');
    popupPlane = uidropdown(controlGrid3, ...
        'Items', {'x = constant', 'y = constant', 'z = constant'}, ...
        'Value', 'x = constant', ...
        'FontSize', 11);

    uilabel(controlGrid3, 'Text', 'Value:', 'FontSize', 11, 'FontWeight', 'bold');
    editValue = uieditfield(controlGrid3, 'numeric', ...
        'Value', 0.5, 'Limits', [0 1], ...
        'FontSize', 11, 'HorizontalAlignment', 'center');

    uilabel(controlGrid3, 'Text', 'Iso:', 'FontSize', 11, 'FontWeight', 'bold');
    editIsoValue = uieditfield(controlGrid3, 'numeric', ...
        'Value', 0.5, 'Limits', [0 1], ...
        'FontSize', 11, 'HorizontalAlignment', 'center');

    btnUpdateVis3 = uibutton(controlGrid3, 'push', ...
        'Text', 'Update', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) updatePhysicalVisualizations());

    uilabel(controlGrid3, 'Text', '');

    % ===================== VISUALIZATION TAB 4 (Convergence Table) =========================
    visTab4 = tabVis4;

    visMainGrid4 = uigridlayout(visTab4, [2, 1]);
    visMainGrid4.RowHeight = {'1x', 60};
    visMainGrid4.Padding = [10 10 10 10];
    visMainGrid4.RowSpacing = 10;

    visPlotPanel4 = uipanel(visMainGrid4, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Convergence Analysis - Newton', ...
        'FontSize', 12, 'FontWeight', 'bold', 'Scrollable', 'on');

    visGrid4 = uigridlayout(visPlotPanel4, [1, 1]);
    visGrid4.RowHeight = {400};
    visGrid4.Padding = [10 10 10 10];

    tablePanel = uipanel(visGrid4, 'BackgroundColor', [1 1 1], ...
        'BorderType', 'line', 'Title', 'Error Analysis', ...
        'FontSize', 11, 'FontWeight', 'bold');

    convTable = uitable(tablePanel, 'Units', 'normalized', ...
        'Position', [0.02 0.08 0.96 0.85], ...
        'ColumnName', {'h', 'L2 Error', 'H1 Error', 'κ_{max}', 'CPU (s)', 'Iter', 'Order'}, ...
        'ColumnWidth', {70, 85, 85, 70, 70, 50, 60}, ...
        'FontSize', 11, ...
        'FontWeight', 'bold');

    visControlPanel4 = uipanel(visMainGrid4, 'BackgroundColor', [0.95 0.98 0.7], ...
        'BorderType', 'line', 'Title', 'Controls - Convergence Table', ...
        'FontSize', 12, 'FontWeight', 'bold');
    visMainGrid4.RowHeight = {280, 80}; 

    controlGrid4 = uigridlayout(visControlPanel4, [1, 5]);
    controlGrid4.ColumnWidth = {'1x', 200, 25, 125, '1x'};
    controlGrid4.Padding = [10 10 10 10];
    controlGrid4.RowHeight = {30};
    uilabel(controlGrid4, 'Text', '');

    btnLoadVis4 = uibutton(controlGrid4, 'push', ...
        'Text', 'Load Data', ...
        'BackgroundColor', accent, ...
        'FontColor', [1 1 1], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) loadValidationData());

    uilabel(controlGrid4, 'Text', 'λ:', 'FontSize', 11, 'FontWeight', 'bold');
    popupLambdaVal = uidropdown(controlGrid4, ...
        'Items', {'Select...'}, ...
        'Value', 'Select...', ...
        'FontSize', 11);

    btnRefreshVis4 = uibutton(controlGrid4, 'push', ...
        'Text', 'Refresh', ...
        'BackgroundColor', [0.9 0.9 0.9], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,~) updateConvergenceTables());

    uilabel(controlGrid4, 'Text', '');

    % Store all axes in a structure
    visAxes = struct();
    visAxes.cpu = cpuAxes;
    visAxes.iter = iterAxes;
    visAxes.cond = condAxes;
    visAxes.section = sectionAxes;
    visAxes.iso = isoAxes;
    visAxes.convTable = convTable;
    visAxes.popupLambdaVal = popupLambdaVal;    
    visAxes.fig = fig;
    visAxes.donnees = [];
    visAxes.noms = [];

    % Store controls for cross-section
    visAxes.popupPlane = popupPlane;
    visAxes.editValue = editValue;
    visAxes.popupTime = popupTime;
    visAxes.editIsoValue = editIsoValue;

    % Data for physical visualizations
    visAxes.physData = struct();
    visAxes.physData.times = [];
    visAxes.physData.time_strings = {};
    visAxes.physData.nx = [];
    visAxes.physData.sol_dir = '';
    visAxes.physData.hasData = false;

    setappdata(fig, 'visAxes', visAxes);

    % ===================== BUTTONS =============================
    btns = uigridlayout(right,[1 3]);
    btns.Layout.Row     = 3;
    btns.ColumnWidth    = {'1x','1x','1x'};
    btns.ColumnSpacing  = 12;
    btns.Padding        = [0 0 0 0];

    bRun = uibutton(btns,'push',...
        'Text','  RUN',...
        'FontSize',14,...
        'FontWeight','bold',...
        'BackgroundColor',accent,...
        'FontColor',[1 1 1],...
        'ButtonPushedFcn',@onRun);

    bView = uibutton(btns,'push',...
        'Text',' VIEW RESULTS',...
        'FontSize',13,...
        'Enable','off',...
        'ButtonPushedFcn',@onView);

    bClose = uibutton(btns,'push','Text','CLOSE',...
        'FontSize',13,...
        'ButtonPushedFcn',@(~,~) close(fig));

    % ===================== LIVE MONITOR PANEL =====================
    monitor_panel = uipanel('Parent',root,'Units','pixels',...
                        'Title',' LIVE MONITOR ',...
                        'FontSize',11,'FontWeight','bold',...
                        'BackgroundColor',monitorBg,...
                        'ForegroundColor',fg,...
                        'BorderType','line',...
                        'HighlightColor',lineCol);
    monitor_panel.Layout.Row = 2;

    log_box = uicontrol('Parent',monitor_panel,'Style','listbox','Units','pixels',...
                    'BackgroundColor',[1 1 1],...
                    'FontName','Consolas',...
                    'FontSize',9,...
                    'Max',2,'Min',0,...
                    'String',{'--- Live log ---'});

    progress_frame = uicontrol('Parent',monitor_panel,'Style','text','Units','pixels',...
                          'BackgroundColor',progressBarBg,...
                          'HorizontalAlignment','left',...
                          'String','');

    progress_fill = uicontrol('Parent',monitor_panel,'Style','text','Units','pixels',...
                          'BackgroundColor',progressBarFill,...
                          'HorizontalAlignment','left',...
                          'String','');

    status_text = uicontrol('Parent',monitor_panel,'Style','text','Units','pixels',...
                        'BackgroundColor',monitorBg,...
                        'ForegroundColor',fg,...
                        'HorizontalAlignment','left',...
                        'String','Status: idle');

    monitor_handles = struct();
    monitor_handles.log_box = log_box;
    monitor_handles.progress_frame = progress_frame;
    monitor_handles.progress_fill = progress_fill;
    monitor_handles.status_text = status_text;

    monitor_timer = [];
    diary_file = '';

    setappdata(fig,'monitor_handles',monitor_handles);
    setappdata(fig,'monitor_timer',monitor_timer);
    setappdata(fig,'diary_file',diary_file);

    % Initial update
    validateAll();
    refreshEnable();

    function loadValidationData()
        visAxes = getappdata(fig, 'visAxes');
        
        try
            appendLog('--- Loading validation data for convergence tables (Newton) ---');
            
            current_dir = fileparts(mfilename('fullpath'));
            project_root = fileparts(current_dir);
            val_dir = fullfile(project_root, 'results', 'numerical_validation', 'Newton');
            
            if ~exist(val_dir, 'dir')
                val_dir = fullfile(current_dir, 'results', 'numerical_validation', 'Newton');
            end
            
            if ~exist(val_dir, 'dir')
                uialert(fig, 'Validation results not found.', 'Error');
                return;
            end
            
            lambda_dirs = dir(val_dir);
            lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
            
            lambda_vals = [];
            lambda_names = {};
            lambda_data = {};
            
            for k = 1:length(lambda_dirs)
                name = lambda_dirs(k).name;
                % Look for directories like "lambda_0_50", "lambda_0_75", etc.
                tok = regexp(name, 'lambda_([0-9_]+)', 'tokens', 'once');
                if ~isempty(tok)
                    lambda_str = strrep(tok{1}, '_', '.');
                    lambda_val = str2double(lambda_str);
                    
                    % Search recursively for resultats_complets.mat
                    data_files = dir(fullfile(val_dir, name, '**', 'resultats_complets.mat'));
                    
                    for f = 1:length(data_files)
                        data_file = fullfile(data_files(f).folder, data_files(f).name);
                        S = load(data_file);
                        if isfield(S, 'h_values') && (isfield(S, 'Erreur_L2') || isfield(S, 'newton_params'))
                            lambda_vals(end+1) = lambda_val;
                            lambda_names{end+1} = sprintf('λ = %.4f', lambda_val);
                            lambda_data{end+1} = S;
                            appendLog(sprintf('  Loaded λ=%.4f', lambda_val));
                            break;
                        end
                    end
                end
            end
            
            [lambda_vals, idx] = sort(lambda_vals);
            lambda_names = lambda_names(idx);
            lambda_data = lambda_data(idx);
            
            visAxes.valData = struct();
            visAxes.valData.lambda_vals = lambda_vals;
            visAxes.valData.lambda_names = lambda_names;
            visAxes.valData.lambda_data = lambda_data;
            
            visAxes.popupLambdaVal.Items = lambda_names;
            if ~isempty(lambda_names)
                visAxes.popupLambdaVal.Value = lambda_names{1};
            end
            
            setappdata(fig, 'visAxes', visAxes);
            
            appendLog(sprintf('✓ Loaded %d λ values', length(lambda_vals)));
            
            updateConvergenceTables();
            
        catch ME
            uialert(fig, ['Error loading data: ' ME.message], 'Error');
            appendLog([' Error: ' ME.message]);
        end
    end

    function updateConvergenceTables()
        visAxes = getappdata(fig, 'visAxes');
        
        if ~isfield(visAxes, 'valData') || isempty(visAxes.valData)
            uialert(fig, 'Load validation data first.', 'No Data');
            return;
        end
        
        lambda_str = visAxes.popupLambdaVal.Value;
        idx = find(strcmp(visAxes.valData.lambda_names, lambda_str), 1);
        if isempty(idx)
            return;
        end
        
        data = visAxes.valData.lambda_data{idx};
        
        if isfield(data, 'h_values')
            [h_vals, sort_idx] = sort(data.h_values, 'descend');
        else
            return;
        end
        
        n_rows = length(h_vals);
        table_data = cell(n_rows, 7);
        
        for i = 1:n_rows
            un_sur_h = 1 / h_vals(i);
            table_data{i,1} = sprintf('1/%d', round(un_sur_h));
            
            if isfield(data, 'Erreur_L2')
                table_data{i,2} = sprintf('%.2e', data.Erreur_L2(sort_idx(i)));
            else
                table_data{i,2} = '-';
            end
            
            if isfield(data, 'Erreur_H1')
                table_data{i,3} = sprintf('%.2e', data.Erreur_H1(sort_idx(i)));
            else
                table_data{i,3} = '-';
            end
            
            if isfield(data, 'Cond_max')
                table_data{i,4} = sprintf('%.1f', data.Cond_max(sort_idx(i)));
            else
                table_data{i,4} = '-';
            end
            
            if isfield(data, 'CPU_times')
                cpu_val = data.CPU_times(sort_idx(i));
                if cpu_val < 0.01
                    table_data{i,5} = sprintf('%.2e', cpu_val);
                elseif cpu_val < 1
                    table_data{i,5} = sprintf('%.2f', cpu_val);
                elseif cpu_val < 10
                    table_data{i,5} = sprintf('%.2f', cpu_val);
                else
                    table_data{i,5} = sprintf('%.1f', cpu_val);
                end
            else
                table_data{i,5} = '-';
            end
            
            if isfield(data, 'Newton_iters_moyenne')
                table_data{i,6} = sprintf('%d', round(data.Newton_iters_moyenne(sort_idx(i))));
            elseif isfield(data, 'iterations')
                table_data{i,6} = sprintf('%d', round(data.iterations(sort_idx(i))));
            else
                table_data{i,6} = '-';
            end
            
            if i > 1 && isfield(data, 'Erreur_L2')
                err_coarse = data.Erreur_L2(sort_idx(i-1));
                err_fine   = data.Erreur_L2(sort_idx(i));
                order = log2(err_coarse / err_fine);
                table_data{i,7} = sprintf('%.2f', order);
            else
                table_data{i,7} = '–';
            end
        end
        
        set(visAxes.convTable, 'Data', table_data);
        visAxes.convTable.ColumnWidth = {80, 100, 100, 80, 90, 60, 70};
        visAxes.convTable.Position = [0.02 0.02 0.96 0.96];
        visAxes.convTable.FontSize = 12;
    end

    function loadVisualisationData()
        visAxes = getappdata(fig, 'visAxes');
        
        try
            appendLog('--- Loading validation data for visualization (Newton) ---');
            
            current_dir = fileparts(mfilename('fullpath'));
            project_root = fileparts(current_dir);
            
            search_paths = {
                fullfile(project_root, 'results', 'numerical_validation', 'Newton');
                fullfile(current_dir, 'results', 'numerical_validation', 'Newton');
            };
            
            results_path = '';
            for i = 1:length(search_paths)
                if exist(search_paths{i}, 'dir') == 7
                    results_path = search_paths{i};
                    break;
                end
            end
            
            if isempty(results_path)
                uialert(fig, 'Results directory not found. Run simulations first.', 'Error');
                return;
            end
            
            lambda_dirs = dir(results_path);
            lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
            
            if isempty(lambda_dirs)
                uialert(fig, 'No lambda directories found.', 'Error');
                return;
            end
            
            donnees = {};
            noms = {};
            
            for i = 1:length(lambda_dirs)
                name = lambda_dirs(i).name;
                tok = regexp(name, 'lambda_([0-9_]+)', 'tokens', 'once');
                if ~isempty(tok)
                    lambda_str = strrep(tok{1}, '_', '.');
                    lambda_val = str2double(lambda_str);
                    
                    % Search for resultats_complets.mat
                    data_files = dir(fullfile(results_path, name, '**', 'resultats_complets.mat'));
                    
                    for f = 1:length(data_files)
                        data_file = fullfile(data_files(f).folder, data_files(f).name);
                        S = load(data_file);
                        if isfield(S, 'h_values') && isfield(S, 'CPU_times')
                            S.lambda = lambda_val;
                            donnees{end+1} = S;
                            noms{end+1} = sprintf('Newton (λ=%.4f)', lambda_val);
                            appendLog(sprintf('  Loaded λ=%.4f with %d points', lambda_val, length(S.h_values)));
                            break;
                        end
                    end
                end
            end
            
            if isempty(donnees)
                uialert(fig, 'No valid data found.', 'Error');
                return;
            end
            
            visAxes.donnees = donnees;
            visAxes.noms = noms;
            
            setappdata(fig, 'visAxes', visAxes);
            
            updateVisualisationPlots();
            
            appendLog(sprintf('✓ Loaded %d λ values', length(donnees)));
            
        catch ME
            uialert(fig, ['Error loading data: ' ME.message], 'Error');
            appendLog([' Error loading data: ' ME.message]);
        end
    end

    function updateVisualisationPlots()
        visAxes = getappdata(fig, 'visAxes');
        
        if isempty(visAxes.donnees)
            return;
        end
        
        donnees = visAxes.donnees;
        noms = visAxes.noms;
        
        couleurs_base = [
            0, 0.4470, 0.7410;
            0.4660, 0.6740, 0.1880;
            0.9290, 0.6940, 0.1250;
            0.4940, 0.1840, 0.5560;
            0.3010, 0.7450, 0.9330;
            0.6350, 0.0780, 0.1840;
            0.2, 0.2, 0.2;
            0.8500, 0.3250, 0.0980
        ];
        
        styles = {'-o', '-s', '-^', '-d', '-v', '-p', '-h', '--s'};
        
        cla(visAxes.cpu);
        cla(visAxes.iter);
        cla(visAxes.cond);
        
        hold(visAxes.cpu, 'on');
        hold(visAxes.iter, 'on');
        hold(visAxes.cond, 'on');
        
        for i = 1:length(donnees)
            data = donnees{i};
            nom = noms{i};
            
            if isfield(data, 'h_values')
                [h_sorted, idx] = sort(data.h_values);
                x_vals = 1./h_sorted;
            else
                continue;
            end
            
            couleur = couleurs_base(mod(i-1, size(couleurs_base,1)) + 1, :);
            style = styles{mod(i-1, length(styles)) + 1};
            
            if isfield(data, 'CPU_times')
                y_vals = data.CPU_times(idx);
                plot(visAxes.cpu, x_vals, y_vals, style, ...
                    'Color', couleur, 'LineWidth', 2.5, ...
                    'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                    'DisplayName', nom);
            end
            
            if isfield(data, 'Newton_iters_moyenne')
                y_vals = data.Newton_iters_moyenne(idx);
                plot(visAxes.iter, x_vals, y_vals, style, ...
                    'Color', couleur, 'LineWidth', 2.5, ...
                    'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                    'DisplayName', nom);
            elseif isfield(data, 'iterations')
                y_vals = data.iterations(idx);
                plot(visAxes.iter, x_vals, y_vals, style, ...
                    'Color', couleur, 'LineWidth', 2.5, ...
                    'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                    'DisplayName', nom);
            end
            
            if isfield(data, 'Cond_max')
                y_vals = data.Cond_max(idx);
                plot(visAxes.cond, x_vals, y_vals, style, ...
                    'Color', couleur, 'LineWidth', 2.5, ...
                    'MarkerSize', 6, 'MarkerFaceColor', couleur, ...
                    'DisplayName', nom);
            end
        end
        
        set(visAxes.cpu, 'YScale', 'log', 'FontSize', 10);
        set(visAxes.cond, 'YScale', 'log', 'FontSize', 10);
        set(visAxes.iter, 'FontSize', 10);
        
        legend(visAxes.cpu, 'Location', 'best', 'FontSize', 8);
        legend(visAxes.iter, 'Location', 'best', 'FontSize', 8);
        legend(visAxes.cond, 'Location', 'best', 'FontSize', 8);
        
        hold(visAxes.cpu, 'off');
        hold(visAxes.iter, 'off');
        hold(visAxes.cond, 'off');
        
        drawnow;
        
        setappdata(fig, 'visAxes', visAxes);
    end

    function refreshVisualisation()
        visAxes = getappdata(fig, 'visAxes');
        if ~isempty(visAxes.donnees)
            updateVisualisationPlots();
            appendLog(' Visualization plots refreshed');
        else
            appendLog(' No data loaded. Click "Load Data" first.');
        end
    end

    function exportVisualisation()
        visAxes = getappdata(fig, 'visAxes');
        
        if isempty(visAxes.donnees)
            uialert(fig, 'No data to export.', 'Export Error');
            return;
        end
        
        exportDir = uigetdir(pwd, 'Select directory to export figures');
        if exportDir == 0
            return;
        end
        
        appendLog([' Figures exported to: ' exportDir]);
    end

    function loadPhysicalCrossSectionData()
        visAxes = getappdata(fig, 'visAxes');
        
        try
            appendLog('--- Loading physical case data for cross-sections (Newton) ---');
            
            current_dir = fileparts(mfilename('fullpath'));
            project_root = fileparts(current_dir);
            base_results_dir = fullfile(project_root, 'results');
            
            if exist(base_results_dir, 'dir') ~= 7
                base_results_dir = fullfile(current_dir, 'results');
            end
            
            case_root = fullfile(base_results_dir, 'physical_case');
            if exist(case_root, 'dir') ~= 7
                uialert(fig, 'Physical case results not found.', 'Error');
                return;
            end
            
            scheme_root = fullfile(case_root, 'Newton');
            if exist(scheme_root, 'dir') ~= 7
                uialert(fig, 'Newton folder not found.', 'Error');
                return;
            end
            
            lambda_dirs = dir(scheme_root);
            lambda_dirs = lambda_dirs([lambda_dirs.isdir] & ~ismember({lambda_dirs.name}, {'.','..'}));
            
            if isempty(lambda_dirs)
                uialert(fig, 'No lambda folder found.', 'Error');
                return;
            end
            
            bestIdx = [];
            bestTime = -inf;
            
            for k = 1:numel(lambda_dirs)
                cand = fullfile(scheme_root, lambda_dirs(k).name);
                % Look for dt subdirectories
                dt_dirs = dir(cand);
                dt_dirs = dt_dirs([dt_dirs.isdir] & ~ismember({dt_dirs.name}, {'.','..'}));
                
                for d = 1:numel(dt_dirs)
                    sol_dir_k = fullfile(cand, dt_dirs(d).name, 'solutions_temporelles');
                    if exist(sol_dir_k, 'dir') ~= 7
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
                uialert(fig, 'No valid solution files found.', 'Error');
                return;
            end
            
            chosen_dir = fullfile(scheme_root, bestIdx.lambda_dir, bestIdx.dt_dir);
            sol_dir = fullfile(chosen_dir, 'solutions_temporelles');
            
            files = dir(fullfile(sol_dir, 'solution_nx*_t*s.mat'));
            nxVals = [];
            for i = 1:numel(files)
                tok = regexp(files(i).name, 'solution_nx(\d+)_', 'tokens', 'once');
                if ~isempty(tok)
                    nxVals(end+1) = str2double(tok{1});
                end
            end
            
            if isempty(nxVals)
                uialert(fig, 'Cannot extract nx from filenames.', 'Error');
                return;
            end
            
            nx = max(nxVals);
            
            pattern = sprintf('solution_nx%d_t*.mat', nx);
            time_files = dir(fullfile(sol_dir, pattern));
            
            time_values = [];
            time_strings = {};
            
            for i = 1:numel(time_files)
                tok = regexp(time_files(i).name, '_t([0-9.eE+-]+)s\.mat', 'tokens', 'once');
                if ~isempty(tok)
                    t_val = str2double(tok{1});
                    if isfinite(t_val)
                        time_values(end+1) = t_val;
                        time_strings{end+1} = sprintf('t = %.6g h', t_val);
                    end
                end
            end
            
            if isempty(time_values)
                uialert(fig, 'Cannot extract times from filenames.', 'Error');
                return;
            end
            
            [time_values, sort_idx] = sort(time_values, 'ascend');
            time_strings = time_strings(sort_idx);
            
            visAxes.physData.times = time_values;
            visAxes.physData.time_strings = time_strings;
            visAxes.physData.nx = nx;
            visAxes.physData.sol_dir = sol_dir;
            visAxes.physData.hasData = true;
            
            visAxes.popupTime.Items = time_strings;
            if ~isempty(time_strings)
                visAxes.popupTime.Value = time_strings{1};
            end
            
            setappdata(fig, 'visAxes', visAxes);
            
            appendLog(sprintf('✓ Loaded physical data: nx=%d, %d time steps', nx, length(time_values)));
            
            updatePhysicalVisualizations();
            
        catch ME
            uialert(fig, ['Error loading physical data: ' ME.message], 'Error');
            appendLog([' Error: ' ME.message]);
        end
    end

    function updatePhysicalVisualizations()
        visAxes = getappdata(fig, 'visAxes');
        
        if ~visAxes.physData.hasData
            uialert(fig, 'Load physical data first.', 'No Data');
            return;
        end
        
        time_str = visAxes.popupTime.Value;
        plane_str = visAxes.popupPlane.Value;
        cut_val = visAxes.editValue.Value;
        iso_val = visAxes.editIsoValue.Value;
        
        time_idx = find(strcmp(visAxes.physData.time_strings, time_str), 1);
        if isempty(time_idx)
            return;
        end
        
        t = visAxes.physData.times(time_idx);
        nx = visAxes.physData.nx;
        sol_dir = visAxes.physData.sol_dir;
        
        switch plane_str
            case 'x = constant'
                cut_mode = 2;
            case 'y = constant'
                cut_mode = 3;
            case 'z = constant'
                cut_mode = 1;
        end
        
        try
            cla(visAxes.section);
            [p, ~, u, tm] = charger_donnees_temps(sol_dir, nx, t);
            if ~isempty(p)
                temp_fig = figure('Visible', 'off');
                show_cut_from_file(sol_dir, nx, t, cut_mode, cut_val);
                temp_ax = gca;
                temp_ax.Position = [0.15 0.18 0.8 0.7];
                copyobj(temp_ax.Children, visAxes.section);
                visAxes.section.XLim = temp_ax.XLim;
                visAxes.section.YLim = temp_ax.YLim;
                visAxes.section.XLabel.String = temp_ax.XLabel.String;
                visAxes.section.YLabel.String = temp_ax.YLabel.String;
                visAxes.section.FontSize = 10;
                close(temp_fig);
                title(visAxes.section, '');
            end
            
            cla(visAxes.iso);
            if ~isempty(p)
                temp_fig = figure('Visible', 'off');
                show_isosurface_from_file(sol_dir, nx, t);
                temp_ax = gca;
                temp_ax.Position = [0.15 0.09 0.6 0.6];
                copyobj(temp_ax.Children, visAxes.iso);
                visAxes.iso.XLim = temp_ax.XLim;
                visAxes.iso.YLim = temp_ax.YLim;
                visAxes.iso.ZLim = temp_ax.ZLim;
                visAxes.iso.View = temp_ax.View;
                visAxes.iso.XLabel.String = temp_ax.XLabel.String;
                visAxes.iso.YLabel.String = temp_ax.YLabel.String;
                visAxes.iso.ZLabel.String = temp_ax.ZLabel.String;
                visAxes.iso.FontSize = 12;
                close(temp_fig);
                title(visAxes.iso, '');
            end
            
            drawnow;
            
        catch ME
            uialert(fig, ['Error updating visualizations: ' ME.message], 'Error');
            appendLog([' Visualization error: ' ME.message]);
        end
    end

    function show_isosurface_from_file(sol_dir, nx, t)
        [P, ~, U, tm] = charger_donnees_temps(sol_dir, nx, t);
        if isempty(P), return; end
        if isempty(tm), tm = t; end

        mx = max(17, min(129, nx+1));
        [X,Y,Z] = meshgrid(linspace(0,1,mx), linspace(0,1,mx), linspace(0,1,mx));

        try
            Fint  = scatteredInterpolant(P(:,1),P(:,2),P(:,3),U,'natural','none');
            Ugrid = Fint(X,Y,Z);
        catch
            Ugrid = griddata(P(:,1),P(:,2),P(:,3),U,X,Y,Z,'linear');
        end

        umin = min(Ugrid(:)); 
        umax = max(Ugrid(:));
        if ~isfinite(umin) || ~isfinite(umax) || umax <= umin
            fprintf('Iso: invalid Ugrid range.\n');
            return;
        end

        iso_value = umin+0.475*(umax-umin);
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
        ax.FontSize   = 6;
        ax.LineWidth  = 1.5;
        ax.FontWeight = 'bold';

        xlabel('x','FontSize',11,'FontWeight','bold');
        ylabel('y','FontSize',11,'FontWeight','bold');
        zlabel('z','FontSize',11,'FontWeight','bold');

        title(sprintf('Isosurface (t=%.3f)', tm), 'FontWeight','bold');

        colormap(jet);
        cb = colorbar;
        cb.FontSize = 11;
    end

    % ===================== CALLBACKS / HELPERS =====================
    function validateAll(~,~)
        validateNxPhysical();
        validateNxList();
        validateLambdaVec();
        validateLambdaScalar();
        update_h_label();
        update_previews();
        update_phys_chips();
    end

    function update_phys_chips()
        delete(physPreviewGrid.Children);

        Nx = str2double(strtrim(edNxPhys.Value));
        if ~isfinite(Nx), Nx = NaN; end

        tau = edDt0Phys.Value;
        Tf  = edTfPhys.Value;
        Ls  = edLambdaScalar.Value;

        makeChip(physPreviewGrid, sprintf('Nx = %s', safeInt(Nx)), 'Example: Nx=9');
        makeChip(physPreviewGrid, sprintf('τ = %s h', safeNum(tau)), 'Example: τ=0.25 h');
        makeChip(physPreviewGrid, sprintf('t_f = %s h', safeNum(Tf)), 'Example: t_final=8 h');
        makeChip(physPreviewGrid, sprintf('λ = %s', safeNum(Ls)), 'Example: λ=0.5');
    end

    function makeChip(parent, txt, tip)
        chip = uipanel(parent, 'BackgroundColor', chipBg, 'BorderType', 'line');
        cg = uigridlayout(chip, [1 1]);
        cg.Padding = [10 4 10 4];
        lb = uilabel(cg, 'Text', txt, ...
            'FontName', 'Consolas', 'FontSize', 10, ...
            'HorizontalAlignment', 'center', 'FontColor', fg);
        lb.Tooltip = tip;
    end

    function s = safeInt(x)
        if ~isfinite(x), s = '—'; return; end
        s = sprintf('%d', round(x));
    end

    function s = safeNum(x)
        if ~isfinite(x), s = '—'; return; end
        if abs(x) >= 1e3 || (abs(x) > 0 && abs(x) < 1e-3)
            s = sprintf('%.3g', x);
        else
            s = sprintf('%.4g', x);
        end
    end

    function [valid, value] = validateNxPhysical()
        value = str2double(strtrim(edNxPhys.Value));
        valid = isfinite(value) && value >= 3 && abs(value - round(value)) < 1e-10;
        if valid
            nxPhysValid.Text = ''; nxPhysValid.FontColor = success;
        else
            nxPhysValid.Text = '✗'; nxPhysValid.FontColor = errorC;
        end
    end

    function [valid, values] = validateNxList()
        values = str2num(strtrim(edNxListVal.Value)); 
        valid = ~isempty(values) && all(isfinite(values)) && all(values >= 2) && all(abs(values - round(values)) < 1e-10);
        if valid
            nxListValid.Text = ''; nxListValid.FontColor = success;
        else
            nxListValid.Text = '✗'; nxListValid.FontColor = errorC;
        end
    end

    function [valid, values] = validateLambdaVec()
        values = str2num(strtrim(edLambdaVec.Value)); 
        valid = ~isempty(values) && all(isfinite(values)) && all(values > 0) && all(values <= 1);
        if valid
            lambdaVecValid.Text = ''; lambdaVecValid.FontColor = success;
        else
            lambdaVecValid.Text = '✗'; lambdaVecValid.FontColor = errorC;
        end
    end

    function valid = validateLambdaScalar()
        value = edLambdaScalar.Value;
        valid = isfinite(value) && value > 0 && value <= 1;
        if valid
            lambdaScalarValid.Text = ''; lambdaScalarValid.FontColor = success;
        else
            lambdaScalarValid.Text = '✗'; lambdaScalarValid.FontColor = errorC;
        end
    end

    function refreshEnable(~,~)
        runPhysical   = cbPhysical.Value;
        runValidation = cbValidation.Value;

        pPhys.Visible = onoff(runPhysical);
        pVal.Visible  = onoff(runValidation);

        if runPhysical && runValidation
            left.RowHeight = {H_cases, H_phys, '1x'};
        elseif runPhysical && ~runValidation
            left.RowHeight = {H_cases, '1x', 0};
        elseif ~runPhysical && runValidation
            left.RowHeight = {H_cases, 0, '1x'};
        else
            left.RowHeight = {H_cases, 0, 0};
        end

        if (~runPhysical && ~runValidation) && isvalid(bView)
            bView.Enable = 'off';
        end

        validateAll();
    end

    function s = onoff(tf)
        if tf, s = 'on'; else, s = 'off'; end
    end

    function update_h_label(~,~)
        [valid, Nx] = validateNxPhysical();
        if ~valid
            hLabel.Text = 'h = 1/(Nx-1)';
            return;
        end
        Nx = round(Nx);
        denom = Nx - 1;
        hLabel.Text = sprintf('h = 1/(Nx-1) = 1/%d', denom);  
    end

    function update_previews()
        buildVectorChipsH(nxPreviewGrid, edNxListVal.Value, 'h:', false);
        buildVectorChips(lambdaPreviewGrid, edLambdaVec.Value, 'λ:', false);
    end

    function buildVectorChipsH(parentGrid, str, titleText, asIntegers)
        delete(parentGrid.Children);

        outer = uigridlayout(parentGrid, [1 2]);
        outer.ColumnWidth     = {42, '1x'};
        outer.RowHeight       = {24};
        outer.Padding         = [0 0 0 0];
        outer.ColumnSpacing   = 8;

        uilabel(outer, 'Text', titleText, 'FontColor', sub, 'FontSize', 10, 'FontWeight', 'bold');

        chipsHost = uigridlayout(outer, [1 1]);
        chipsHost.Padding = [0 0 0 0];

        v = str2num(strtrim(str)); 
        if isempty(v)
            uilabel(chipsHost, 'Text', '(invalid)', 'FontColor', errorC, 'FontSize', 10, 'FontAngle', 'italic');
            return;
        end

        h_values = 1 ./ (v - 1);
        h_formatted = cell(1, length(h_values));
        for i = 1:length(h_values)
            denom = round(1 / h_values(i));
            if abs(h_values(i) - 1/denom) < 1e-10
                h_formatted{i} = sprintf('1/%d', denom);
            else
                h_formatted{i} = sprintf('%.4g', h_values(i));
            end
        end

        maxChips = 7;
        show = h_formatted;
        truncated = numel(show) > maxChips;
        if truncated, show = show(1:maxChips); end

        n = numel(show);
        chips = uigridlayout(chipsHost, [1, n + double(truncated)]);
        chips.Padding         = [0 0 0 0];
        chips.RowHeight       = 24;
        chips.ColumnSpacing   = 6;

        for i = 1:n
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', show{i}, ...
                'FontName', 'Consolas', 'FontSize', 10, ...
                'HorizontalAlignment', 'center', 'FontColor', fg);
        end

        if truncated
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', '&', 'FontName', 'Consolas', 'FontSize', 12, ...
                'HorizontalAlignment', 'center', 'FontColor', sub);
        end
    end

    function buildVectorChips(parentGrid, str, titleText, asIntegers)
        delete(parentGrid.Children);

        outer = uigridlayout(parentGrid, [1 2]);
        outer.ColumnWidth     = {42, '1x'};
        outer.RowHeight       = {24};
        outer.Padding         = [0 0 0 0];
        outer.ColumnSpacing   = 8;

        uilabel(outer, 'Text', titleText, 'FontColor', sub, 'FontSize', 10, 'FontWeight', 'bold');

        chipsHost = uigridlayout(outer, [1 1]);
        chipsHost.Padding = [0 0 0 0];

        v = str2num(strtrim(str)); 
        if isempty(v)
            uilabel(chipsHost, 'Text', '(invalid)', 'FontColor', errorC, 'FontSize', 10, 'FontAngle', 'italic');
            return;
        end

        if asIntegers, v = round(v); end

        maxChips = 7;
        show = v(:)'; 
        truncated = numel(show) > maxChips;
        if truncated, show = show(1:maxChips); end

        n = numel(show);
        chips = uigridlayout(chipsHost, [1, n + double(truncated)]);
        chips.Padding         = [0 0 0 0];
        chips.RowHeight       = 24;
        chips.ColumnSpacing   = 6;

        for i = 1:n
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', formatNumber(show(i), asIntegers), ...
                'FontName', 'Consolas', 'FontSize', 10, ...
                'HorizontalAlignment', 'center', 'FontColor', fg);
        end

        if truncated
            chip = uipanel(chips, 'BackgroundColor', chipBg, 'BorderType', 'line');
            cg = uigridlayout(chip, [1 1]);
            cg.Padding = [6 2 6 2];
            uilabel(cg, 'Text', '&', 'FontName', 'Consolas', 'FontSize', 12, ...
                'HorizontalAlignment', 'center', 'FontColor', sub);
        end
    end

    function s = formatNumber(x, asInt)
        if asInt
            s = sprintf('%d', round(x));
        else
            if abs(x) >= 1e3 || (abs(x) > 0 && abs(x) < 1e-3)
                s = sprintf('%.3g', x);
            else
                s = sprintf('%.4g', x);
            end
        end
    end

    function appendLog(line)
        v = logArea.Value;
        if numel(v) == 1 && (isempty(v{1}) || strcmp(v{1}, ' '))
            v = {};
        end
        v{end + 1, 1} = line;
        logArea.Value = v;

        if ishandle(log_box)
            current = get(log_box, 'String');
            if ischar(current)
                current = cellstr(current);
            end
            if isempty(current) || (numel(current) == 1 && strcmp(current{1}, '--- Live log ---'))
                current = {};
            end
            current{end + 1, 1} = line;
            if numel(current) > 100
                current = current(end - 99:end);
            end
            set(log_box, 'String', current, 'Value', numel(current));
        end

        drawnow;
    end

    function start_live_monitor()
        set(log_box, 'String', {'--- Live log ---'}, 'Value', 1);
        set(status_text, 'String', 'Status: running main.m ...');

        diary_file = fullfile(tempdir, sprintf('live_main_log_%s.txt', datestr(now, 'yyyymmdd_HHMMSS')));
        setappdata(fig, 'diary_file', diary_file);

        try
            diary('off');
            diary(diary_file);
            diary('on');
        catch
        end

        setappdata(fig, 'live_bar_pos', 0);
        setappdata(fig, 'live_bar_dir', 1);

        monitor_timer = timer(...
            'ExecutionMode', 'fixedSpacing', ...
            'Period', 0.25, ...
            'BusyMode', 'drop', ...
            'TimerFcn', @(~, ~) live_tick(), ...
            'Tag', 'LIVE_MONITOR_TIMER');

        setappdata(fig, 'monitor_timer', monitor_timer);
        start(monitor_timer);
    end

    function stop_live_monitor()
        monitor_timer = getappdata(fig, 'monitor_timer');
        if ~isempty(monitor_timer) && isvalid(monitor_timer)
            stop(monitor_timer);
            delete(monitor_timer);
        end

        try
            diary('off');
        catch
        end

        if ishandle(status_text)
            set(status_text, 'String', 'Status: finished. You can click VIEW RESULTS.');
        end

        try
            p = get(progress_fill, 'Position');
            barW = get(progress_frame, 'Position');
            p(3) = barW(3);
            set(progress_fill, 'Position', p);
        catch
        end
    end

    function live_tick()
        try
            p = get(progress_fill, 'Position');
            baseX = p(1);
            baseY = p(2);
            baseH = p(4);

            barW = get(progress_frame, 'Position');
            barW = barW(3);
            blockW = min(120, max(70, round(0.18 * barW)));

            pos = getappdata(fig, 'live_bar_pos');
            dir = getappdata(fig, 'live_bar_dir');

            pos = pos + dir * 14;
            if pos <= 0
                pos = 0;
                dir = 1;
            elseif pos >= (barW - blockW)
                pos = barW - blockW;
                dir = -1;
            end

            setappdata(fig, 'live_bar_pos', pos);
            setappdata(fig, 'live_bar_dir', dir);

            set(progress_fill, 'Position', [baseX + pos, baseY, blockW, baseH]);
        catch
        end

        try
            diary_file = getappdata(fig, 'diary_file');
            if isempty(diary_file) || ~exist(diary_file, 'file')
                return;
            end

            txt = fileread(diary_file);
            if isempty(txt)
                return;
            end

            lines = regexp(txt, '\r\n|\n|\r', 'split');
            if isempty(lines)
                return;
            end

            N = 100;
            if numel(lines) > N
                lines = lines(end - N + 1:end);
            end

            old = get(log_box, 'String');
            if ~isequal(old, lines)
                set(log_box, 'String', lines, 'Value', numel(lines));
                drawnow limitrate;
            end
        catch
        end
    end

    % ========================= AUTO-JUMP ====================
    function onWindowKeyPress(~, evt)
        if ~isfield(evt, 'Key') || isempty(evt.Key), return; end
        key = lower(string(evt.Key));
        if ~(key == "space" || key == "return" || key == "enter")
            return;
        end

        obj = [];
        try
            obj = fig.CurrentObject;
        catch
            return;
        end
        if isempty(obj) || ~isvalid(obj), return; end

        if obj == edNxListVal
            if firstTokenComplete(edNxListVal.Value, true)
                safeFocus(edDt0);
            end
            return;
        end

        if obj == edLambdaVec
            if firstTokenComplete(edLambdaVec.Value, false)
                safeFocus(bRun);
            end
            return;
        end
    end

    function tf = firstTokenComplete(txt, mustBeInt)
        s = strtrim(char(txt));
        if isempty(s), tf = false; return; end
        parts = regexp(s, '\s+', 'split');
        if isempty(parts), tf = false; return; end
        x = str2double(parts{1});
        if ~isfinite(x), tf = false; return; end
        if mustBeInt && abs(x - round(x)) > 1e-10
            tf = false; return;
        end
        tf = (numel(parts) == 1);
    end

    function safeFocus(comp)
        try
            focus(comp);
        catch
        end
    end

    % ========================= VIEW RESULTS ====================
    function onView(~, ~)
        try
            appendLog('--- VIEW RESULTS: batch_view_rules_bat ---');
            evalin('base', 'batch_view_rules_bat;');
            appendLog(' Viewer finished.');
        catch ME
            uialert(fig, getReport(ME, 'extended', 'hyperlinks', 'off'), 'Viewer error');
            appendLog([' Viewer error: ' ME.message]);
        end
    end

    % % ========================= RUN =============================
    % function onRun(~, ~)
    %     runPhysical   = cbPhysical.Value;
    %     runValidation = cbValidation.Value;
    % 
    %     if ~runPhysical && ~runValidation
    %         uialert(fig, 'Select at least one case (Physical and/or Validation).', 'Input error');
    %         return;
    %     end
    % 
    %     [physOK, ~]  = validateNxPhysical();
    %     [valNxOK, ~] = validateNxList();
    %     [lambdaVecOK, ~] = validateLambdaVec();
    %     lambdaScalOK = validateLambdaScalar();
    % 
    %     tfValOK   = isfinite(edTf.Value)      && edTf.Value      > 0;
    %     dtValOK   = isfinite(edDt0.Value)     && edDt0.Value     > 0;
    %     tfPhysOK  = isfinite(edTfPhys.Value)  && edTfPhys.Value  > 0;
    %     dtPhysOK  = isfinite(edDt0Phys.Value) && edDt0Phys.Value > 0;
    % 
    %     if (runPhysical && (~physOK || ~lambdaScalOK || ~tfPhysOK || ~dtPhysOK)) || ...
    %        (runValidation && (~valNxOK || ~lambdaVecOK || ~tfValOK || ~dtValOK))
    %         uialert(fig, 'Please fix validation errors before running.', 'Validation Error');
    %         return;
    %     end
    % 
    %     vertisol_mode = ddMode.Value;
    % 
    %     Nx_phys_str = strtrim(edNxPhys.Value);
    %     Nx_list_str = strtrim(edNxListVal.Value);
    % 
    %     Tf_phys_val = edTfPhys.Value;
    %     Dt0_phys    = edDt0Phys.Value;
    % 
    %     Tf_val      = edTf.Value;
    %     Dt0_val     = edDt0.Value;
    % 
    %     lambda_vec_str = strtrim(edLambdaVec.Value);
    %     lambda_scalar_val = edLambdaScalar.Value;
    % 
    %     mainScriptEsc = strrep(mainScript, '''', '''''');
    % 
    %     if isvalid(bView), bView.Enable = 'off'; end
    % 
    %     start_live_monitor();
    % 
    %     appendLog('============================================');
    %     appendLog(['RUN started: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);
    %     appendLog(['Cases: ' ternary(runPhysical, 'Physical ', '') ternary(runValidation, 'Validation', '')]);
    %     appendLog(['Mode:  ' char(vertisol_mode)]);
    % 
    %     if runPhysical
    %         appendLog(sprintf('Physical: dt=%.6g h | t_final=%.6g h | Nx=%s | λ_scalar=%.6g', ...
    %             Dt0_phys, Tf_phys_val, Nx_phys_str, lambda_scalar_val));
    %     end
    %     if runValidation
    %         appendLog(sprintf('Validation: dt=%.6g h | t_final=%.6g h | Nx=[%s] | λ=[%s]', ...
    %             Dt0_val, Tf_val, Nx_list_str, lambda_vec_str));
    %     end
    % 
    %     function cmd = build_cmd(case_name)
    %         cmd = "clear case_type vertisol_mode Nx_list t_final dt0 L_vec L_scalar lambda_list dt_list lam_Newton; ";
    %         cmd = cmd + "case_type='" + string(case_name) + "'; ";
    %         cmd = cmd + "vertisol_mode='" + string(vertisol_mode) + "'; ";
    % 
    %         if case_name == "physical_case"
    %             cmd = cmd + "dt0=" + string(Dt0_phys) + "; ";
    %             cmd = cmd + "t_final=" + string(Tf_phys_val) + "; ";
    %             cmd = cmd + "Nx_list=[" + string(Nx_phys_str) + "]; ";
    %             cmd = cmd + "lam_Newton=" + string(lambda_scalar_val) + "; ";
    %         else
    %             cmd = cmd + "dt0=" + string(Dt0_val) + "; ";
    %             cmd = cmd + "t_final=" + string(Tf_val) + "; ";
    %             cmd = cmd + "Nx_list=[" + string(Nx_list_str) + "]; ";
    %             cmd = cmd + "lambda_list=[" + string(lambda_vec_str) + "]; ";
    %             cmd = cmd + "dt_list=[" + string(Dt0_val) + "]; ";
    %         end
    % 
    %         cmd = cmd + "run('" + string(mainScriptEsc) + "');";
    %     end
    % 
    %     try
    %         if runPhysical
    %             appendLog('--- Running physical_case ---');
    %             evalin('base', build_cmd("physical_case"));
    %             appendLog(' physical_case finished.');
    %         end
    % 
    %         if runValidation
    %             appendLog('--- Running numerical_validation ---');
    %             evalin('base', build_cmd("numerical_validation"));
    %             appendLog(' numerical_validation finished.');
    %         end
    % 
    %         appendLog('RUN finished ');
    %         appendLog('============================================');
    % 
    %         if isvalid(bView), bView.Enable = 'on'; end
    % 
    %         sumArea.Value = { ...
    %             '--- SIMULATION SUMMARY (NEWTON) ---'; ...
    %             sprintf('Mode: %s', vertisol_mode); ...
    %             '---'; ...
    %             sprintf('Physical: %s', ternary(runPhysical, ...
    %                 sprintf('dt=%.6g h | t_final=%.6g h | Nx=%s | λ=%.6g', Dt0_phys, Tf_phys_val, Nx_phys_str, lambda_scalar_val), ...
    %                 'not run')); ...
    %             sprintf('Validation: %s', ternary(runValidation, ...
    %                 sprintf('dt=%.6g h | t_final=%.6g h | Nx=[%s] | λ=[%s]', Dt0_val, Tf_val, Nx_list_str, lambda_vec_str), ...
    %                 'not run')); ...
    %             '---'; ...
    %             sprintf('Completed: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS')) ...
    %         };
    % 
    %         stop_live_monitor();
    % 
    %     catch ME
    %         uialert(fig, getReport(ME, 'extended', 'hyperlinks', 'off'), 'Run error');
    %         appendLog(['Run error: ' ME.message]);
    %         stop_live_monitor();
    %     end
    % end
        % ========================= RUN =============================
    % function onRun(~, ~)
    %     runPhysical   = cbPhysical.Value;
    %     runValidation = cbValidation.Value;
    % 
    %     if ~runPhysical && ~runValidation
    %         uialert(fig, 'Select at least one case (Physical and/or Validation).', 'Input error');
    %         return;
    %     end
    % 
    %     [physOK, ~]  = validateNxPhysical();
    %     [valNxOK, ~] = validateNxList();
    %     [lambdaVecOK, ~] = validateLambdaVec();
    %     lambdaScalOK = validateLambdaScalar();
    % 
    %     tfValOK   = isfinite(edTf.Value)      && edTf.Value      > 0;
    %     dtValOK   = isfinite(edDt0.Value)     && edDt0.Value     > 0;
    %     tfPhysOK  = isfinite(edTfPhys.Value)  && edTfPhys.Value  > 0;
    %     dtPhysOK  = isfinite(edDt0Phys.Value) && edDt0Phys.Value > 0;
    % 
    %     if (runPhysical && (~physOK || ~lambdaScalOK || ~tfPhysOK || ~dtPhysOK)) || ...
    %        (runValidation && (~valNxOK || ~lambdaVecOK || ~tfValOK || ~dtValOK))
    %         uialert(fig, 'Please fix validation errors before running.', 'Validation Error');
    %         return;
    %     end
    % 
    %     vertisol_mode = ddMode.Value;
    % 
    %     Nx_phys_str = strtrim(edNxPhys.Value);
    %     Nx_list_str = strtrim(edNxListVal.Value);
    % 
    %     % Convert string to numeric array
    %     Nx_list_num = str2num(Nx_list_str);
    %     if isempty(Nx_list_num)
    %         uialert(fig, 'Invalid Nx list format.', 'Error');
    %         return;
    %     end
    % 
    %     Tf_phys_val = edTfPhys.Value;
    %     Dt0_phys    = edDt0Phys.Value;
    % 
    %     Tf_val      = edTf.Value;
    %     Dt0_val     = edDt0.Value;
    % 
    %     lambda_vec_str = strtrim(edLambdaVec.Value);
    %     lambda_vec_num = str2num(lambda_vec_str);
    %     if isempty(lambda_vec_num)
    %         uialert(fig, 'Invalid lambda vector format.', 'Error');
    %         return;
    %     end
    % 
    %     lambda_scalar_val = edLambdaScalar.Value;
    % 
    %     mainScriptEsc = strrep(mainScript, '''', '''''');
    % 
    %     if isvalid(bView), bView.Enable = 'off'; end
    % 
    %     start_live_monitor();
    % 
    %     appendLog('============================================');
    %     appendLog(['RUN started: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);
    %     appendLog(['Cases: ' ternary(runPhysical, 'Physical ', '') ternary(runValidation, 'Validation', '')]);
    %     appendLog(['Mode:  ' char(vertisol_mode)]);
    % 
    %     if runPhysical
    %         appendLog(sprintf('Physical: dt=%.6g h | t_final=%.6g h | Nx=%s | λ=%.6g', ...
    %             Dt0_phys, Tf_phys_val, Nx_phys_str, lambda_scalar_val));
    %     end
    %     if runValidation
    %         appendLog(sprintf('Validation: dt=%.6g h | t_final=%.6g h | Nx=[%s] | λ=[%s]', ...
    %             Dt0_val, Tf_val, Nx_list_str, lambda_vec_str));
    %     end
    % 
    %     function cmd = build_cmd(case_name)
    %         % Base command - clear all variables that might interfere
    %         cmd = "clear; ";
    % 
    %         % Common parameters
    %         cmd = cmd + "case_type='" + string(case_name) + "'; ";
    %         cmd = cmd + "vertisol_mode='" + string(vertisol_mode) + "'; ";
    %         cmd = cmd + "test_id=" + string(test_id) + "; ";
    %         cmd = cmd + "test_cond=" + string(test_cond) + "; ";
    %         cmd = cmd + "eps1=1e-8; ";
    %         cmd = cmd + "save_interval=" + string(save_interval) + "; ";
    %         cmd = cmd + "ell=3; ";
    %         cmd = cmd + "iso=-0.001; ";
    % 
    %         if case_name == "physical_case"
    %             cmd = cmd + "dt0=" + string(Dt0_phys) + "; ";
    %             cmd = cmd + "t_final=" + string(Tf_phys_val) + "; ";
    %             cmd = cmd + "Nx_list=[" + string(Nx_phys_str) + "]; ";
    %             cmd = cmd + "lam_Newton=" + string(lambda_scalar_val) + "; ";
    %             cmd = cmd + "dt_list=[]; ";
    %             cmd = cmd + "lambda_list=[]; ";
    %         else  % numerical_validation
    %             cmd = cmd + "dt0=" + string(Dt0_val) + "; ";
    %             cmd = cmd + "t_final=" + string(Tf_val) + "; ";
    %             cmd = cmd + "Nx_list=[" + string(Nx_list_str) + "]; ";
    %             cmd = cmd + "dt_list=[" + string(Dt0_val) + "]; ";
    %             cmd = cmd + "lambda_list=[" + string(lambda_vec_str) + "]; ";
    %             cmd = cmd + "lam_Newton=[]; ";
    %         end
    % 
    %         cmd = cmd + "run('" + string(mainScriptEsc) + "');";
    %     end
    % 
    %     try
    %         if runPhysical
    %             appendLog('--- Running physical_case ---');
    %             evalin('base', build_cmd("physical_case"));
    %             appendLog(' physical_case finished.');
    %         end
    % 
    %         if runValidation
    %             appendLog('--- Running numerical_validation ---');
    %             evalin('base', build_cmd("numerical_validation"));
    %             appendLog(' numerical_validation finished.');
    %         end
    % 
    %         appendLog('RUN finished ');
    %         appendLog('============================================');
    % 
    %         if isvalid(bView), bView.Enable = 'on'; end
    % 
    %         sumArea.Value = { ...
    %             '--- SIMULATION SUMMARY (NEWTON) ---'; ...
    %             sprintf('Mode: %s', vertisol_mode); ...
    %             '---'; ...
    %             sprintf('Physical: %s', ternary(runPhysical, ...
    %                 sprintf('dt=%.6g h | t_final=%.6g h | Nx=%s | λ=%.6g', Dt0_phys, Tf_phys_val, Nx_phys_str, lambda_scalar_val), ...
    %                 'not run')); ...
    %             sprintf('Validation: %s', ternary(runValidation, ...
    %                 sprintf('dt=%.6g h | t_final=%.6g h | Nx=[%s] | λ=[%s]', Dt0_val, Tf_val, Nx_list_str, lambda_vec_str), ...
    %                 'not run')); ...
    %             '---'; ...
    %             sprintf('Completed: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS')) ...
    %         };
    % 
    %         stop_live_monitor();
    % 
    %     catch ME
    %         uialert(fig, getReport(ME, 'extended', 'hyperlinks', 'off'), 'Run error');
    %         appendLog(['Run error: ' ME.message]);
    %         stop_live_monitor();
    %     end
    % end
    % ========================= RUN =============================
    function onRun(~, ~)
        runPhysical   = cbPhysical.Value;
        runValidation = cbValidation.Value;

        if ~runPhysical && ~runValidation
            uialert(fig, 'Select at least one case (Physical and/or Validation).', 'Input error');
            return;
        end

        [physOK, ~]  = validateNxPhysical();
        [valNxOK, ~] = validateNxList();
        [lambdaVecOK, ~] = validateLambdaVec();
        lambdaScalOK = validateLambdaScalar();

        tfValOK   = isfinite(edTf.Value)      && edTf.Value      > 0;
        dtValOK   = isfinite(edDt0.Value)     && edDt0.Value     > 0;
        tfPhysOK  = isfinite(edTfPhys.Value)  && edTfPhys.Value  > 0;
        dtPhysOK  = isfinite(edDt0Phys.Value) && edDt0Phys.Value > 0;

        if (runPhysical && (~physOK || ~lambdaScalOK || ~tfPhysOK || ~dtPhysOK)) || ...
           (runValidation && (~valNxOK || ~lambdaVecOK || ~tfValOK || ~dtValOK))
            uialert(fig, 'Please fix validation errors before running.', 'Validation Error');
            return;
        end

        vertisol_mode = ddMode.Value;

        Nx_phys_str = strtrim(edNxPhys.Value);
        Nx_list_str = strtrim(edNxListVal.Value);
        
        % Convert string to numeric array
        Nx_list_num = str2num(Nx_list_str);
        if isempty(Nx_list_num)
            uialert(fig, 'Invalid Nx list format.', 'Error');
            return;
        end

        Tf_phys_val = edTfPhys.Value;
        Dt0_phys    = edDt0Phys.Value;

        Tf_val      = edTf.Value;
        Dt0_val     = edDt0.Value;

        lambda_vec_str = strtrim(edLambdaVec.Value);
        lambda_vec_num = str2num(lambda_vec_str);
        if isempty(lambda_vec_num)
            uialert(fig, 'Invalid lambda vector format.', 'Error');
            return;
        end
        
        lambda_scalar_val = edLambdaScalar.Value;

        mainScriptEsc = strrep(mainScript, '''', '''''');

        if isvalid(bView), bView.Enable = 'off'; end

        start_live_monitor();

        appendLog('============================================');
        appendLog(['RUN started: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);
        appendLog(['Cases: ' ternary(runPhysical, 'Physical ', '') ternary(runValidation, 'Validation', '')]);
        appendLog(['Mode:  ' char(vertisol_mode)]);

        if runPhysical
            appendLog(sprintf('Physical: dt=%.6g h | t_final=%.6g h | Nx=%s | λ=%.6g', ...
                Dt0_phys, Tf_phys_val, Nx_phys_str, lambda_scalar_val));
        end
        if runValidation
            appendLog(sprintf('Validation: dt=%.6g h | t_final=%.6g h | Nx=[%s] | λ=[%s]', ...
                Dt0_val, Tf_val, Nx_list_str, lambda_vec_str));
        end

        function cmd = build_cmd(case_name)
            % Base command - clear all variables that might interfere
            cmd = "clear; ";
            
            % Common parameters
            cmd = cmd + "case_type='" + string(case_name) + "'; ";
            cmd = cmd + "vertisol_mode='" + string(vertisol_mode) + "'; ";
            
            % Set test parameters based on case type
            if case_name == "physical_case"
                cmd = cmd + "test_id=3; ";
                cmd = cmd + "test_cond=3; ";
                cmd = cmd + "save_interval=1; ";
            else
                cmd = cmd + "test_id=1; ";
                cmd = cmd + "test_cond=1; ";
                cmd = cmd + "save_interval=0.2; ";
            end
            
            cmd = cmd + "eps1=1e-8; ";
            cmd = cmd + "ell=3; ";
            cmd = cmd + "iso=-0.001; ";

            if case_name == "physical_case"
                cmd = cmd + "dt0=" + string(Dt0_phys) + "; ";
                cmd = cmd + "t_final=" + string(Tf_phys_val) + "; ";
                cmd = cmd + "Nx_list=[" + string(Nx_phys_str) + "]; ";
                cmd = cmd + "lam_Newton=" + string(lambda_scalar_val) + "; ";
                cmd = cmd + "dt_list=[]; ";
                cmd = cmd + "lambda_list=[]; ";
            else  % numerical_validation
                cmd = cmd + "dt0=" + string(Dt0_val) + "; ";
                cmd = cmd + "t_final=" + string(Tf_val) + "; ";
                cmd = cmd + "Nx_list=[" + string(Nx_list_str) + "]; ";
                cmd = cmd + "dt_list=[" + string(Dt0_val) + "]; ";
                cmd = cmd + "lambda_list=[" + string(lambda_vec_str) + "]; ";
                cmd = cmd + "lam_Newton=[]; ";
            end

            cmd = cmd + "run('" + string(mainScriptEsc) + "');";
        end

        try
            if runPhysical
                appendLog('--- Running physical_case ---');
                evalin('base', build_cmd("physical_case"));
                appendLog(' physical_case finished.');
            end

            if runValidation
                appendLog('--- Running numerical_validation ---');
                evalin('base', build_cmd("numerical_validation"));
                appendLog(' numerical_validation finished.');
            end

            appendLog('RUN finished ');
            appendLog('============================================');

            if isvalid(bView), bView.Enable = 'on'; end

            sumArea.Value = { ...
                '--- SIMULATION SUMMARY (NEWTON) ---'; ...
                sprintf('Mode: %s', vertisol_mode); ...
                '---'; ...
                sprintf('Physical: %s', ternary(runPhysical, ...
                    sprintf('dt=%.6g h | t_final=%.6g h | Nx=%s | λ=%.6g', Dt0_phys, Tf_phys_val, Nx_phys_str, lambda_scalar_val), ...
                    'not run')); ...
                sprintf('Validation: %s', ternary(runValidation, ...
                    sprintf('dt=%.6g h | t_final=%.6g h | Nx=[%s] | λ=[%s]', Dt0_val, Tf_val, Nx_list_str, lambda_vec_str), ...
                    'not run')); ...
                '---'; ...
                sprintf('Completed: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS')) ...
            };

            stop_live_monitor();

        catch ME
            uialert(fig, getReport(ME, 'extended', 'hyperlinks', 'off'), 'Run error');
            appendLog(['Run error: ' ME.message]);
            stop_live_monitor();
        end
    end
    function out = ternary(cond, a, b)
        if cond, out = a; else, out = b; end
    end

    % ===================== PANEL HELPER =====================
    function pan = makePanel(parentLayout, rowIndex, titleText, fgColor, bgColor, borderColor)
        outer = uipanel(parentLayout);
        outer.Layout.Row = rowIndex;
        outer.BackgroundColor = bgColor;
        outer.BorderType = 'line';
        outer.Title = '';

        wrapper = uigridlayout(outer, [2 1]);
        wrapper.RowHeight = {26, '1x'};
        wrapper.Padding = [0 0 0 0];
        wrapper.RowSpacing = 0;

        titleRow = uigridlayout(wrapper, [2 1]);
        titleRow.RowHeight = {20, 3};
        titleRow.Padding = [12 2 12 2];
        titleRow.RowSpacing = 0;

        uilabel(titleRow, 'Text', titleText, ...
            'FontWeight', 'bold', 'FontSize', 12, 'FontColor', fgColor);

        rule = uilabel(titleRow, 'Text', '');
        rule.BackgroundColor = borderColor;

        pan = uipanel(wrapper);
        pan.Layout.Row = 2;
        pan.BackgroundColor = bgColor;
        pan.BorderType = 'none';
    end

    % Initial update
    update_monitor_positions();
end

function [p, tmesh, u, tm, file_path] = charger_donnees_temps(output_folder, nx, temps)
    p = []; tmesh = []; u = []; tm = []; file_path = '';

    if nargin < 2, nx = []; end
    if nargin < 3, temps = []; end

    if exist(output_folder,'dir') ~= 7
        fprintf(' Directory does not exist: %s\n', output_folder);
        return;
    end

    files = dir(fullfile(output_folder,'solution_nx*_t*s.mat'));
    if isempty(files)
        fprintf(' No solution_nx*_t*s.mat files in: %s\n', output_folder);
        return;
    end

    NX = nan(numel(files),1);
    TT = nan(numel(files),1);

    for i=1:numel(files)
        name = files(i).name;

        tokNx = regexp(name,'solution_nx(\d+)_','tokens','once');
        tokT  = regexp(name,'_t([^s]+)s\.mat$','tokens','once');

        if ~isempty(tokNx), NX(i) = str2double(tokNx{1}); end
        if ~isempty(tokT),  TT(i) = str2double(tokT{1});  end
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

function show_cut_from_file(sol_dir, nx, t, cut_mode, cut_val)
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
            xlabel('y','FontSize',11,'FontWeight','bold');
            ylabel('z','FontSize',11,'FontWeight','bold');
            ttl = sprintf('Cut x=%.2f', cut_val);

        case 3
            [~,iy] = min(abs(Yg(:,1,1) - cut_val));
            Xc = squeeze(Xg(iy,:,:)); Zc = squeeze(Zg(iy,:,:)); Uc = squeeze(Ug(iy,:,:));
            contourf(Xc,Zc,Uc,20,'LineStyle','none');
            xlabel('x','FontSize',24,'FontWeight','bold');
            ylabel('z','FontSize',24,'FontWeight','bold');
            ttl = sprintf('Cut y=%.2f', cut_val);

        otherwise
            fprintf('Invalid cut_mode.\n');
            return;
    end

    ax = gca;
    ax.FontSize   = 22;
    ax.LineWidth  = 1.5;
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

function update_monitor_positions()
    % This function is called during resize - defined in the main function scope
    % The implementation is handled within run_all_cases_gui
end