# 历史版本归档

本目录按**开发演进顺序**归档建模过程中产生的各个版本，仅作溯源与对比使用。
**可直接运行的最终版本在 [`../src/`](../src/)，请优先使用该目录。**

> 归档文件均**按原样保留**（包括其中的注释掉的代码、废弃写法与已知量纲问题），
> 便于回溯当时的设计思路；如需使用，请先阅读下面的说明。

| 目录 | 阶段 | 说明 |
| :--- | :--- | :--- |
| `00-prototype-initial/` | 最初原型 | 以 `initialize_parameters.m` 集中初始化参数的最早版本 |
| `01-reference-sample/` | 参考样本 | 课程设计/参考资料中的内弹道样本程序 |
| `02-early-ode-model/` | 早期独立实现 | 针对某 59-130 火炮的无量纲化 ODE 模型 |
| `03-test-version/` | 测试版本 | 与最终版功能一致，仅并行与绘图设置不同 |
| `04-57mm-parameter-variant/` | 参数变体 | 57 mm 高射炮的参数配置 |

---

## `00-prototype-initial/` — 最初原型

论文写作早期搭建的框架，核心思路是"**参数初始化 + 求解 + 优化**"三层分离：

```
initialize_parameters.m   参数集中初始化（含几何燃烧参数推导）
ballistic_ode.m           内弹道微分方程组（含大量注释掉的备选写法）
solve_ballistic.m         ode45 求解
analyze_results.m         结果绘图（用的判据是 y(:,3) >= params.lg）
main.m                    入口：单方案仿真
optimize_single.m         单目标遗传算法（ga，加权目标）
optimize_multi.m          多目标遗传算法（gamultiobj）
update_geometric_params.m 当 e1 变化时重算几何参数
```

**与最终版的差异与注意点**

- **量纲问题**：`initialize_parameters.m` 中 `params.c = 7.25`，其上一行被注释掉的
  `%params.c = 7.25e-3;` 才是正确的米制取值。`c` 与 `e1`、`D0`、`d0` 必须同单位，
  否则 `beta = e1/c` 与形状特征量全部失真。最终版已改为 `14.5e-3/2`。
- **压力指数**：此处 `params.n = 0.978` 被注释为"压力指数"，实际在该方程中充当
  燃速压力指数使用，与最终版的 `n1` 对应。
- **单目标优化**：`optimize_single.m` 以 `-0.7*v_muzzle + 0.3*(p_max/1e6)` 加权，
  属于论文 3.4.1 节"单目标优化"的早期尝试，最终版未保留（论文主体采用多目标路线）。
- **多目标优化**：`optimize_multi.m` 的决策变量是 `[omega, e1]`（相对装药量），
  最终版改为 `[eta, e1]`（装药利用系数），与论文 3.2.2 节的说明一致
  （η 的变化范围远小于相对装药量，便于给定搜索区间）。

---

## `01-reference-sample/` — 参考样本

早期学习阶段使用的内弹道样本程序，用于对照验证自编代码：

```
interior_ballistic.m   主脚本：给定 152 mm 炮参数求解并绘图
Runge_kutta_pre.m      微分方程组（通过 global 传递参数）
lphi.m                 药室自由容积缩径长 l_psi 的计算函数
```

**注意**

- 该样本采用 **`global` 变量**传参（`global n e1 m diameter f omega rho_p k alpha u1 p0 V0 c`），
  与最终版的 `params` 结构体传参形成对比——最终版的参数封装正是为了消除这种全局耦合。
- 样本中 `params.lg = 8.59` 用行程长判断出膛，与最终版用"初速达到设计值"的判据不同。
- 该文件为**参考资料**性质，著作权归原作者所有，此处仅作学习对照留存，
  不属于本项目作者的原创实现，也**不包括在 MIT 许可范围内**。

---

## `02-early-ode-model/` — 早期独立实现

针对某 **59-130** 火炮（`A=1.394`、`G=33.4`、`WO=18.56`、`l_g=59.52`）编写的一版
独立实现，采用**无量纲化变量**与 `C` 向量传参：

```
main.m      主脚本：参数计算 → ode45 求解 → 分阶段后处理 → 四联图
ndd_fun.m   微分方程组 function dy=ndd_fun(t,y,C)
```

**特点与差异**

- 状态量为 `[Z, l, v]`（归一化），压力 `p` 由代数式 `p=(psi-v*v)/(1+l_psi)` 反算，
  而非最终版的"把 p 作为状态量直接积分"；
- 方程组用 `dy(1)=sqrt((theta/(2*B))*(p^V)*(Z>=0&Z<=Z_s))` 形式，
  是论文 2.1 节方程组的无量纲化写法；
- 参数经 `C` 向量（12 个分量）传入 `ndd_fun`，是最终版 `params` 结构体的前身。

---

## `03-test-version/` — 测试版本

与 `src/`（最终版）**功能等价**，逐文件比对结果：

| 文件 | 与 `src/` 的关系 |
| :--- | :--- |
| `ballistic_design.m` | 完全相同 |
| `ballistic_ode.m` | 完全相同 |
| `solve_ballistic.m` | 完全相同 |
| `binary_search_e1.m` | 完全相同 |
| `main.m` | 仅差一个末尾空行 |
| `multi_objective_optimization.m` | **有差异**（见下） |
| `analyze_results.m` | **最终版缺失此文件，`src/analyze_results.m` 即取自此处** |

`multi_objective_optimization.m` 的两处差异：

1. `'UseParallel'` 为 **`false`**（最终版为 `true`）——无 Parallel Computing Toolbox
   时可直接用此版本；
2. 保留了**绘制 Pareto 前沿**的代码块（最终版将其注释掉，改用 `'PlotFcn', @gaplotpareto`
   由 `gamultiobj` 实时绘图）。

---

## `04-57mm-parameter-variant/` — 57 mm 高射炮参数版本

仅含 `ballistic_design.m`，是论文第四章 57 mm 高射炮案例的参数配置
（`diameter = 57e-3`、`m = 2.8`、`v_g = 1000`、`P_mT = 303`、`chi_k = 1.9`、
`delta = 0.79e3`、`lambda_g = 6.4`）。使用时将其复制到 `src/` 覆盖同名文件即可。

> ⚠ **量纲问题**：该文件中 `params.c = 14.5/2`（= 7.25），而 `c` 应与 `e1`、`D0`、`d0`
> 同为米制。最终版 152 mm 案例写作 `params.c = 14.5e-3/2`（= 7.25e-3 m）。
> 直接使用本文件前请先确认该取值，否则 `beta = e1/c` 与形状特征量
> $\chi,\lambda,\mu$ 会显著失真。本文件按原样归档，未作修改。

---

## 未归档的文件

原始项目目录中还有两个压缩包 `测试.zip` 与 `ballistic_ode.zip`。经比对，
其内容分别与 `03-test-version/` 和 `00-prototype-initial/` 中的文件重复
（仅 `main.m`、`ballistic_design.m` 等为更早的中间修订），因此未重复归档，
以保持仓库轻量。如需原始压缩包，请查阅本地原始工程目录。
