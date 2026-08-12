function shade_curve(num, iter, psnr_data, total_time)
% 绘制算法稳定性评估图（带运行时间双横坐标轴）
% 输入:
%   num - 初始化次数
%   iter - 迭代次数向量 (例如: 1:100)
%   psnr_data - PSNR数据矩阵，大小为 [迭代次数 × 初始化次数]
%   total_time - 总运行时间（秒）

% 参数验证
if nargin < 4
    error('需要4个输入参数: num, iter, psnr_data, total_time');
end

if length(iter) ~= size(psnr_data, 1)
    error('迭代次数向量的长度必须与psnr_data的行数一致');
end

if num ~= size(psnr_data, 2)
    error('初始化次数num必须与psnr_data的列数一致');
end

% 计算统计量
psnr_mean = mean(psnr_data, 2);  % 按行求均值
psnr_std = std(psnr_data, 0, 2); % 按行求标准差
psnr_min = min(psnr_data, [], 2);
psnr_max = max(psnr_data, [], 2);

% 创建图形
figure('Position', [100, 100, 900, 600]);
hold on;

% 确保所有向量都是行向量
iter_row = iter(:)';
psnr_min_row = psnr_min(:)';
psnr_max_row = psnr_max(:)';

% 指定RGB颜色（0-255范围转换为0-1范围）
% shadow_color = [220, 230, 248] / 255;  % 阴影颜色 RGB(231,242,248)
% line_color = [58, 146, 202] / 255;     % 实线颜色 RGB(58,146,202)
% data_color = [100, 150, 200] / 255;    % 数据点颜色


shadow_color = [0.8, 0.5, 0.4] / 1;  % 浅橙色阴影 RGB(255,230,210)
line_color = [220, 150, 100] / 255;    % 中等饱和橙色 RGB(220,150,100)
data_color = [240, 180, 140] / 255;    % 浅橙色数据点 RGB(240,180,140)



% 绘制所有数据点（浅色散点）
for i = 1:num
    plot(iter, psnr_data(:, i), '-', 'Color', [data_color, 0.9], 'LineWidth', 0.8, ...
         'HandleVisibility', 'off');
end

% 绘制完整范围阴影区域（最小到最大）
fill([iter_row, fliplr(iter_row)], ...
     [psnr_max_row, fliplr(psnr_min_row)], ...
     shadow_color, 'EdgeColor', 'none', 'FaceAlpha', 0.2, ...
     'DisplayName', sprintf('Full range (%d runs)', num));

% 绘制平均曲线 - 使用指定颜色的实线
semilogy(iter, psnr_mean, '--','Color', line_color, 'LineWidth', 2.5, ...
     'DisplayName', 'Average PSNR');

% 设置下横坐标轴（迭代次数）
xlabel('Iteration Number', 'FontSize', 14);
ylabel('Amplitude mean squared error', 'FontSize', 14);

% 去掉网格
set(gca, 'FontSize', 11, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');

% 设置坐标轴范围
xlim([min(iter), max(iter)]);
% ylim([0, 1]); % 固定纵坐标范围为0~1

% % 创建上横坐标轴（运行时间）
ax1 = gca;
ax1.FontSize  =14;
% 
% % 设置上坐标轴 - 修正刻度位置对应问题
% % 计算迭代次数到时间的线性映射
% iter_range = max(iter) - min(iter);
% time_per_iter = total_time / iter_range;
% 
% % 根据总时间确定合适的刻度数量
% if total_time <= 10
%     num_ticks = total_time + 1; % 显示所有整数刻度
% elseif total_time <= 30
%     num_ticks = 7; % 大约每5秒一个刻度
% elseif total_time <= 60
%     num_ticks = 7; % 大约每10秒一个刻度
% elseif total_time <= 120
%     num_ticks = 7; % 大约每20秒一个刻度
% else
%     num_ticks = 5; % 大约每30秒一个刻度
% end
% 
% % 生成均匀分布的时间刻度和对应的迭代次数位置
% time_ticks_values = linspace(0, total_time, num_ticks);
% iter_ticks_positions = min(iter) + (time_ticks_values / time_per_iter);
% 
% % 确保刻度值是整数（对于小的时间范围）
% if total_time <= 10
%     time_ticks_values = 0:total_time;
%     iter_ticks_positions = min(iter) + (time_ticks_values / time_per_iter);
% end
% 
% ax2 = axes('Position', ax1.Position, ...
%            'XAxisLocation', 'top', ...
%            'YAxisLocation', 'right', ...
%            'Color', 'none', ...
%            'XLim', [min(iter), max(iter)], ... % 与主坐标轴相同的X范围
%            'YLim', [0, 1], ... % 同样固定纵坐标范围为0~1
%            'XTick', iter_ticks_positions, ... % 在对应的迭代次数位置显示时间刻度
%            'XTickLabel', arrayfun(@(x) sprintf('%.0f', x), time_ticks_values, 'UniformOutput', false), ...
%            'FontSize', 11, ...
%            'Box', 'on', ...
%            'XColor', 'k', 'YColor', 'k', ...
%            'XGrid', 'off', 'YGrid', 'off', ... % 去掉网格
%            'YTickLabel', []); % 右纵坐标不显示数值
% 
% xlabel(ax2, 'Runtime (s)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
% 
% % 同步两个坐标轴的Y轴范围
% linkaxes([ax1, ax2], 'y');

% 设置主坐标轴为当前坐标轴
% axes(ax1);

xticks([0, 100,200,300,400,500])
% yticks([0, 4,8]*10^6)

hold off;

grid off

end