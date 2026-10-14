# 内弹道多目标优化设计

**Interior Ballistics Multi-Objective Optimization** · MATLAB 实现

> 本仓库是南京理工大学学士学位论文《**弹道设计软件开发及实践**》的配套代码。
> 作者：**彰彬**，能源与动力工程学院 · 武器发射工程专业；
> 指导教师：**张小兵 教授**、**耿宝魁 研究员（校外）**，2025 年 5 月。

仓库提供可直接运行的 MATLAB 程序（`src/`）与配套说明文档（`docs/`），
内容对应论文第 3 章"内弹道设计系统构建"与第 4 章"内弹道方案优化实践"。

---

## 目录

- [项目简介](#项目简介)
- [主要结果](#主要结果)
- [仓库结构](#仓库结构)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [核心模块与算法流程](#核心模块与算法流程)
- [数学模型](#数学模型)
- [案例与结果](#案例与结果)
- [已知问题与后续工作](#已知问题与后续工作)
- [引用](#引用)
- [许可](#许可)

---

## 项目简介

内弹道设计中存在一对固有矛盾：提高初速要靠增加装药量，而装药量增加又会推高膛压峰值。
经典经验设计法的做法是**先凭经验固定装药利用系数 η，再反解火药弧厚 e1**，
因此只能在单一参数上做调整，无法在"初速—膛压—装药经济性"之间做权衡。

本项目针对这一局限，构建了一套通用的内弹道设计方法，包含三个环节：

1. **参数动态封装**——`ballistic_design(e1, eta)` 把火炮构造参数、火药性质与装填条件
   集中计算，使"火药形状 / 装药条件 / 弹道模型"相互解耦，为优化算法提供标准化输入；
2. **常规设计：二分法反解火药弧厚**——利用"火药弧厚—最大膛压"的近似单调关系，
   用二分查找使计算膛压收敛到设计膛压，容差 **±1 kPa**；
3. **多目标优化：实数编码遗传算法**——以装药利用系数 η 与火药弧厚 e1 为决策变量，
   用 `gamultiobj` 生成"初速极大化 / 膛压极小化"的 **Pareto 非劣解集**，
   并以**动态惩罚函数**处理膛压约束。

方法以 **57 mm 高射炮**与 **152 mm 榴弹炮**两组不同口径、不同战术要求的火炮为案例，
对比了常规设计与优化设计的效果。

---

## 主要结果

在炮口初速变化不超过 0.1 % 的前提下，优化方案明显降低了膛压峰值：

| 案例 | 最大膛压（常规设计） | 最大膛压（优化设计） | 降幅 |
| :--- | ---: | ---: | ---: |
| 57 mm 高射炮 | 312.9 MPa | 306.3 MPa | **−2.12 %** |
| 152 mm 榴弹炮 | 235.8 MPa | 230.8 MPa | **−2.12 %** |

两组案例的膛压降幅几乎一致，说明该方法对不同口径、不同装填密度与燃速特性的火炮
都具有适应性。完整数据见 [案例与结果](#案例与结果)。

---

## 仓库结构

```
interior-ballistics-optimization/
├── README.md                    本文件（中文说明）
├── README_EN.md                 English documentation
├── LICENSE                      MIT 许可证
├── CITATION.cff                 引用信息
├── src/                         MATLAB 源码（论文第 3、4 章所用版本）
│   ├── main.m                       入口脚本：常规设计 + 多目标优化 + 绘图对比
│   ├── ballistic_design.m           参数封装模块
│   ├── solve_ballistic.m            内弹道方程组求解器（ode45）
│   ├── ballistic_ode.m              内弹道微分方程组
│   ├── binary_search_e1.m           二分查找反解火药弧厚
│   ├── multi_objective_optimization.m  多目标遗传算法 + 动态惩罚函数
│   └── analyze_results.m            结果后处理与四联图绘制
└── docs/
    ├── theory.md                模型与算法说明（方程组、符号表、算法流程）
    ├── results.md               两组案例的参数、结果数据与曲线
    └── figures/                 论文插图（PNG）与流程图（PNG + 可编辑 SVG 源）
```

---

## 环境要求

| 项目 | 要求 |
| :--- | :--- |
| 平台 | MATLAB（R2018b 及以后版本均可，仅使用 `ode45`、`optimoptions` 等长期稳定接口） |
| 必需工具箱 | **Global Optimization Toolbox**（提供 `gamultiobj`） |
| 可选工具箱 | **Parallel Computing Toolbox**——仅在保留 `UseParallel = true` 时需要 |

> 若没有 Parallel Computing Toolbox，把 `multi_objective_optimization.m` 中的
> `'UseParallel'` 改为 `false` 即可，这是唯一需要改动的地方。

---

## 快速开始

1. 用 MATLAB 打开 `src/` 目录（或在命令行 `cd` 到该目录）；
2. 运行入口脚本：

```matlab
>> main
```

`main.m` 依次完成三件事：

1. `binary_search_e1()`——固定 η = 1500，二分反解满足设计膛压的火药弧厚 e1；
2. `multi_objective_optimization()`——对 (η, e1) 做双目标优化，输出 Pareto 解集与选定的最优解；
3. `analyze_results(...)`——把常规设计（蓝）与优化设计（红）的压力—行程、
   速度—行程曲线叠加在同一张四联图上对比，并打印行程长、炮口初速与最大膛压。

控制台输出形如：

```
完成 e1	: 0.xxxx
最优结果: eta = 15xx.xxxx, e1 = x.xxxxe-04
Best eta: 15xx.xxxx, Best e1: x.xxxxe-04
运行时间: xx.xx秒
[b] 行程长: x.xxxx dm
[b] 炮口初速: xxx.xxxx m/s
[b] 最大膛压: 235.xxxx MPa
[r] 行程长: ...
[r] 炮口初速: ...
[r] 最大膛压: 230.xxxx MPa
```

---

## 核心模块与算法流程

### `ballistic_design(e1, eta)` — 参数封装模块

- **输入**：`e1` 火药弧厚（m）；`eta` 装药利用系数（kJ/kg）
- **输出**：结构体 `params`，汇总弹丸特性、压力约束、火药燃烧参数、几何特征量与动态计算量
- **要点**
  - 由装药利用系数反算装药质量 `omega = m*v_g^2/(2e3*eta)`；
  - 由七孔火药几何推导形状特征量 `chi / lambda / mu`，以及碎粒阶段的
    `chi_S / lambda_S` 与燃烧分裂点 `Z_b`；
  - 装填密度 `delta` 作为输入常量，药室容积 `V0 = omega/delta` 随装药量联动。

![参数封装模块流程](docs/figures/fig3-01-parameter-encapsulation-flow.png)

### `solve_ballistic(params)` — 方程组求解

状态量 `y = [psi, Z, l, v, p]`（已燃百分比、相对已燃厚度、行程、速度、膛压）。
初值由挤进压力 `p0` 对应的 `psi0`、`Z0` 给出，用 `ode45` 在 `t ∈ [0, 0.1] s` 上积分，
`MaxStep = 1e-4`、`RelTol = 1e-6`，以限制压力峰值附近的步长。

### `binary_search_e1()` — 常规设计

搜索区间 `e1 ∈ [5e-5, 5e-2] m`，目标 `p_max → p_m`，容差 `1e3 Pa`（±1 kPa），
最大迭代 100 次，η 固定为 1500。这是论文"常规设计"路线的实现。

![二分查找流程](docs/figures/fig3-02-bisection-search-flow.png)

### `multi_objective_optimization()` — 多目标优化

| 设置 | 取值 |
| :--- | :--- |
| 决策变量 | `eta ∈ [1400, 1600]`、`e1 ∈ [5e-5, 5e-3]` m |
| 目标 1 | 最大化炮口初速 `v_muzzle`（实现为最小化 `-v_muzzle/1000`） |
| 目标 2 | 最小化最大膛压 `p_max`（实现为最小化 `p_max/1e6`） |
| 约束 | `p_max` 落在 `p_m` 的 ±2 % 带内，越界量按 MPa 计入动态惩罚 |
| 算法参数 | PopulationSize 100，MaxGenerations 100，CrossoverFraction 0.8，ParetoFraction 0.5 |

动态惩罚系数 `penalty_coeff = 1e3*(1 + 0.5*(violation > 0))` 会随越界程度加重，
使算法在早期允许轻微越界以扩大搜索范围，在后期收敛到可行域内。

![多目标优化流程](docs/figures/fig3-03-multiobjective-optimization-flow.png)

---

## 数学模型

模型的八条基本假设、完整方程组、符号表与算法推导见 **[docs/theory.md](docs/theory.md)**。
核心是以下多孔火药经典内弹道方程组：

$$
\begin{aligned}
\frac{\mathrm{d}Z}{\mathrm{d}t} &= \frac{u_1}{e_1} p^{n_1}, & Z < Z_b \\[2pt]
\frac{\mathrm{d}\psi}{\mathrm{d}t} &=
\begin{cases}
(\chi + 2\lambda\chi Z + 3\mu\chi Z^2)\,\dfrac{\mathrm{d}Z}{\mathrm{d}t}, & Z < 1 \\[6pt]
\dfrac{\chi_S}{Z_b}\left(1 + \dfrac{2\lambda_S}{Z_b}Z\right)\dfrac{\mathrm{d}Z}{\mathrm{d}t}, & 1 \le Z < Z_b
\end{cases} \\[2pt]
\frac{\mathrm{d}l}{\mathrm{d}t} &= v \\[2pt]
\frac{\mathrm{d}v}{\mathrm{d}t} &= \frac{S\,p}{\varphi m} \\[2pt]
\frac{\mathrm{d}p}{\mathrm{d}t} &= \frac{1}{S\,(l + l_\psi)}
\left(f\omega\frac{\mathrm{d}\psi}{\mathrm{d}t}
- \theta\varphi m v\frac{\mathrm{d}v}{\mathrm{d}t}
- S\,p\,v\right)
\end{aligned}
$$

其中 $\theta = k - 1$，$l_\psi$ 为药室自由容积缩径长。

---

## 案例与结果

两组验证案例的参数、数据表与曲线图见 **[docs/results.md](docs/results.md)**。

### 57 mm 高射炮

| 传统设计 压力—行程 | 优化设计 压力—行程 |
| :---: | :---: |
| ![57mm conventional p-l](docs/figures/fig4-01-57mm-conventional-p-l.png) | ![57mm optimized p-l](docs/figures/fig4-07-57mm-optimized-p-l.png) |

| Pareto 前沿 | Pareto 最优解集 |
| :---: | :---: |
| ![57mm pareto front](docs/figures/fig4-05-57mm-pareto-boundary.png) | ![57mm pareto set](docs/figures/fig4-06-57mm-pareto-solutions.png) |

### 152 mm 榴弹炮

| 传统设计 压力—行程 | 优化设计 压力—行程 |
| :---: | :---: |
| ![152mm conventional p-l](docs/figures/fig4-11-152mm-conventional-p-l.png) | ![152mm optimized p-l](docs/figures/fig4-17-152mm-optimized-p-l.png) |

| Pareto 前沿 | Pareto 最优解集 |
| :---: | :---: |
| ![152mm pareto front](docs/figures/fig4-15-152mm-pareto-boundary.png) | ![152mm pareto set](docs/figures/fig4-16-152mm-pareto-solutions.png) |

> 说明：Pareto 图的横轴为**取负后的炮口初速**（目标函数中初速以 $-v$ 形式参与最小化），
> 因此数值为负；横轴向右表示初速降低、膛压同步下降。

---

## 已知问题与后续工作

**整理过程中处理的问题**

1. **补回缺失文件**——原始"最终"版本目录缺少 `analyze_results.m`，而 `main.m` 会调用它，
   直接运行会报 `未定义函数或变量 'analyze_results'`。已从测试版本中取回放入 `src/`。
2. **停用 MATLAB 自动化服务**——原 `main.m` 首行为 `enableservice('AutomationServer',true)`，
   用于让外部程序（GUI）驱动 MATLAB，命令行运行并不需要，且会开放 COM 自动化接口。
   现已注释并注明原因，不影响任何计算结果。

**建议后续核对**

3. **`UseParallel` 的依赖**——`src/multi_objective_optimization.m` 采用 `UseParallel = true`，
   需要 Parallel Computing Toolbox；没有该工具箱时改为 `false` 即可。
4. **`l_psi` 的取值方式**——`ballistic_ode.m` 在每个积分步都用**初始** `psi0` 计算 `l_psi`，
   即在整个积分过程中视为常数；经典公式中 `l_psi` 随 `psi` 变化。
   建议对比两种处理方式对压力曲线的影响，必要时改为随状态量更新。
5. **论文中的两处数据表述**——整理时对论文表格做了算术校核，发现表 4.10 中 57 mm 案例的
   装药利用系数变化率与表中数值不符（详见 [docs/results.md](docs/results.md) 第 4 节），
   建议核对原始数据。
6. **可扩展方向**（与论文展望一致）：图形界面或规范化输入文件、多孔与分级装药建模、
   深度强化学习等混合智能优化、内弹道与身管热力耦合的多学科验证。

**关于 57 mm 案例**

仓库中的 `src/ballistic_design.m` 是 152 mm 榴弹炮的参数配置（与论文最终版本一致）。
若要复现 57 mm 高射炮案例，请按 [docs/results.md](docs/results.md) 第 1 节的参数表
修改文件中的字面量；其中药粒半长 `c` 取 **7.25e-3 m**（论文表中"药粒长度 2c = 14.5 mm"），
注意保持与 `e1`、`D0`、`d0` 同为米制，否则形状特征量会明显失真。

---

## 引用

如果本项目对你的研究有帮助，请引用配套学位论文：

```bibtex
@thesis{zhang2025ballistic,
  title       = {弹道设计软件开发及实践},
  author      = {彰彬},
  year        = {2025},
  month       = {5},
  institution = {南京理工大学},
  type        = {学士学位论文},
  note        = {指导教师：张小兵 教授、耿宝魁 研究员（校外）}
}
```

机器可读的引用信息见 [CITATION.cff](CITATION.cff)。

---

## 许可

本项目采用 [MIT License](LICENSE) 发布。

> 代码与文档均出自作者的本科毕业设计工作，仅供学习与研究使用。
> 仓库不包含学位论文正文；论文所引用的参考文献、火药手册等第三方资料，
> 其著作权归各自的权利人所有。
