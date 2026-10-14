function [opt_params, objectives] = optimize_multi()
    params = initialize_parameters();
    
    % 多目标函数定义
    obj_fun = @(x) [calc_velocity(x, params), -calc_pressure(x, params)];
    
    % 多目标遗传算法
    options = optimoptions('gamultiobj', 'ParetoFraction', 0.3);
    [x_opt, objectives] = gamultiobj(obj_fun, 2, [], [], [], [], [3,0.1e-3], [5,0.5e-3], options);
    
    % 提取Pareto解
    opt_params = arrayfun(@(i) set_params(x_opt(i,:), params), 1:size(x_opt,1));
end

function v = calc_velocity(x, params)
    params.omega = x(1);
    params.e1 = x(2);
    [~, y] = solve_ballistic(params);
    v = y(end, 4);
end

function p = calc_pressure(x, params)
    params.omega = x(1);
    params.e1 = x(2);
    [~, y] = solve_ballistic(params);
    p = max(y(:,5));
end