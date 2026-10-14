%%二分查找符合设计膛压的计算e1
function [t, y, params] = binary_search_e1()
e1_bottom = 5e-5;
e1_top = 5e-2;
tolerance = 1e3;
max_iter = 100;
for iter = 1:max_iter 
    e1 = (e1_top + e1_bottom) / 2;
    params = ballistic_design(e1, 1500);
    [t, y] = solve_ballistic(params);
    p_max = max(y(:,5));
    dp = p_max - params.p_m;
    if abs(dp) < tolerance
        fprintf('完成 e1\t: %.4f\n', e1 * 1e3);
        break;
    elseif dp > 0
        e1_bottom = e1;
    elseif dp < 0
        e1_top = e1;
    end
    % fprintf('%d: e1=%.4f, Pm=%d Pa, 误差：%d \n',iter, e1 * 1e3, p_max, dp);
end

end