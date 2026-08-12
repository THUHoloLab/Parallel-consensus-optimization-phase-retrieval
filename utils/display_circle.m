
% I = imread('cameraman.tif');
% [arc_y, arc_x, phase_values1] = display_circle(I, 150, 150, 50, 60, 360, 60);
% figure
% plot(phase_values1)

function [arc_y, arc_x,phase_values1] = display_circle(img, center_x, center_y, radius, start_angle, end_angle, point)
% 在图像上绘制圆形轨迹并提取相位值
% 
% 输入参数：
%   img: 输入图像矩阵
%   center_x: 圆心x坐标
%   center_y: 圆心y坐标
%   radius: 圆半径
%   start_angle: 起始角度（度）
%   end_angle: 结束角度（度）
%   point: 采样点数
%
% 输出参数：
%   circle: 包含绘图信息的结构体
%   phase_values: 提取的相位值数组
%   coordinates: 采样点的坐标数组


%%phase curve
color1 = [255,82,73]/255; %red
color2 = [0,176,80]/255; %green
color3 = [0,115,189]/255;
color4 = [255,192,0]/255; % yellow

% 获取图像的尺寸
[H, W] = size(img);

angles = linspace(start_angle, end_angle, point);

phase_values1 = zeros(size(angles));
coordinates1 = zeros(length(angles), 2);

% 沿着圆形轨迹提取相位值
for i = 1:length(angles)
    val_angle = angles(i);  % 当前角度

    % 计算对应的 (x, y) 坐标
    x = round(center_x + radius * cosd(val_angle));  % cosd 用于角度（度）
    y = round(center_y + radius * sind(val_angle));  % sind 用于角度（度）
    coordinates1(i, :) = [x, y];

    % 确保 (x, y) 在图像范围内
    if x >= 1 && x <= H && y >= 1 && y <= W
        phase_values1(i) = img(x, y);
    else
        phase_values1(i) = NaN;  % 如果超出范围，则记录 NaN
    end
end

% 绘制相位图
figure(19)
subplot(121)
imshow(img, []);
hold on;

% 绘制圆形弧线（从start_angle开始的180度弧线）
theta = linspace(deg2rad(start_angle), deg2rad(end_angle), point);  % 生成从起始角度开始的弧线
arc_x = center_x + radius * cos(theta);  % 弧线的x坐标
arc_y = center_y + radius * sin(theta);  % 弧线的y坐标
plot(arc_y, arc_x, 'Color', color2, 'LineStyle','--','LineWidth', 1.5);  % 绘制圆弧
hold off
subplot(122)
plot(phase_values1);ylim([-pi, pi]);axis square
end



% %% 3D surface
% 
% % colorbar
% T = load("cmocean_deep.txt"); %cmocean_thermal
% if max((T))>1
% T = T./255;
% else
% end
% T = flipud(T);% 翻转color
% 
% height = PGGAN_fake_pha./(n-1)./k * 1e6;
% xt = linspace(0,224,224);
% yt = xt;
% [XT, YT] = meshgrid(xt,yt);
% figure, surf(XT, YT, height);
% colormap(T);
% shading interp;
% box on; 
% ax = gca;
% ax.BoxStyle = 'back';
% xlim([0,224]);
% ylim([0,224]);
% zlim([0,0.4]);
% view(45+270,80);
% grid off;
% % light;  % 添加光源
% lighting flat;  % 光照模型 :gouraud/flat/phong
% clim([0,0.4]);
% alpha(1);  % 设置透明度

% %% compare image
% 
% img1 = PGGAN_fake_pha;
% img2 = AWF_pha;
% % M = slanCM(4);
% 
% % 为了合成方便，先把两张图尺寸对齐
% [h1,w1] = size(img1);
% [h2,w2] = size(img2);
% H = min(h1,h2);
% W = min(w1,w2);
% img1r = im2double(imresize(img1,[H W]));
% img2r = im2double(imresize(img2,[H W]));
% 
% figure, imshow(img1,[]); colormap (M); clim([0,1.8]);
% %% 构造一条“从上边到下边”的斜分界线
% % 设定分界线与上边(y=1)的交点、与下边(y=H)的交点
% x_top    = 0.15 * W;   % 分界线在上边的x位置，可调 0~W
% x_bottom = 0.45 * W;   % 分界线在下边的x位置，可调 0~W
% 
% % 用两个点 (x_top, 1) 和 (x_bottom, H) 求直线 y = m*x + b
% m = (H - 1) / (x_bottom - x_top);   % 斜率
% b = 1 - m * x_top;                  % 截距
% 
% % 网格
% [xg, yg] = meshgrid(1:W, 1:H);
% 
% % 对每个像素，判断是在直线的哪一侧
% % 想要直线右边是 img2，左边是 img1，可以这样：
% mask_line = yg > (m * xg + b);   % mask=1 用 img2，0 用 img1
% 
% % 做一个平滑过渡
% blendWidth = 8;
% distToLine = yg - (m * xg + b);
% alpha = 1 ./ (1 + exp(-distToLine / blendWidth));  % 从0到1平滑
% 
% % 合成图
% composite = img1r .* (1 - alpha) + img2r .* alpha;
% 
% %% 显示
% figure('Color','w','Position',[100 100 700 700]);
% imshow(composite,[]);
% colormap(M);
% clim([0,1.8]);
% hold on;
% 
% %% 把分界虚线画出来
% % 这条线就是你指定的两个交点
% plot([x_top, x_bottom], [1, H], 'w--', 'LineWidth', 1);


