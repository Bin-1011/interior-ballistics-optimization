# 模型与算法说明

本文档整理自学位论文《弹道设计软件开发及实践》第 2、3 章，与 `src/` 中的实现一一对应。

- [1. 基本假设](#1-基本假设)
- [2. 符号表](#2-符号表)
- [3. 参数封装模块](#3-参数封装模块)
- [4. 内弹道方程组](#4-内弹道方程组)
- [5. 初始条件与求解](#5-初始条件与求解)
- [6. 常规设计：二分查找反解火药弧厚](#6-常规设计二分查找反解火药弧厚)
- [7. 多目标优化](#7-多目标优化)
- [8. 实现说明与注意点](#8-实现说明与注意点)

---

## 1. 基本假设

方程组基于以下经典内弹道假设：

1. 火药燃烧遵循**几何燃烧定律**；
2. 药粒均在**平均压力**下燃烧，且遵循燃速定律；
3. 内膛表面热散失用减小火药力或增大比热比的方式间接修正；
4. 用次要功计算系数 $\varphi$ 考虑其他次要功；
5. 弹带挤进膛线**瞬时完成**，以挤进压力 $p_0$ 作为弹丸启动条件；
6. 火药燃气服从**诺贝尔—阿贝尔状态方程**；
7. 单位质量火药燃烧放出的能量与生成的燃气温度均为定值，膨胀做功过程中
   燃气组分变化不计，故火药力 $f$、余容 $\alpha$、比热比 $k$ 视为常数；
8. 弹带挤入膛线后密闭良好，**不存在漏气**。

---

## 2. 符号表

| 符号 | 代码字段 | 含义 | 单位 |
| :--- | :--- | :--- | :--- |
| $d$ | `diameter` | 火炮口径 | m |
| $m$ | `m` | 弹丸质量 | kg |
| $v_g$ | `v_g` | 设计初速 | m/s |
| $p_{mT}$ | `P_mT` | 最大膛压设计值（代码以 MPa 存放） | MPa |
| $\chi_k$ | `chi_k` | 药室扩大系数 | — |
| $\Delta$ | `delta` | 装填密度 | kg/m³ |
| $\lambda_g$ | `lambda_g` | 弹丸相对行程长 | — |
| $\varphi_1$ | `phi1` | 阻力系数 | — |
| $\eta$ | `eta` | 装药利用系数 | kJ/kg |
| $\omega$ | `omega` | 装药质量 | kg |
| $\varphi$ | `phi` | 次要功计算系数 | — |
| $p_m$ | `p_m` | 弹道设计压力（平均压力） | Pa |
| $f$ | `f` | 火药力 | J/kg |
| $k$ | `k` | 比热比 | — |
| $\alpha$ | `alpha` | 余容 | m³/kg |
| $\rho_p$ | `rho_p` | 火药密度 | kg/m³ |
| $u_1$ | `u1` | 燃速系数 | (m/s)/Pa$^{n_1}$ |
| $n_1$ | `n1` | 燃速指数 | — |
| $c$ | `c` | 药粒半长 | m |
| $\eta_s$ | `eta_s` | 膛线深度特征量 | — |
| $V_0$ | `V0` | 药室容积 | m³ |
| $S$ | `S` | 身管（炮膛）横断面积 | m² |
| $p_0$ | `p0` | 挤进压力 | Pa |
| $l_0$ | `l0` | 等效圆柱体长度 | m |
| $e_1$ | `e1` | 火药弧厚（决策变量） | m |
| $\psi$ | `y(:,1)` | 已燃火药体积百分比 | — |
| $Z$ | `y(:,2)` | 相对已燃厚度 | — |
| $l$ | `y(:,3)` | 弹丸行程 | m |
| $v$ | `y(:,4)` | 弹丸速度 | m/s |
| $p$ | `y(:,5)` | 膛内平均压力 | Pa |

---

## 3. 参数封装模块

实现：`src/ballistic_design.m`（对应论文 3.3.1 节）

![参数封装模块流程](figures/fig3-01-parameter-encapsulation-flow.png)

### 3.1 起始参量与装填量

装药利用系数与相对装药量成反比，故以 $\eta$（而非相对装药量）作为设计变量，
在现有火炮中其变化范围小得多，便于给定优化区间：

$$
\omega = \frac{m\,v_g^{2}}{2\times 10^{3}\,\eta}
$$

$$
\lambda_1 = \frac{1}{2}\cdot\frac{\dfrac{1}{\chi_k} + \lambda_g}{1 + \lambda_g},
\qquad
\lambda_2 = \frac{1}{3}\cdot\frac{\dfrac{1}{\chi_k} + \lambda_g}{1 + \lambda_g}
$$

$$
\varphi = \varphi_1 + \lambda_2\frac{\omega}{m}
$$

$$
p_m = \frac{1.065\,\varphi\,p_{mT}}{1 + \lambda_1\dfrac{\omega}{m}}
$$

> 单位约定：代码中 `P_mT` 以 **MPa** 存入（如 152 mm 案例为 220），
> 计算 `p_m` 时整体乘以 $10^{6}$ 转为 Pa。

### 3.2 药室与身管几何

$$
V_0 = \frac{\omega}{\Delta},\qquad
S = \eta_s\,d^{2},\qquad
l_0 = \frac{V_0}{S},\qquad
l_{V0} = \frac{l_0}{\chi_k}
$$

### 3.3 七孔火药几何特征量

以弧厚 $e_1$、内孔直径 $d_0$ 表示药粒外径 $D_0$，进而导出形状特征量
$\chi,\lambda,\mu$ 与碎粒阶段特征量：

$$
D_0 = 8e_1 + 3d_0,\qquad \beta = \frac{e_1}{c}
$$

$$
\Pi_1 = \frac{D_0 + 7d_0}{2c},\qquad
Q_1 = \frac{D_0^{2} - n\,d_0^{2}}{4c^{2}}
$$

$$
\mu = -\frac{(n-1)\beta^{2}}{Q_1 + 2\Pi_1},\qquad
\lambda = \frac{(n-1-2\Pi_1)\beta}{Q_1 + 2\Pi_1},\qquad
\chi = \frac{Q_1 + 2\Pi_1}{Q_1}\,\beta
$$

碎粒（燃烧分裂）阶段：

$$
\rho = 0.2956\,(r + e_1),\quad r = \frac{d_0}{2}
$$

$$
\psi_S = \chi(1 + \mu + \lambda),\qquad
Z_b = \frac{e_1 + \rho}{e_1}
$$

$$
\chi_S = \frac{1 - \psi_S Z_b^{2}}{Z_b - Z_b^{2}},\qquad
\lambda_S = \frac{\psi_S}{\chi_S} - 1
$$

$Z_b$ 即燃烧分裂点：$Z<1$ 为增面燃烧（主阶段），$1 \le Z < Z_b$ 为碎粒减面燃烧阶段。

### 3.4 输出的数据结构

函数返回结构体 `params`，字段可分为五类：

| 类别 | 典型字段 | 物理意义 |
| :--- | :--- | :--- |
| 弹丸特性 | `m`, `v_g`, `diameter` | 质量、初速、口径 |
| 压力约束 | `P_mT`, `p_m`, `p0` | 最大膛压、设计压力、挤进压力 |
| 火药燃烧参数 | `f`, `u1`, `n1`, `alpha`, `rho_p`, `c` | 能量释放与燃速规律 |
| 几何特征量 | `chi`, `lambda`, `mu`, `chi_S`, `lambda_S`, `Z_b` | 燃烧面积变化特征系数 |
| 动态计算参数 | `omega`, `phi`, `V0`, `S`, `l0`, `delta` | 装药质量、次要功系数、药室几何 |

这种封装把"火药形状 / 装药条件 / 弹道模型"解耦，替换火药类型时只需改动 `n`、`d0` 等少数几处。

---

## 4. 内弹道方程组

实现：`src/ballistic_ode.m`（对应论文式 2.1）

$$
\begin{aligned}
\frac{\mathrm{d}Z}{\mathrm{d}t} &= \frac{u_1}{e_1}\,p^{\,n_1}, & Z < Z_b \\[4pt]
\frac{\mathrm{d}\psi}{\mathrm{d}t} &=
\begin{cases}
\left(\chi + 2\lambda\chi Z + 3\mu\chi Z^{2}\right)\dfrac{\mathrm{d}Z}{\mathrm{d}t}, & Z < 1 \\[8pt]
\dfrac{\chi_S}{Z_b}\left(1 + \dfrac{2\lambda_S}{Z_b}Z\right)\dfrac{\mathrm{d}Z}{\mathrm{d}t}, & 1 \le Z < Z_b
\end{cases} \\[4pt]
\frac{\mathrm{d}l}{\mathrm{d}t} &= v \\[4pt]
\frac{\mathrm{d}v}{\mathrm{d}t} &= \frac{S\,p}{\varphi\,m} \\[4pt]
\frac{\mathrm{d}p}{\mathrm{d}t} &= \frac{1}{S\,(l + l_\psi)}
\left(
f\,\omega\,\frac{\mathrm{d}\psi}{\mathrm{d}t}
- \theta\,\varphi\,m\,v\,\frac{\mathrm{d}v}{\mathrm{d}t}
- S\,p\,v
\right)
\end{aligned}
$$

其中 $\theta = k - 1$，药室自由容积缩径长

$$
l_\psi = l_0\left[1 - \frac{\Delta}{\rho_p} - \Delta\left(\alpha - \frac{1}{\rho_p}\right)\psi_0 + \alpha\,\Delta\,\eta_0\right],
\qquad \eta_0 = 0
$$

状态向量按 `y = [psi; Z; l; v; p]` 排列；$Z$ 到达 $Z_b$ 后 $\mathrm{d}Z/\mathrm{d}t = 0$，
燃烧结束。

---

## 5. 初始条件与求解

实现：`src/solve_ballistic.m`

$$
\psi_0 = \frac{\dfrac{1}{\Delta} - \dfrac{1}{\rho_p}}{\dfrac{f}{p_0} + \left(\alpha - \dfrac{1}{\rho_p}\right)},
\qquad
Z_0 = \frac{\sqrt{1 + \dfrac{4\lambda\psi_0}{\chi}} - 1}{2\lambda}
$$

初值向量 `y0 = [psi0; Z0; 0; 0; p0]`（行程与速度初值为 0，压力初值为挤进压力），
以 `ode45` 在 $t \in [0,\,0.1]$ s 上积分：

```matlab
options = odeset('MaxStep', 1e-4, 'RelTol', 1e-6);
[t, y] = ode45(@(t,y) ballistic_ode(t, y, params), [0, 0.1], y0, options);
```

采用变步长 Runge–Kutta(4,5) 方法，并限制最大步长以保证压力峰附近的精度。

---

## 6. 常规设计：二分查找反解火药弧厚

实现：`src/binary_search_e1.m`（对应论文 3.3.2 节）

![二分查找流程](figures/fig3-02-bisection-search-flow.png)

由"火药弧厚 $e_1$ 与设计膛压 $p_m$ 在一定范围内近似线性"的物理特性，
以二分法求解 $p_{\max}(e_1) = p_m$：

$$
\min_{e_1}\ \left|\,p_{\max}(e_1) - p_m\,\right| < \varepsilon,\qquad \varepsilon = 10^{3}\ \mathrm{Pa}
$$

| 项目 | 取值 |
| :--- | :--- |
| 搜索区间 | $e_1 \in [5\times10^{-5},\,5\times10^{-2}]$ m |
| 收敛容差 | $\varepsilon = 10^{3}$ Pa（±1 kPa） |
| 最大迭代 | 100 次 |
| 固定量 | $\eta = 1500$ kJ/kg |
| 迭代方式 | 取区间中点求解内弹道；$p_{\max} > p_m$ 时抬升下界，否则压低上界 |

论文指出该路线时间复杂度为 $O(\log n)$，典型在 **15–20 次迭代**内收敛；
其局限是依赖单调性假设、且只能反解单一参数，无法协调多目标矛盾。

---

## 7. 多目标优化

实现：`src/multi_objective_optimization.m`（对应论文 3.4 节）

![多目标优化流程](figures/fig3-03-multiobjective-optimization-flow.png)

### 7.1 优化模型

$$
\begin{aligned}
\min_{x} \quad & \mathbf{f}(x) = \left[\,-v_{\text{muzzle}}(x),\ p_{\max}(x)\,\right] \\
\text{s.t.} \quad & x = [\eta,\ e_1] \\
& 1400 \le \eta \le 1600 \\
& 5\times10^{-5} \le e_1 \le 5\times10^{-3}\ \mathrm{m} \\
& (1 - 2\%)\,p_m \le p_{\max} \le (1 + 2\%)\,p_m
\end{aligned}
$$

目标 1 取负号以便统一为最小化问题；目标 2 直接最小化膛压峰值。
代码中进一步把两个目标分别按 $1/1000$ 与 $1/10^{6}$ 归一化，使二者量级可比。

### 7.2 动态惩罚函数

$$
\text{violation} =
\begin{cases}
\dfrac{p_{\max} - p_{\max}^{\text{upper}}}{10^{6}}, & p_{\max} > p_{\max}^{\text{upper}} \\[6pt]
\dfrac{p_{\max}^{\text{lower}} - p_{\max}}{10^{6}}, & p_{\max} < p_{\max}^{\text{lower}} \\[6pt]
0, & \text{otherwise}
\end{cases}
$$

$$
k_{\text{pen}} = 10^{3}\left(1 + 0.5\,\mathbb{1}[\text{violation} > 0]\right)
$$

$$
f_1 = -\frac{v_{\text{muzzle}}}{1000} + k_{\text{pen}}\cdot\text{violation},
\qquad
f_2 = \frac{p_{\max}}{10^{6}} + k_{\text{pen}}\cdot\text{violation}
$$

违规量以 MPa 计、按同一系数加到两个目标上：算法早期允许轻微越界以扩大搜索空间，
后期则严格收敛到约束带内。

### 7.3 遗传算法配置

```matlab
options = optimoptions('gamultiobj', ...
    'PopulationSize',    100, ...              % 种群规模
    'MaxGenerations',    100, ...              % 最大迭代代数
    'CrossoverFraction', 0.8, ...              % 交叉比例
    'ParetoFraction',    0.5, ...              % 非劣解保留比例
    'Display', 'iter', ...
    'PlotFcn', @gaplotpareto, ...
    'UseParallel', true);                      % 需 Parallel Computing Toolbox
```

采用**实数编码**（避免二进制编解码误差）、**线性（算术）交叉**与
**高斯变异**，并以基于 Pareto 支配关系的直接竞争选择算子生成非劣解集。
论文小结给出：可行解比例由初始代 32% 提升到末代约 92%，40 代内生成约 15±2 个非劣解。

### 7.4 Pareto 基本概念

- **Pareto 支配**：$x_1 \succ x_2$ 当且仅当 $x_1$ 在所有目标上不劣于 $x_2$，且至少在一个目标上严格更优；
- **Pareto 最优解**：不存在支配 $x^{*}$ 的其他可行解；
- **Pareto 非支配集 / 前沿**：全部 Pareto 最优解构成的集合，及其在目标空间中的像。

在内弹道问题中，这些非劣解对应"初速—膛压"的权衡曲线，供设计者按战术需求取舍。

---

## 8. 实现说明与注意点

1. **`l_psi` 的取值**：`ballistic_ode.m` 在每个积分步用**初始** $\psi_0$ 计算 $l_\psi$，
   即在积分过程中视为常数。经典公式中 $l_\psi$ 随 $\psi$ 变化，两种处理方式的
   差异值得后续核对（见 README「已知问题与后续工作」）。
2. **`UseParallel`**：`src/multi_objective_optimization.m` 设为 `true`，
   需要 Parallel Computing Toolbox；无该工具箱时改为 `false`。
3. **`params.delta` 与 `omega`**：装填密度作为输入常量，药室容积 $V_0 = \omega/\Delta$
   随装药量联动——因此优化改变 $\eta$ 时药室容积随之变化，这是本模型的建模选择。
4. **变量命名细节**：`solve_ballistic.m` 中的 `l_0` 是**行程初值**（= 0），
   与 `params.l0`（等效圆柱体长度）不是同一个量。
5. **57 mm 案例的参数**：仓库中的 `ballistic_design.m` 是 152 mm 榴弹炮配置。
   若要复现 57 mm 高射炮案例，各字面量见 [results.md](results.md) 第 1 节，
   其中药粒半长 `c` 应取 `7.25e-3` m，须与 `e1`、`D0`、`d0` 保持同一单位（米）。
