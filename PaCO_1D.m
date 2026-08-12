 clear; clc; close all;

% 添加路径
addpath(genpath('./utils'));
addpath(genpath('../data'));

% =========================================================================
% 数据加载和预处理
params.dist = 3.52;% mm
params.pxsize = 2.4e-3;
params.wavlen = 0.532e-3;
params.cropsize = 256;
cropsize= params.cropsize;
% 加载物体图像
n = 256;
m = 0:n-1;  % 时间点 0 到 255
% amp_img = imresize(mean(imread(['peppers.png'])/255,3),[256,256]);
amp_img = 1;

freq1 = 1;  % 频率
freq2 = 10;  % 频率
sin_wave = 0.5*sin(2 * pi * freq1 * m / n) + 0.5*sin(2 * pi * freq2 * m / n);
sin_matrix = repmat(sin_wave, n, 1);
phase_img = sin_matrix;


% [x, y] = meshgrid(1:n, 1:n);
% theta = atan2(y - n/2, x - n/2);  % 从-π到π
% l = 10;  
% phase_img = mod(l * theta, 2*pi);

test_img = amp_img .* exp(1i.*1.*phase_img);
img_obj = padarray(test_img, [params.cropsize,params.cropsize], 'both');

d_defocus = 0;
img_obj = propagate(img_obj,d_defocus,params.pxsize,params.wavlen);


figure(31)
imshow(angle(img_obj),[])
figure(32)
plot(angle(test_img(128,:)))
figure
imshow(log(abs(fftshift(fft2(img_obj))+1)),[])

close all
% =========================================================================
% 掩模
% =========================================================================
[M1, M2] = size(img_obj);
maskSize = 12e-3;
ratio = round(maskSize./ params.pxsize);
ratio = 2;
phaseRAND = binornd(1,0.5, round([M1/ratio, M2/ratio]));
phaseRAND = imresize(phaseRAND, [M1, M2],"nearest");
mask = exp(1i * pi * phaseRAND);
% =========================================================================
% 准备测量数据
% =========================================================================
N1 = M1 ;
N2 = M2 ;
HQ2 = fftshift(transfunc_propagate(N1, N2, params.dist, params.pxsize, params.wavlen));

% 测量算子函数句柄
M = @(x) x .* mask;
MH = @(x) x .* conj(mask);
Q2 = @(x) ifft2(fft2(x) .* HQ2);
Q2H = @(x) ifft2(fft2(x) .* conj(HQ2));
A = @(x) (Q2(M(x)));
AH = @(x) MH(Q2H((x)));

yComplex = A(img_obj);
y_amp = abs(yComplex).^2;
snr_val = inf;
y = (max(awgn(y_amp,snr_val),0));


figure
imshow(y,[])
imshow(abs(Q2(M(img_obj))),[])

% =========================================================================
% 设置算法参数
% =========================================================================
LF = 1*max(abs(mask(:)))^2;
gamma = 1/LF;

options = struct(...
    'max_iter', 500, ...
    'rho1', 1, ...
    'rho2', 1, ...
    'rho3', 1, ...
    'gamma', gamma, ...
    'support_radius',1/8 ,...
    'tv_lambda', 0.05, ...
    'd_defocus', d_defocus, ...
    'display_iter', 1, ...
    'cache_size', 10, ...
    'subiter', 3 ...
    );

% =========================================================================
% 运行相位恢复算法
% =========================================================================
[x_est, loss_history, corr_history] = COPEforSim(y, mask, params, options);

% =========================================================================
% 结果可视化
% =========================================================================
% 1. 损失函数曲线
figure('Position', [100, 100, 800, 300]);
subplot(1, 2, 1);
semilogy(loss_history);
xlabel('迭代次数');
ylabel('损失函数');
title('损失函数收敛曲线');
grid on;

subplot(1, 2, 2);
plot(corr_history);
xlabel('迭代次数');
ylabel('相关系数');
title('相关系数变化');
grid on;

% 2. 重建结果
xFocus = propagate(x_est, options.d_defocus, params.pxsize, params.wavlen);
C = @(x) x(cropsize+1:end-cropsize, cropsize+1:end-cropsize);

figure('Position', [100, 100, 1200, 400]);
subplot(1, 3, 1);
imshow(abs(C(xFocus)), [0, 1]);
title('重建振幅');

subplot(1, 3, 2);
imshow(angle(C(xFocus)), []);
colormap(sinebow(256));
title('重建相位');

subplot(1, 3, 3);
imshow(y, []);
title('原始测量强度');

% 3. 多焦点显示
% figure;
% for d = -1:0.1:1
%     xFocus_d = propagate(x_est, -d, params.pxsize, params.wavlen);
%     imshow(abs(C(xFocus_d)), [0, 1]);
%     title(sprintf('传播距离 d = %.1f mm', d));
%     drawnow;
%     pause(0.5);
% end

% 4. 在焦点显示
figure;

xFocus_d = propagate(x_est, -d_defocus, params.pxsize, params.wavlen);
subplot(1, 3, 1);
imshow(abs(C(xFocus_d)), []);
subplot(1, 3, 2);
imshow(angle(C(xFocus_d)), []);
subplot(1, 3, 3);
imshow(log(1+abs(fftshift(fft2(C(xFocus_d))))), []);
title(sprintf('传播距离 d = %.1f mm', d_defocus));

% =========================================================================
% 保存结果
% =========================================================================
% save('reconstruction_results.mat', 'x_est', 'loss_history', 'corr_history', 'rect_aoi', 'params');


function u = imgcrop(x,cropsize)
% =========================================================================
% Crop the central part of the image.
% -------------------------------------------------------------------------
% Input:    - x        : Original image.
%           - cropsize : Cropping pixel number along each dimension.
% Output:   - u        : Cropped image.
% =========================================================================
u = x(cropsize+1:end-cropsize,cropsize+1:end-cropsize);
end
