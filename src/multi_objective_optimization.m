% =========================================================================
% multi_objective_optimization.m — 多目标优化（论文 3.4.2 节，图 3.3）
%
% 决策变量：eta ∈ [1400, 1600] kJ/kg
%           e1  ∈ [5e-5, 5e-3] m
% 目标函数：f1 = -v_muzzle/1000  最大化炮口初速（取负统一为最小化）
%           f2 =  p_max/1e6      最小化最大膛压（归一化到 MPa）
% 约束处理：p_max 需落在弹道设计压力 p_m 的 ±2% 带内；越界时按 MPa 计算违规量，
%           并以动态惩罚系数 penalty_coeff = 1e3*(1 + 0.5*(violation>0))
%           同时加到两个目标上。早期允许轻微越界以扩大搜索，后期收敛到可行域。
% 算法    ：gamultiobj（实数编码 + Pareto 直接竞争选择算子）
%            PopulationSize 100，MaxGenerations 100，
%            CrossoverFraction 0.8，ParetoFraction 0.5
% 输出    ：best_eta, best_e1 — 从 Pareto 解集中取的首个非劣解
%           fval             — 对应的目标函数值
%           pareto_front     — Pareto 非劣解集（决策变量空间）
%
% 依赖：Global Optimization Toolbox；'UseParallel' = true 时还需
%       Parallel Computing Toolbox。若无该工具箱，请将 'UseParallel' 改为 false。
% =========================================================================
function [best_eta, best_e1, fval, pareto_front] = multi_objective_optimization()
    % 设置多目标优化的选项
    options = optimoptions('gamultiobj', 'PopulationSize', 100, 'MaxGenerations', 100, ...
                           'CrossoverFraction', 0.8, 'ParetoFraction', 0.5, ...
                           'Display', 'iter', 'PlotFcn', @gaplotpareto,'UseParallel',true);

    % 定义目标函数
    objective_function = @(x) evaluate_objective(x);

    % 设置决策变量的范围：eta 和 e1
    lb = [1400, 5e-5];  % eta 和 e1 的下界
    ub = [1600, 5e-3];  % eta 和 e1 的上界
    
    % 使用遗传算法进行多目标优化
    [pareto_front, fval] = gamultiobj(objective_function, 2, [], [], [], [], lb, ub, options);
    
    % 输出最优结果
    best_eta = pareto_front(1, 1);
    best_e1 = pareto_front(1, 2);
    fprintf('最优结果: eta = %.4f, e1 = %.4e\n', best_eta, best_e1);


    % % 提取速度和压力
    % speed = -fval(:, 1);  % 速度作为目标1
    % pressure = fval(:, 2);  % 压力作为目标2
    % 
    % % 绘制 Pareto 前沿面
    % figure;
    % plot(pressure, speed,'bo');
    % xlabel('Pressure');  % 横轴标签：压力
    % ylabel('Speed');     % 纵轴标签：速度
    % title('Pareto Front - Speed vs Pressure');
    % grid on;
end

% 目标函数：优化炮口初速（最大化）和膛压（最小化）
function f = evaluate_objective(x)
    eta = x(1);
    e1 = x(2);
    
    % 获取设计参数
    params = ballistic_design(e1, eta);
    [t, y] = solve_ballistic(params);
    
    % 获取炮口初速和最大膛压
    v_muzzle = y(end, 4);
    p_max = max(y(:, 5));
    
    % 设定膛压的最大值
    max_p = params.p_m*1.02;
    min_p = params.p_m * 0.98;
    
    if p_max > max_p
        violation = (p_max - max_p)/1e6;  % 转换为MPa单位
    elseif p_max < min_p
        violation = (min_p - p_max)/1e6;
    else
        violation = 0;
    end
        
    %% 动态惩罚项
    penalty_coeff = 1e3 * (1 + 0.5*(violation>0)); % 基础系数+违反惩罚
    speed_norm = -v_muzzle / 1000;  % 速度归一化
    pressure_norm = p_max / 1e6;    % 压力归一化到MPa
        
    %% 应用惩罚项
    if violation > 0
        f(1) = speed_norm + penalty_coeff*violation; 
        f(2) = pressure_norm + penalty_coeff*violation;
    else
        f(1) = speed_norm;
        f(2) = pressure_norm; 
    end
end
