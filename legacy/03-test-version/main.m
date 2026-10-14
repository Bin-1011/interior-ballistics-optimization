%clc;
enableservice('AutomationServer',true);
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