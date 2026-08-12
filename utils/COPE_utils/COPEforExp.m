function [x_est, loss_history, corr_history] = exp_COPE(y, mask, params, options)
% COMPLEX_TV_ADMM_PR ADMM相位恢复算法（含复数全变分约束）
%
% 输入参数：
%   y : 测量强度图像 (sqrt尺度)
%   mask : 掩模（复数）
%   params : 参数结构体，包含：
%       - dist : 传播距离
%       - pxsize : 像素尺寸
%       - wavlen : 波长
%       - cropsize : 裁剪尺寸
%   options : 可选参数结构体，包含：
%       - max_iter : 最大迭代次数 (默认: 1500)
%       - rho1, rho2, rho3 : ADMM惩罚参数 (默认: [1, 1, 1])
%       - gamma : 步长 (默认: 1.18)
%       - tv_lambda : TV正则化参数 (默认: 0.1)
%       - support_radius : 支撑半径 (默认: O2/4)
%       - d_defocus : 离焦距离 (默认: 17.4)
%       - display_iter : 显示间隔 (默认: 10)
%       - cache_size : 缓存大小 (默认: 10)
%
% 输出参数：
%   x_est : 估计的复振幅场
%   loss_history : 损失函数历史
%   corr_history : 相关系数历史

% =========================================================================
% 参数设置
% =========================================================================


if nargin < 4
    options = struct();
end

% 默认参数
defaults = struct(...
    'max_iter', 1500, ...
    'rho1', 1, ...
    'rho2', 1, ...
    'rho3', 1, ...
    'gamma', 1.18, ...
    'tv_lambda', 0.1, ...
    'support_radius', [], ...
    'd_defocus', 17.4, ...
    'display_iter', 10, ...
    'cache_size', 10, ...
    'subiter', 3 ...
);

% 合并参数
option_names = fieldnames(defaults);
for i = 1:length(option_names)
    name = option_names{i};
    if ~isfield(options, name)
        options.(name) = defaults.(name);
    end
end

% 提取参数
max_iter = options.max_iter;
rho1 = options.rho1;
rho2 = options.rho2;
rho3 = options.rho3;
gamma = options.gamma;
tv_lambda = options.tv_lambda;
d_defocus = options.d_defocus;
display_iter = options.display_iter;
cache_size = options.cache_size;
subiter = options.subiter;

% 图像尺寸
[M1, M2] = size(y);
cropsize = params.cropsize;
N1 = M1 + 2*cropsize;
N2 = M2 + 2*cropsize;
O1 = N1;
O2 = N2;

% =========================================================================
% 预计算和函数句柄定义
% =========================================================================
% 传播传输函数
HQ2 = fftshift(transfunc_propagate(N1, N2, params.dist, params.pxsize, params.wavlen));

% 测量算子函数句柄
M = @(x) x .* mask;
MH = @(x) x .* conj(mask);
Q2 = @(x) ifft2(fft2(x) .* HQ2);
Q2H = @(x) ifft2(fft2(x) .* conj(HQ2));
C2 = @(x) imgcrop(x, cropsize);
C2H = @(x) zeropad(x, cropsize);
A = @(x) C2(Q2(M(x)));
AH = @(x) MH(Q2H(C2H(x)));

% 离焦传播算子
Q1 = @(x) propagate(x, -d_defocus, params.pxsize, params.wavlen);
Q1H = @(x) propagate(x, d_defocus, params.pxsize, params.wavlen);

% 支撑约束
support = gpuArray(padarray(ones(M1, M2), [cropsize, cropsize], 0));

% 傅里叶空间支撑
if isempty(options.support_radius)
    support_radius = O2/4;
else
    support_radius = O2*options.support_radius;
end
supportF = gpuArray(aperture(O1, O2, O1/2, O2/2, support_radius));
supportF2 = gpuArray(aperture(O1, O2, O1/2, O2/2, O2/4));

% =========================================================================
% 初始化变量
% =========================================================================
% x = gpuArray(ones(O1, O2, 'single'));  % 主变量ones
x = gpuArray(1*exp(2*pi*rand([N1,N2],'single'))); % 主变量随机
z1 = x;  % 辅助变量1：傅里叶空间约束
z2 = x;  % 辅助变量2：强度约束
z3 = x;  % 辅助变量3：TV约束

u1 = zeros(size(x), 'single');  % 对偶变量1
u2 = zeros(size(x), 'single');  % 对偶变量2
u3 = zeros(size(x), 'single');  % 对偶变量3

% 历史记录
loss_history = zeros(max_iter, 1);
corr_history = zeros(max_iter, 1);

% 缓存用于早停判断
cache_loss = inf(cache_size, 1);

% =========================================================================
% ADMM主循环
% =========================================================================
timer = tic;
for iter = 1:max_iter
    % --- x更新 ---
    x = (rho1 * (z1 - u1) + rho2 * (z2 - u2) + rho3 * (z3 - u3)) / (rho1 + rho2 + rho3);
    x = x .* support;
    
    % --- z1更新：傅里叶空间约束 ---
    % z1 = ifft2(fftshift(supportF .* fftshift(fft2(x + u1))));
    z1 = Q1H(ifft2(fftshift(supportF.*fftshift(fft2(Q1(x + u1))))));
    
    % --- z2更新：强度约束 ---
    z2 = intensity_constraint(x + u2, sqrt(y), A, AH, gamma, subiter);
    
    % --- z3更新：复数TV约束 ---
    z3 = Q1H(complex_TV(Q1(x + u3), tv_lambda));
    
    % --- 对偶变量更新 ---
    u1 = u1 + x - z1;
    u2 = u2 + x - z2;
    u3 = u3 + x - z3;
    
    % --- 计算指标 ---
    res = abs(A(x)) - sqrt(y);
    loss_history(iter) = gather(norm(res(:), 2)^2);
    corr_history(iter) = gather(corr_c(abs(A(x)), sqrt(y)));
    
    % 缓存管理
    idx = mod(iter - 1, cache_size) + 1;
    cache_loss(idx) = loss_history(iter);
    
    % --- 显示进度 ---
    if mod(iter, display_iter) == 0
        criteria = std(cache_loss) / mean(cache_loss);
        fprintf('iter: %4d | loss: %5.2e | loss std: %5.2e | corr: %5.2e | runtime: %5.1f s\n', ...
            iter, loss_history(iter), criteria, corr_history(iter), toc(timer));
        
        % 可视化
        if options.display_iter > 0
            Fig = figure(2);
            imshow(abs(Q1(x)), [0, 2], 'border', 'tight');
            text(30, 30, sprintf('iter = %d', iter), ...
                'Color', 'black', ...
                'BackgroundColor', 'white', ...
                'FontSize', 20, ...
                'FontWeight', 'bold');
            drawnow;
        end
    end
end

% 最终傅里叶空间滤波
x_est = ifft2(fftshift(supportF2 .* fftshift(fft2(x))));
end