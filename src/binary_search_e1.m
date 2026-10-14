% =========================================================================
% binary_search_e1.m — 常规设计：二分查找反解火药弧厚（论文 3.3.2 节，图 3.2）
%
% 目标：求 e1 使内弹道计算得到的最大膛压 p_max 匹配弹道设计压力 p_m
%         |p_max - p_m| < tolerance = 1e3 Pa   (±1 kPa)
% 区间：e1 ∈ [5e-5, 5e-2] m ；最大迭代 100 次
% 固定：装药利用系数 η = 1500 kJ/kg（由经验预先确定，不参与寻优）
% 输出：t, y   — 收敛时的内弹道解
%       params — 与收敛 e1 对应的参数结构体
%
% 依据"火药弧厚—最大膛压"的近似单调关系：p_max 偏大则抬升下界，偏小则压低上界。
% =========================================================================
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