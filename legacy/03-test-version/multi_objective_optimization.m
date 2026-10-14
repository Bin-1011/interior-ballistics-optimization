function [best_eta, best_e1, fval,pareto_front] = multi_objective_optimization()
    % 设置多目标优化的选项
    options = optimoptions('gamultiobj', 'PopulationSize', 100, 'MaxGenerations', 100, ...
                           'CrossoverFraction', 0.8, 'ParetoFraction', 0.5, ...
                           'Display', 'iter', 'PlotFcn', @gaplotpareto,'UseParallel',false);

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


    % 提取速度和压力
    speed = -fval(:, 1);  % 速度作为目标1
    pressure = fval(:, 2);  % 压力作为目标2

    % 绘制 Pareto 前沿面
    figure;
    plot(pressure, speed,'bo');
    xlabel('Pressure');  % 横轴标签：压力
    ylabel('Speed');     % 纵轴标签：速度
    title('Pareto Front - Speed vs Pressure');
    grid on;
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
        
    %% 动态惩罚项（重点修改部分）
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
    
    % 如果膛压超过最大值，则给目标函数一个非常大的值
    % if p_max > max_p || p_max < min_p
    %     penalty = 1e6 * (abs(p_max - max_p) + abs(p_max - min_p)); % 动态惩罚
    %     f(1) = -v_muzzle + penalty; % 惩罚目标1
    %     f(2) = p_max + penalty;     % 惩罚目标2
    % else
    %     % 目标1：最大化炮口初速（负值表示最大化）
    %     % 目标2：最小化膛压（正值表示最小化）
    %     f(1) = -v_muzzle;  % 负号表示最大化
    %     f(2) = p_max;      % 最小化膛压
    % end
end
