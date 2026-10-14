# Interior Ballistics Multi-Objective Optimization

**MATLAB implementation** · [中文说明](README.md)

> Companion code for the bachelor dissertation **“Development and Practice of Ballistic
> Design Software”** (弹道设计软件开发及实践) by **Bin Zhang (彰彬)**, School of Energy and
> Power Engineering, Nanjing University of Science and Technology, May 2025.
> Supervised by Prof. Xiaobing Zhang and Prof. Baokui Geng.

---

## Overview

Classical interior ballistics design faces an inherent conflict: raising the muzzle
velocity requires a heavier charge, which in turn raises the peak chamber pressure.
The traditional empirical route fixes the charge utilisation coefficient $\eta$ and then
back-solves the propellant web thickness $e_1$, so it cannot trade off velocity, pressure
and charge economy in a multi-parameter space.

This project addresses that conflict with three building blocks:

1. **Dynamic parameter encapsulation** — `ballistic_design(e1, eta)` centralises the gun
   geometry, propellant properties and loading conditions into one structure, decoupling
   *grain shape / loading condition / ballistic model* and providing a standard input for
   the optimiser.
2. **Conventional design by bisection** — exploits the near-monotonic relation between web
   thickness and peak pressure to solve $p_{\max}(e_1) = p_m$ within **±1 kPa**.
3. **Multi-objective genetic algorithm** — `gamultiobj` over $(\eta, e_1)$ produces the
   **Pareto non-dominated set** for *maximise muzzle velocity* vs *minimise peak pressure*,
   with a **dynamic penalty function** handling the pressure constraint.

The method is validated on two guns with different calibres and tactical requirements:
a **57 mm anti-aircraft gun** and a **152 mm howitzer**.

---

## Key results

Muzzle velocity varies by less than 0.1 % while the peak chamber pressure drops noticeably:

| Case | Peak pressure (conventional) | Peak pressure (optimised) | Change |
| :--- | ---: | ---: | ---: |
| 57 mm AA gun | 312.9 MPa | 306.3 MPa | **−2.12 %** |
| 152 mm howitzer | 235.8 MPa | 230.8 MPa | **−2.12 %** |

See [`docs/results.md`](docs/results.md) for the full data tables and curves.

---

## Repository layout

```
interior-ballistics-optimization/
├── src/                         ★ final implementation (used in the dissertation)
│   ├── main.m                       entry point: bisection + multi-objective + plots
│   ├── ballistic_design.m           parameter encapsulation module
│   ├── solve_ballistic.m            ODE solver (ode45) with initial conditions
│   ├── ballistic_ode.m              the interior ballistics ODE system
│   ├── binary_search_e1.m           bisection for the propellant web thickness
│   ├── multi_objective_optimization.m   gamultiobj + dynamic penalty function
│   └── analyze_results.m            post-processing and 2×2 comparison plots
├── docs/
│   ├── theory.md                model equations, parameters and algorithms
│   ├── results.md               case parameters, result tables and figures
│   └── figures/                 figures exported from the dissertation (PNG)
└── legacy/                      archived development history
    ├── README.md                notes and differences for every archived version
    ├── 00-prototype-initial/    earliest prototype (initialize_parameters style)
    ├── 01-reference-sample/     reference sample used for comparison
    ├── 02-early-ode-model/      early non-dimensional ODE model
    ├── 03-test-version/         test build (UseParallel = false)
    └── 04-57mm-parameter-variant/  57 mm gun parameter set
```

---

## Requirements

| Item | Requirement |
| :--- | :--- |
| Platform | MATLAB R2018b or later |
| Required toolbox | **Global Optimization Toolbox** (`gamultiobj`, `optimoptions`) |
| Optional toolbox | **Parallel Computing Toolbox** — only needed while `UseParallel = true` is kept |

> Without the Parallel Computing Toolbox, set `'UseParallel', false` in
> `multi_objective_optimization.m` — that is the only change required, and
> `legacy/03-test-version/` already ships with that configuration.

---

## Quick start

```matlab
cd src
main
```

`main.m` performs, in order:

1. `binary_search_e1()` — with $\eta = 1500$ fixed, bisect $e_1$ until the computed peak
   pressure matches the design pressure to within ±1 kPa;
2. `multi_objective_optimization()` — Pareto optimisation over $(\eta, e_1)$ and printing
   of the selected optimum;
3. `analyze_results(...)` — overlay of the conventional (blue) and optimised (red)
   pressure–travel and velocity–travel curves, plus printed travel length, muzzle velocity
   and peak pressure.

---

## Model

The state vector is `y = [psi; Z; l; v; p]` (burned fraction, relative burned thickness,
projectile travel, velocity, pressure) and the system integrated is:

$$
\begin{aligned}
\frac{\mathrm{d}Z}{\mathrm{d}t} &= \frac{u_1}{e_1} p^{n_1}, \quad Z < Z_b \\[2pt]
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

with $\theta = k - 1$. The complete derivation, the eight classical assumptions and the
grain-shape relations are documented in [`docs/theory.md`](docs/theory.md).

---

## Known issues and future work

**Resolved while preparing this repository**

1. **Restored a missing file** — the original “final” folder was missing
   `analyze_results.m`, which `main.m` calls; running it directly failed with an undefined
   function error. The file was recovered from the test build into `src/`.
2. **Disabled the MATLAB automation service** — the original `main.m` started with
   `enableservice('AutomationServer', true)`, needed only when an external program drives
   MATLAB. It is now commented out with an explanatory note; no numerical result changes.

**Recommended follow-ups**

3. **`UseParallel` dependency** — `src/multi_objective_optimization.m` uses
   `UseParallel = true`, which requires the Parallel Computing Toolbox.
4. **Treatment of `l_psi`** — `ballistic_ode.m` evaluates $l_\psi$ from the *initial*
   `psi0` on every step, i.e. treats it as constant, whereas the classical formulation lets
   it vary with $\psi$. Comparing both treatments is worthwhile.
5. **A unit inconsistency in a legacy file** — `legacy/04-57mm-parameter-variant/` uses
   `params.c = 14.5/2` (7.25) while the final version uses `14.5e-3/2` (7.25e-3 m).
   The archived file is untouched; check the unit before reuse.
6. **Extensions** (matching the dissertation outlook): a GUI or structured input files,
   multi-perforated and staged charges, hybrid deep-reinforcement-learning optimisation,
   and multi-disciplinary validation coupling the interior ballistics with barrel
   thermal–mechanical models.

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

> The code and documentation originate from the author's undergraduate final-year project
> and are shared for study and research. The dissertation text itself is **not** included
> in this repository, and the rights to third-party material referenced by the dissertation
> (bibliography, propellant handbooks, etc.) remain with their respective owners.
> The file `legacy/01-reference-sample/` is reference material and is **not** covered by
> the MIT license.
