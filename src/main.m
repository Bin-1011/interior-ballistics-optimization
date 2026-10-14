% =========================================================================
% main.m — 内弹道设计入口脚本
%
% 流程：
%   1) 常规设计  ：binary_search_e1() 二分反解满足设计膛压的火药弧厚 e1
%                  （装药利用系数 η 固定为 1500 kJ/kg）
%   2) 多目标优化：multi_objective_optimization() 对 (η, e1) 生成 Pareto 非劣解集
%   3) 结果对比  ：analyze_results() 叠加常规（蓝）与优化（红）的压力/速度曲线
%
% 对应论文《弹道设计软件开发及实践》3.3、3.4 节与第 4 章。
% 依赖 MATLAB + Global Optimization Toolbox；若保留 UseParallel = true，
% 还需 Parallel Computing Toolbox（无该工具箱请改为 false）。
%
% 状态量 y = [psi, Z, l, v, p]：已燃百分比、相对已燃厚度、行程、速度、膛压。
% =========================================================================

%clc;
% 原代码通过下面这条语句开启 MATLAB 自动化服务，供外部程序（GUI）驱动 MATLAB。
% 命令行直接运行 main.m 并不需要，且会开放 COM 自动化接口，故在此停用。
% enableservice('AutomationServer',true);

[t, y, params]= binary_search_e1();


tic
[best_eta, best_e1, fval,pareto_front] = multi_objective_optimization();
fprintf('Best eta: %.4f, Best e1: %.4e\n', best_eta, best_e1);
elapsedTime = toc;
disp(['运行时间: ', num2str(elapsedTime), '秒']);
params2=ballistic_design(best_e1,best_eta);
[t1, y1] = solve_ballistic(params2);


% fprintf('常规设计：已确定装药利用系数1167，求解e1\n');
% analyze_results(t, y, params);
% fprintf('多目标优化设计：改变装药系数和e1\n');
% analyze_results(t1, y1, params2);
analyze_results(t, y, params, 'b'); % 蓝色
analyze_results(t1, y1, params2, 'r'); % 红色