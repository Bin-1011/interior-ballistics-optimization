function opt_params = optimize_single()
    params = initialize_parameters();
    
    % 定义设计变量范围 [omega, e1]
    lb = [3.0, 0.1e-3];   % 下限
    ub = [5.0, 0.5e-3];   % 上限
    
    % 优化目标函数
    obj_fun = @(x) objective_function(x, params);
    
    % 调用遗传算法
    options = optimoptions('ga', 'PopulationSize', 50, 'MaxGenerations', 30);
    [opt_x, ~] = ga(obj_fun, 2, [], [], [], [], lb, ub, [], options);
    
    % 更新最优参数
    opt_params = params;
    opt_params.omega = opt_x(1);
    opt_params.e1 = opt_x(2);
end

function score = objective_function(x, params)
    % 修改待优化参数
    params.omega = x(1);
    params.e1 = x(2);
    params = update_geometric_params(params);
    % 计算弹道
    try
        [~, y] = solve_ballistic(params);
        v_muzzle = y(end, 4);
        p_max = max(y(:,5));
        score = -0.7*v_muzzle + 0.3*(p_max/1e6);  % 加权目标
    catch
        score = Inf;  % 无效解惩罚
    end
end