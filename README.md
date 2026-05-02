# Coupled Richards Equation - Newton Solver for Deformable Porous Media

MATLAB solver for coupled Richards equation in deformable porous media (Vertisol).

## Quick Start

### 1. Run simulations

```matlab
run_simulations
```

The launcher will ask:
- `1` - Run VALIDATION simulation
- `2` - Run PHYSIQUE simulation
- `3` - Run both simulations
- `4` - Visualize only (use this when you already ran simulations and want to see results)

After simulation completes, you will see:
```
Simulation PHYSIQUE completed in 24.95 seconds.
Launch visualization? (y/n) [y]:
```
- Type `y` to open the visualization tool immediately
- Type `n` to exit

### 2. If you exit MATLAB

You can always reopen the visualization tool later using **TWO ways**:

**Way 1 - Using the launcher:**
```matlab
run_simulations
```
Then select option `4` (Visualize only)

**Way 2 - Direct access:**
```matlab
Analyse_differentes_methodes
```

No need to re-run the simulation.

### 3. Results location

After simulation, results are saved in:

```
results/
├── numerical_validation/
│   └── Newton/
│       ├── lambda_0.60/
│       │   └── dt_0.0500/
│       │       ├── resultats_complets/
│       │       │   └── resultats_complets.mat
│       │       └── solutions_temporelles/
│       │           └── solution_nx*.mat
│       └── lambda_1.00/
│           └── dt_0.0500/
│               ├── resultats_complets/
│               └── solutions_temporelles/
│
└── physique/
    └── Newton/
        ├── lambda_0.60/
        │   └── dt_0.0500/
        │       ├── resultats_complets/
        │       └── solutions_temporelles/
        └── lambda_1.00/
            └── dt_0.0500/
                ├── resultats_complets/
                └── solutions_temporelles/
```

Each `lambda_X/` folder contains results for a specific damping parameter value.

### 4. View results table manually

To see the numerical results (errors, CPU time, iterations), navigate to:

```
VALIDATION/results/numerical_validation/Newton/lambda_X/dt_Y/resultats_complets/
```

or

```
PHYSIQUE/results/physique/Newton/lambda_X/dt_Y/resultats_complets/
```

Open the file `resume_resultats.txt` in any text editor. It contains:

```
h       dt        L1          L2          Linf        H1          It.last  It.mean   CPU(s)
1/8     0.0500    1.23e-03    2.34e-03    1.56e-03    4.56e-02    8        6.50      12.34
1/16    0.0500    3.45e-04    5.67e-04    4.12e-04    1.23e-02    10       8.20      45.67
```

The file `resultats_complets.mat` (MATLAB format) contains:
- `Erreur_L1`, `Erreur_L2`, `Erreur_H1`, `Erreur_Linf` - Numerical errors
- `CPU_times` - Computation time per mesh
- `Newton_iters_last`, `Newton_iters_moyenne` - Newton iterations
- `Cond_max`, `Cond_moyen` - Matrix conditioning

### 5. Visualization tool

```matlab
Analyse_differentes_methodes
```

Then navigate through the menus:

```
--- MAIN MENU ---
1. Visualize VALIDATION folder results
2. Visualize PHYSIQUE folder results
3. Exit

Your choice: 2

Available lambda values:
1 - lambda = 0.60
2 - lambda = 1.00
Your choice: 1

Available time steps:
1 - dt = 0.0500
Your choice: 1
```

### Visualization Menu Options

| Option | Description |
|--------|-------------|
| 1 | 3D Isosurface at given time |
| 2 | 2D Cross-section (x, y, or z constant) |
| 3 | Convergence by mesh (single scheme) |
| 4 | Convergence by mesh (all schemes) - Compares different lambda values |
| 5 | Compare schemes (CPU, iterations, errors, conditioning) |
| 0 | Back |

### Example: Compare different lambda values (Option 4)

```
Available meshes (h):
  1 - h = 0.063000 (1/16)
  2 - h = 0.125000 (1/8)

Select mesh numbers to display (e.g., 1 3 5) or "all": all

Y-axis: 1 log10(error) | 2 raw error [1]: 1
```

This generates a figure showing Newton convergence for each lambda value.

### Note on Option 4

Option 4 ("Convergence by mesh (all schemes)") compares different lambda values.
If only one lambda is available, the curve will still display but no comparison is possible.

## Parameters (Edit in main_validation.m or main_phy.m)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `Nx_list` | Mesh resolution vector | `[9, 17, 33]` |
| `dt` | Time step (hours) | `0.05` |
| `t_final` | Final time (hours) | `1.0` |
| `lambda` | Newton damping | `0.5` to `1.0` |
| `test_cond` | Boundary condition | `1` (Neumann), `2` (Dirichlet), `3` (Mixed) |

## Requirements

- MATLAB R2020b or later

## Folder Structure

```
├── VALIDATION/                 # Numerical validation cases
│   ├── main_validation.m       # Validation simulation script
│   └── results/                # Simulation results (auto-generated)
│
├── PHYSIQUE/                   # Physical simulation cases
│   ├── main_phy.m              # Physical simulation script
│   └── results/                # Simulation results (auto-generated)
│
├── src/                        # Source code
│   ├── FEM/                    # Finite element routines
│   ├── models/                 # Physical models (Vertisol, van Genuchten)
│   ├── solvers/                # Newton solvers
│   └── utils/                  # Utility functions
│
├── examples/                   # Example scripts and exact solutions
│
├── Analyse_differentes_methodes.m  # Visualization tool
├── run_simulations.m               # Main launcher
│
└── README.md                   # This file
```

## Author

Alhadiri MOELEVOU - Universite Clermont Auvergne - LIMOS


## License

MIT
