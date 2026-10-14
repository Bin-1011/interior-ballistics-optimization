# Interior Ballistics Multi-Objective Optimization

**MATLAB implementation** · [中文说明](README.md)

> Companion code for the bachelor dissertation **“Development and Practice of Ballistic
> Design Software”** (弹道设计软件开发及实践) by **Bin Zhang (彰彬)**, School of Energy and
> Power Engineering, Nanjing University of Science and Technology, May 2025.
> Supervised by Prof. Xiaobing Zhang and Prof. Baokui Geng.

The repository contains a runnable MATLAB program (`src/`) together with its documentation
(`docs/`), covering Chapter 3 (“Construction of the interior ballistics design system”)
and Chapter 4 (“Optimisation practice on interior ballistics schemes”) of the dissertation.

---

## Contents

- [Overview](#overview)
- [Key results](#key-results)
- [Repository layout](#repository-layout)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Modules and algorithm flow](#modules-and-algorithm-flow)
- [Mathematical model](#mathematical-model)
- [Case studies](#case-studies)
- [Known issues and future work](#known-issues-and-future-work)
- [Citation](#citation)
- [License](#license)

---

## Overview

Interior ballistics design contains an inherent conflict: raising the muzzle velocity calls
for a heavier charge, and a heavier charge raises the peak chamber pressure. The classical
empirical route therefore **fixes the charge utilisation coefficient $\eta$ first and then
back-solves the propellant web thickness $e_1$**, so it can only tune a single parameter and
cannot trade off velocity against pressure and charge economy.

This project addresses that limitation with three building blocks:

1. **Dynamic parameter encapsulation** — `ballistic_design(e1, eta)` centralises the gun
   geometry, propellant properties and loading conditions into a single structure, decoupling
   *grain shape / loading condition / ballistic model* and giving the optimiser a standard input.
2. **Conventional design by bisection** — exploits the near-monotonic relation between web
   thickness and peak pressure to drive the computed pressure onto the design pressure within
   **±1 kPa**.
3. **Multi-objective genetic algorithm** — `gamultiobj` over $(\eta, e_1)$ produces the
   **Pareto non-dominated set** for *maximise muzzle velocity* against *minimise peak pressure*,
   with a **dynamic penalty function** handling the pressure constraint.

The method is validated on two guns with different calibres and tactical requirements:
a **57 mm anti-aircraft gun** and a **152 mm howitzer**.

---

## Key results

Muzzle velocity changes by less than 0.1 % while the peak chamber pressure drops noticeably:

| Case | Peak pressure (conventional) | Peak pressure (optimised) | Change |
| :--- | ---: | ---: | ---: |
| 57 mm AA gun | 312.9 MPa | 306.3 MPa | **−2.12 %** |
| 152 mm howitzer | 235.8 MPa | 230.8 MPa | **−2.12 %** |

Both cases show nearly the same pressure reduction, which indicates that the method adapts to
guns of different calibres, loading densities and burning-rate characteristics. Full data are
in [Case studies](#case-studies).

---

## Repository layout

```
interior-ballistics-optimization/
├── README.md                    Chinese documentation
├── README_EN.md                 this file
├── LICENSE                      MIT licence
├── CITATION.cff                 citation metadata
├── src/                         MATLAB sources (the version used in the dissertation)
│   ├── main.m                       entry point: conventional design + optimisation + plots
│   ├── ballistic_design.m           parameter encapsulation module
│   ├── solve_ballistic.m            ODE solver (ode45) with initial conditions
│   ├── ballistic_ode.m              the interior ballistics ODE system
│   ├── binary_search_e1.m           bisection for the propellant web thickness
│   ├── multi_objective_optimization.m   gamultiobj + dynamic penalty function
│   └── analyze_results.m            post-processing and 2×2 comparison plots
└── docs/
    ├── theory.md                model and algorithm notes (equations, symbols, flow)
    ├── results.md               parameters, result tables and curves for both cases
    └── figures/                 dissertation figures (PNG) and flowcharts (PNG + editable SVG)
```

---

## Requirements

| Item | Requirement |
| :--- | :--- |
| Platform | MATLAB (R2018b or later; only long-stable interfaces such as `ode45` and `optimoptions` are used) |
| Required toolbox | **Global Optimization Toolbox** (provides `gamultiobj`) |
| Optional toolbox | **Parallel Computing Toolbox** — only while `UseParallel = true` is kept |

> Without the Parallel Computing Toolbox, set `'UseParallel'` to `false` in
> `multi_objective_optimization.m`. That is the only change required.

---

## Quick start

```matlab
cd src
main
```

`main.m` performs, in order:

1. `binary_search_e1()` — with $\eta = 1500$ fixed, bisect $e_1$ until the computed peak
   pressure matches the design pressure to within ±1 kPa;
2. `multi_objective_optimization()` — Pareto optimisation over $(\eta, e_1)$, then printing of
   the selected optimum;
3. `analyze_results(...)` — overlays the conventional (blue) and optimised (red)
   pressure–travel and velocity–travel curves, and prints travel length, muzzle velocity and
   peak pressure.

---

## Modules and algorithm flow

### `ballistic_design(e1, eta)` — parameter encapsulation

- **Input**: `e1` web thickness (m), `eta` charge utilisation coefficient (kJ/kg)
- **Output**: a `params` structure holding the projectile properties, pressure constraints,
  propellant combustion data, geometric characteristic quantities and derived quantities
- **Notes**
  - the charge mass follows from the utilisation coefficient,
    `omega = m*v_g^2/(2e3*eta)`;
  - the grain-shape quantities `chi / lambda / mu` and the split-point set
    `chi_S / lambda_S`, `Z_b` are derived from the seven-perforation geometry;
  - the loading density `delta` is an input constant, so the chamber volume
    `V0 = omega/delta` follows the charge mass.

![Parameter encapsulation](docs/figures/fig3-01-parameter-encapsulation-flow.png)

### `solve_ballistic(params)` — ODE solution

The state vector is `y = [psi, Z, l, v, p]` (burned fraction, relative burned thickness,
projectile travel, velocity, pressure). Initial values come from `psi0` and `Z0` at the
engraving pressure `p0`; the system is integrated with `ode45` over `t ∈ [0, 0.1] s` using
`MaxStep = 1e-4` and `RelTol = 1e-6` to limit the step size near the pressure peak.

### `binary_search_e1()` — conventional design

Search interval `e1 ∈ [5e-5, 5e-2] m`, target `p_max → p_m`, tolerance `1e3 Pa` (±1 kPa),
at most 100 iterations, with $\eta$ fixed at 1500.

![Bisection search](docs/figures/fig3-02-bisection-search-flow.png)

### `multi_objective_optimization()` — multi-objective optimisation

| Setting | Value |
| :--- | :--- |
| Decision variables | `eta ∈ [1400, 1600]`, `e1 ∈ [5e-5, 5e-3]` m |
| Objective 1 | maximise muzzle velocity `v_muzzle` (implemented as minimise `-v_muzzle/1000`) |
| Objective 2 | minimise peak pressure `p_max` (implemented as minimise `p_max/1e6`) |
| Constraint | `p_max` must stay within ±2 % of `p_m`; the excess is measured in MPa and penalised |
| Algorithm | PopulationSize 100, MaxGenerations 100, CrossoverFraction 0.8, ParetoFraction 0.5 |

The dynamic penalty coefficient `penalty_coeff = 1e3*(1 + 0.5*(violation > 0))` grows with the
violation, which lets the algorithm explore slightly infeasible regions early on and converge
into the feasible band later.

![Multi-objective optimisation](docs/figures/fig3-03-multiobjective-optimization-flow.png)

---

## Mathematical model

The eight classical assumptions, the complete equation set, the symbol table and the algorithm
derivations are documented in [`docs/theory.md`](docs/theory.md). The core system is the
classical multi-perforation interior ballistics model:

$$
\begin{aligned}
\frac{\mathrm{d}Z}{\mathrm{d}t} &= \frac{u_1}{e_1} p^{n_1}, & Z < Z_b \\[2pt]
\frac{\mathrm{d}\psi}{\mathrm{d}t} &=
\begin{cases}
(\chi + 2\lambda\chi Z + 3\mu\chi Z^2)\dfrac{\mathrm{d}Z}{\mathrm{d}t}, & Z < 1 \\[6pt]
\dfrac{\chi_S}{Z_b}\left(1 + \dfrac{2\lambda_S}{Z_b}Z\right)\dfrac{\mathrm{d}Z}{\mathrm{d}t}, & 1 \le Z < Z_b
\end{cases} \\[2pt]
\frac{\mathrm{d}l}{\mathrm{d}t} &= v, \qquad
\frac{\mathrm{d}v}{\mathrm{d}t} = \frac{S p}{\varphi m} \\[2pt]
\frac{\mathrm{d}p}{\mathrm{d}t} &= \frac{1}{S(l + l_\psi)}
\left(f\omega\frac{\mathrm{d}\psi}{\mathrm{d}t}
- \theta\varphi m v\frac{\mathrm{d}v}{\mathrm{d}t} - S p v\right)
\end{aligned}
$$

with $\theta = k - 1$ and $l_\psi$ the reduced free-chamber length.

---

## Case studies

Parameters, result tables and curves for both cases are in [`docs/results.md`](docs/results.md).

### 57 mm anti-aircraft gun

| Conventional pressure–travel | Optimised pressure–travel |
| :---: | :---: |
| ![57mm conventional p-l](docs/figures/fig4-01-57mm-conventional-p-l.png) | ![57mm optimized p-l](docs/figures/fig4-07-57mm-optimized-p-l.png) |

| Pareto front | Pareto solution set |
| :---: | :---: |
| ![57mm pareto front](docs/figures/fig4-05-57mm-pareto-boundary.png) | ![57mm pareto set](docs/figures/fig4-06-57mm-pareto-solutions.png) |

### 152 mm howitzer

| Conventional pressure–travel | Optimised pressure–travel |
| :---: | :---: |
| ![152mm conventional p-l](docs/figures/fig4-11-152mm-conventional-p-l.png) | ![152mm optimized p-l](docs/figures/fig4-17-152mm-optimized-p-l.png) |

| Pareto front | Pareto solution set |
| :---: | :---: |
| ![152mm pareto front](docs/figures/fig4-15-152mm-pareto-boundary.png) | ![152mm pareto set](docs/figures/fig4-16-152mm-pareto-solutions.png) |

> Note: the horizontal axis of the Pareto plots is the **negated** muzzle velocity, because the
> objective is minimised as $-v$. Moving right therefore means lower velocity and lower pressure.

---

## Known issues and future work

**Resolved while preparing this repository**

1. **Restored a missing file** — the original “final” folder was missing `analyze_results.m`,
   which `main.m` calls, so running it directly failed with an undefined-function error.
   The file was recovered from the test build into `src/`.
2. **Disabled the MATLAB automation service** — the original `main.m` began with
   `enableservice('AutomationServer', true)`, needed only when an external program drives
   MATLAB. It is now commented out with an explanatory note; no numerical result changes.

**Recommended follow-ups**

3. **`UseParallel` dependency** — `src/multi_objective_optimization.m` uses
   `UseParallel = true`, which requires the Parallel Computing Toolbox.
4. **Treatment of `l_psi`** — `ballistic_ode.m` evaluates $l_\psi$ from the *initial* `psi0` on
   every step, i.e. treats it as constant, whereas the classical formulation lets it vary with
   $\psi$. Comparing the two treatments is worthwhile.
5. **Two numerical statements in the dissertation** — an arithmetic check of the result tables
   found that the charge-utilisation change reported for the 57 mm case does not match the
   values in the same row (see section 4 of [`docs/results.md`](docs/results.md)).
6. **Extensions** (matching the dissertation outlook): a GUI or structured input files,
   multi-perforation and staged charges, hybrid deep-reinforcement-learning optimisation, and
   multi-disciplinary validation coupling the interior ballistics with barrel
   thermal–mechanical models.

**About the 57 mm case**

`src/ballistic_design.m` ships the 152 mm howitzer configuration, matching the final version of
the dissertation. To reproduce the 57 mm case, edit the literals as listed in section 1 of
[`docs/results.md`](docs/results.md); note that the grain half-length `c` must be **7.25e-3 m**
(the dissertation quotes the grain length as 2c = 14.5 mm) and must use the same unit as `e1`,
`D0` and `d0`, otherwise the shape characteristic quantities become badly distorted.

---

## Citation

```bibtex
@thesis{zhang2025ballistic,
  title       = {弹道设计软件开发及实践},
  author      = {彰彬},
  year        = {2025},
  month       = {5},
  institution = {南京理工大学},
  type        = {Bachelor dissertation},
  note        = {Supervised by Prof. Xiaobing Zhang and Prof. Baokui Geng}
}
```

Machine-readable metadata is available in [`CITATION.cff`](CITATION.cff).

---

## License

Released under the [MIT License](LICENSE).

> The code and documentation originate from the author's undergraduate final-year project and
> are shared for study and research. The dissertation text itself is **not** included in this
> repository, and the rights to third-party material referenced by the dissertation remain with
> their respective owners.
