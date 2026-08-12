% %% 示例：测试全图PCA方法
% 
% % 创建测试数据
% M =256;
% N=256;
% [X, Y] = meshgrid(1:N, 1:M);
% 
% % 物体相位（高频变化）
% object_phase = 0.5 * sin(0.05*X) .* cos(0.05*Y);
% 
% % 背景像差（低频，平滑变化）
% aberration_phase = 0.8 * X/N + 0.5 * Y/M + 0.3 * ((X-N/2)/N).^2 + 0.2 * ((Y-M/2)/M).^2;
% 
% % 合成复振幅
% o_aberration = exp(1i * (object_phase + aberration_phase));
% 
% % 添加一些噪声
% noise_level = 0.1;
% o_aberration_noisy = o_aberration .* (1 + noise_level * (randn(M,N) + 1i*randn(M,N)));
% 
% % 使用全图PCA去像差
% [o_clean, aberration] = PCA_aberration(o_aberration_noisy);

% 
% %% 比较原始像差和提取的像差
% figure('Position', [100, 100, 1200, 400]);
% 
% subplot(1,3,1);
% imagesc(aberration_phase);
% title('真实像差');
% colorbar; colormap(jet);
% axis image;
% 
% subplot(1,3,2);
% imagesc(angle(aberration));
% title('PCA提取的像差');
% colorbar; colormap(jet);
% axis image;
% 
% subplot(1,3,3);
% imagesc(aberration_phase - angle(aberration));
% title('像差提取误差');
% colorbar; colormap(jet);
% axis image;
% 


function [o_clean, aberration] = PCA_aberration(o_aberration, show_results)
% FULLIMAGEPCA_ABERRATION 在整个图像上使用PCA方法去除背景相位像差
%
% 输入：
%   o_aberration : 包含像差的复振幅矩阵
%   show_results : 可选，是否显示结果 (默认为true)
%
% 输出：
%   o_clean : 去除像差后的复振幅
%   aberration : 提取的背景像差相位

if nargin < 2
    show_results = true;
end

[M, N] = size(o_aberration);

phase = angle(o_aberration);
Z = exp(1i * phase);

%% SVD
[U, S, V] = svd(Z);

%提取和拟合第一主成分
% 第一主成分,背景相位
sigma1 = S(1, 1);      % 第一个奇异值
u1 = U(:, 1);         % U的第一列
v1 = V(:, 1);         % V的第一列

% 对u1进行多项式拟合（行方向的相位变化）
phase_u = unwrap(angle(u1));
x_u = (1:length(phase_u))';
p_u = polyfit(x_u, phase_u, 4);      % 二次多项式拟合
phase_u_fit = polyval(p_u, x_u);
u1_fit = exp(1i * phase_u_fit);

% 对v1进行多项式拟合（列方向的相位变化）
phase_v = unwrap(angle(v1));
x_v = (1:length(phase_v))';
p_v = polyfit(x_v, phase_v, 4);      % 二次多项式拟合
phase_v_fit = polyval(p_v, x_v);
v1_fit = exp(1i * phase_v_fit);

%% 4. 重建背景相位
% 直接重建整个图像的背景相位
aberration = sigma1 * (u1_fit * v1_fit');

%% 5. 去除像差
% 从原始复振幅中减去背景相位
o_clean = o_aberration .* conj(aberration);

%% 6. 显示结果
if show_results
    show_fullImage_results(o_aberration, o_clean, aberration, S);
end

end

%% 结果显示函数（增强版）
function show_fullImage_results(o_aberration, o_clean, aberration, S)
    figure('Position', [100, 100, 1400, 700], 'Name', '全图PCA像差去除');
    
    % 原始振幅和相位
    subplot(2, 4, 1);
    imagesc(abs(o_aberration));
    axis image; colorbar; colormap(gray);
    title('原始振幅');
    xlabel('X'); ylabel('Y');
    
    subplot(2, 4, 2);
    imagesc(angle(o_aberration));
    axis image; colorbar; colormap(jet);
    title('原始相位');
    xlabel('X'); ylabel('Y');
    caxis([-pi pi]);
    
    % 提取的像差相位
    subplot(2, 4, 3);
    imagesc(angle(aberration));
    axis image; colorbar; colormap(jet);
    title('提取的背景像差');
    xlabel('X'); ylabel('Y');
    caxis([-pi pi]);
    
    % 奇异值分布
    subplot(2, 4, 4);
    diag_S = diag(S);
    plot(1:min(20, length(diag_S)), diag_S(1:min(20, length(diag_S))), 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
    hold on;
    plot(1, diag_S(1), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    xlabel('奇异值序号');
    ylabel('奇异值大小');
    title('奇异值分布');
    grid on;
    legend('奇异值', 'σ₁', 'Location', 'best');
    
    % 去除像差后振幅和相位
    subplot(2, 4, 5);
    imagesc(abs(o_clean));
    axis image; colorbar; colormap(gray);
    title('去像差后振幅');
    xlabel('X'); ylabel('Y');
    
    subplot(2, 4, 6);
    imagesc(angle(o_clean));
    axis image; colorbar; colormap(jet);
    title('去像差后相位');
    xlabel('X'); ylabel('Y');
    caxis([-pi pi]);
    
    % 相位剖面线对比
    subplot(2, 4, 7);
    hold on;
    
    % 提取中心行
    center_row = floor(size(o_aberration, 1)/2);
    orig_phase_line = angle(o_aberration(center_row, :));
    clean_phase_line = angle(o_clean(center_row, :));
    aberration_line = angle(aberration(center_row, :));
    
    plot(orig_phase_line, 'b-', 'LineWidth', 1.5, 'DisplayName', '原始相位');
    plot(clean_phase_line, 'r-', 'LineWidth', 1.5, 'DisplayName', '去像差后');
    plot(aberration_line, 'g--', 'LineWidth', 1.5, 'DisplayName', '提取的像差');
    
    xlabel('像素位置');
    ylabel('相位值');
    title('中心行相位剖面');
    legend('Location', 'best');
    grid on;
    hold off;
    
    % U和V的第一主成分
    subplot(2, 4, 8);
    hold on;
    plot(angle(aberration(:,1)), 'b-', 'LineWidth', 1.5, 'DisplayName', 'U方向相位');
    plot(angle(aberration(1,:)), 'r-', 'LineWidth', 1.5, 'DisplayName', 'V方向相位');
    xlabel('像素位置');
    ylabel('相位值');
    title('主成分相位分布');
    legend('Location', 'best');
    grid on;
    hold off;
    
    % 控制台输出
    fprintf('输入尺寸: %d × %d\n', size(o_aberration, 1), size(o_aberration, 2));
    fprintf('奇异值σ₁: %.4f\n', S(1,1));
    fprintf('奇异值σ₂: %.4f\n', S(2,2));
    fprintf('σ₁/σ₂比值: %.2f (越大背景越明显)\n', S(1,1)/S(2,2));
end