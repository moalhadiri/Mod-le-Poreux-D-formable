# Richards 3D - Newton Solver for Deformable Porous Media

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020b+-0076A8.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Research](https://img.shields.io/badge/Research-Porous%20Media-1f425f.svg)](https://github.com/)

## Overview

This repository contains a MATLAB implementation of the **Newton solver for the 3D Richards equation in deformable porous media (Vertisol)**. The code solves coupled hydro-mechanical problems in unsaturated deformable porous media using finite element methods.

## Key Features

- **3D finite element solver** for the Richards equation in deformable media.
- **Newton method** with adaptive damping through the parameter `lambda`.
- **Mixed boundary conditions**: Neumann, Dirichlet, and mixed cases.
- **Deformable porous media model** based on Vertisol constitutive laws.
- **Parallel-ready batch simulation framework**.
- **Comprehensive visualization tools** for numerical and physical result analysis.

## Repository Structure

```text
.
├── VALIDATION/                         # Numerical validation cases
│   ├── main_validation.m               # Validation simulation script
│   └── results/                        # Simulation results, auto-generated
│
├── PHYSIQUE/                           # Physical simulation cases
│   ├── main_phy.m                      # Physical simulation script
│   └── results/                        # Simulation results, auto-generated
│
├── src/                                # Source code
│   ├── FEM/                            # Finite element routines
│   ├── models/                         # Physical models: Vertisol, van Genuchten
│   ├── solvers/                        # Newton and iterative solvers
│   └── utils/                          # Utility functions
│
├── examples/                           # Example scripts and exact solutions
│
├── Analyse_differentes_methodes.m      # Visualization tool
├── run_simulations.m                   # Main launcher script
│
└── README.md                           # This file
```

## Requirements

- **MATLAB R2020b or later**
- MATLAB toolboxes:
  - Partial Differential Equation Toolbox
  - Statistics and Machine Learning Toolbox, mainly for visualization

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/richards-3d-newton.git
cd richards-3d-newton
```

Then add all subfolders to the MATLAB path. This is automatically handled by the main scripts.

## Usage

### Quick Start

Run the main launcher from the MATLAB command window:

```matlab
run_simulations
```

### Simulation Modes

| Mode | Description | Script |
|---|---|---|
| Validation | Numerical validation with exact solutions | `main_validation.m` |
| Physical | Realistic physical simulations | `main_phy.m` |
| Both | Run both simulations sequentially | Launcher option 4 |

## Batch Simulation Parameters

| Parameter | Description | Typical values |
|---|---|---|
| `Nx_list` | Mesh resolution | `[9, 17, 33, 65]` |
| `dt` | Time step, in hours | `0.05` to `0.5` |
| `t_final` | Final simulation time, in hours | `1.0` to `8.0` |
| `lambda` | Newton damping parameter | `0.5` to `1.0` |
| `test_cond` | Boundary condition type | `1` Neumann, `2` Dirichlet, `3` Mixed |

## Output Structure

Results are organized in hierarchical folders:

```text
results/
├── numerical_validation/
│   └── Newton/
│       └── lambda_1.00/
│           └── dt_0.0500/
│               ├── resultats_complets/      # Complete simulation data
│               └── solutions_temporelles/   # Time snapshots
│
└── physique/
    └── Newton/
        └── lambda_0.50/
            └── dt_0.2500/
                ├── resultats_complets/
                └── solutions_temporelles/
```

## Visualization

Launch the visualization tool from MATLAB:

```matlab
Analyse_differentes_methodes
```

### Visualization Features

| Feature | Description |
|---|---|
| 3D isosurface | Visualize solution fields at any time |
| Cross-sections | View 2D slices along the `x`, `y`, or `z` axes |
| Convergence analysis | Plot `L2` and `H1` errors versus mesh size |
| Iteration history | Analyze Newton convergence rates |
| Conditioning analysis | Study matrix condition numbers |
| CPU performance | Analyze computation time |
| Field comparison | Compare exact and approximate solutions |

## Examples

### Run a validation simulation

In `main_validation.m`, set for example:

```matlab
Nx_list   = [9, 17, 33];   % Mesh resolutions
dt        = 0.05;          % Time step
t_final   = 1.0;           % Final time
lambda    = 1.0;           % Newton damping
test_cond = 1;             % Neumann boundary condition
```

### Run a physical simulation

In `main_phy.m`, set for example:

```matlab
Nx_list       = [17];          % Single mesh
dt            = 0.25;          % Time step, in hours
t_final       = 8.0;           % 8-hour simulation
lambda        = 0.5;           % Damping parameter
vertisol_mode = 'deformable';  % Deformable soil model
```

### Visualize results

After a simulation, run:

```matlab
Analyse_differentes_methodes
```

Then select:

- Folder: `VALIDATION` or `PHYSIQUE`
- Case: `numerical_validation` or `physique`
- Lambda and `dt` values
- Visualization type: isosurface, cross-section, convergence analysis, etc.

## Error Analysis

The code computes convergence orders. For example, convergence rates are displayed in the MATLAB console as follows:

```matlab
% h = 0.1250 -> h = 0.0625 : L2 = 1.98, H1 = 1.01
% h = 0.0625 -> h = 0.0312 : L2 = 2.01, H1 = 0.99
```

## Citation

If you use this code in your research, please cite:

```bibtex
@software{moelevou_richards_2026,
  author    = {Moelevou, Alhadiri},
  title     = {Richards 3D Newton Solver for Deformable Porous Media},
  year      = {2026},
  publisher = {GitHub},
  url       = {https://github.com/yourusername/richards-3d-newton}
}
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|---|---|
| Source folder not found | Ensure that `run_simulations.m` is in the parent directory containing `VALIDATION/` and `PHYSIQUE/`. |
| Lambda values not detected | Check the folder structure: `results/*/Newton/lambda_*/dt_*`. |
| No error history | Some visualizations require the field `newton_err_history_all` in the saved data. |

### Debug Mode

Enable verbose output by uncommenting `fprintf` statements in:

```text
src/solvers/solveNonLinearNewton.m
src/FEM/kpde3derr_all.m
```

## License

MIT License. See the `LICENSE` file for details.

## Author

**Alhadiri MOELEVOU**  
Université Clermont Auvergne - LIMOS  
Email: [alhadiri.moelevou@uca.fr](mailto:alhadiri.moelevou@uca.fr)

## Acknowledgments

- Laboratoire d'Informatique, de Modélisation et d'Optimisation des Systèmes (LIMOS)
- Université Clermont Auvergne

---

Last updated: April 2026  
Version: 2.0, Newton solver
