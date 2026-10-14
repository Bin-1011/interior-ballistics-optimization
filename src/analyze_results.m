% =========================================================================
% analyze_results.m — 结果后处理与绘图
%
% 输入：t, y   — solve_ballistic.m 的输出
%       params — 参数结构体，用 y(:,4) >= params.v_g*1.01 判定弹丸出膛
%       color  — 颜色/线型字符串，用于把常规设计与优化设计叠加对比
%                （main.m 中分别传入 'b' 蓝色与 'r' 红色）
% 输出：四联图 —— 压力-行程、压力-时间、速度-时间、速度-行程
%       其中压力-行程与速度-行程使用 hold on 叠加对比；
%       同时在控制台打印行程长、炮口初速与最大膛压。
%
% 说明：该文件在原始"最终"版本目录中缺失（main.m 调用它会报未定义函数），
%       本仓库从测试版本取回，内容与测试版本一致。
% =========================================================================
% function analyze_results(t, y, params)
%     % 提取关键指标
%     lg_index = find(y(:,4) >= params.v_g *1.01, 1) - 1;
%     lg = y(lg_index, 3);
%     v_muzzle = y(lg_index, 4);
%     p_max = max(y(:,5));
% 
%     % 绘制曲线
%     figure;
%     subplot(2,2,1);
%     plot(y(1:lg_index,3), y(1:lg_index,5)/1e6, 'b');
%     title('压力-行程曲线'); xlabel('行程 (m)'); ylabel('压力 (MPa)');
% 
%     subplot(2,2,2);
%     plot(t(1:lg_index,1)*1000, y(1:lg_index,5)/1e6, 'r');
%     title('压力-时间曲线'); xlabel('时间 (ms)'); 
% 
%     subplot(2,2,3);
%     plot(t(1:lg_index,1)*1000, y(1:lg_index,4), 'g');
%     title('速度-时间曲线'); xlabel('时间 (ms)'); ylabel('速度 (m/s)');
% 
%     subplot(2,2,4);
%     plot(y(1:lg_index,3), y(1:lg_index,4), 'm');
%     title('速度-行程曲线'); xlabel('行程 (m)');
% 
%     % 显示关键结果
%     fprintf('行程长\t: %.4f \t dm\n', lg * 10);
%     fprintf('炮口初速\t: %.4f \t m/s\n', v_muzzle);
%     fprintf('最大膛压\t: %.4f \t MPa\n', p_max/1e6);
% end
function analyze_results(t, y, params, color)
    % 提取关键指标
    lg_index = find(y(:,4) >= params.v_g *1.01, 1) - 1;
    lg = y(lg_index, 3);
    v_muzzle = y(lg_index, 4);
    p_max = max(y(:,5));
    
    % 绘制压力-行程曲线（统一到第一个子图）
    subplot(2,2,1);
    plot(y(1:lg_index,3), y(1:lg_index,5)/1e6, color, 'LineWidth', 1.5);
    title('压力-行程曲线对比'); 
    xlabel('行程 (m)'); ylabel('压力 (MPa)');
    hold on; % 保持图形叠加
    
    % 绘制速度-行程曲线（统一到第四个子图）
    subplot(2,2,4);
    plot(y(1:lg_index,3), y(1:lg_index,4), color, 'LineWidth', 1.5);
    title('速度-行程曲线对比'); 
    xlabel('行程 (m)'); ylabel('速度 (m/s)');
    hold on;
    
    % 其他曲线保持独立显示
    subplot(2,2,2);
    plot(t(1:lg_index,1)*1000, y(1:lg_index,5)/1e6, color);
    title('压力-时间曲线'); xlabel('时间 (ms)'); 
    
    subplot(2,2,3);
    plot(t(1:lg_index,1)*1000, y(1:lg_index,4), color);
    title('速度-时间曲线'); xlabel('时间 (ms)');
    
    % 显示关键结果
    fprintf('[%s] 行程长: %.4f dm\n', color, lg*10);
    fprintf('[%s] 炮口初速: %.4f m/s\n', color, v_muzzle);
    fprintf('[%s] 最大膛压: %.4f MPa\n\n', color, p_max/1e6);
end