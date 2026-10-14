% 初始化参数
params = initialize_parameters();

% 单方案仿真
[t, y] = solve_ballistic(params);
analyze_results(t, y, params);

% 单目标优化
% opt_params = optimize_single();
% [t_opt, y_opt] = solve_ballistic(opt_params);
% analyze_results(t_opt, y_opt, opt_params);

% [pareto_params, objectives] = optimize_multi();
% figure;
% scatter(objectives(:,1), -objectives(:,2));
% xlabel('炮口初速 (m/s)'); ylabel('最大膛压 (MPa)');
% title('Pareto前沿');