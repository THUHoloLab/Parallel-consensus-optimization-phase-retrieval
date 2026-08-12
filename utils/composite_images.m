% clc;close all; clear
% img1 = imread('cameraman.tif');
% img2 = imread('rice.png');
% img2 = imresize(img2, size(img1));
% 
% % 两个图像合成：线段从第一行的1/8处到最后行的1/2处
% composite2 = composite_images(img1, img2, [1/8, 1/2]);
% 
% figure;
% imshow(composite2);
% title('两个图像合成（水平分割）');
% 
% % 示例2：合成三个图像
% img3 = imread('coins.png');
% img3 = imresize(img3, size(img1));
% 
% figure
% imshow(img3)
% composite3 = composite_images(img1, img2, img3, [1/2, 1/4, 3/4]);
% 
% figure;
% imshow(composite3);
% title('三个图像合成（两条不同起点的线段）');

function composite_img = composite_images(varargin)
% 合成两个或三个图像，以指定线段为界
% 用法：
%   两个图像：composite_img = composite_images(img1, img2, line_params)
%   三个图像：composite_img = composite_images(img1, img2, img3, line_params)
% 
% 输入：
%   img1, img2, img3: 相同大小的图像矩阵（灰度或RGB）
%   line_params: 线段位置参数
%       - 两个图像：[x1_start, x1_end]，x1为线段上端点在图像第一行的位置（归一化坐标）
%       - 三个图像：[y_A, x_C, x_B]，y_A为第一列A点的y坐标，x_C为第一行C点的x坐标，x_B为最后一行B点的x坐标
%
% 输出：
%   composite_img: 合成后的图像矩阵

    % 检查输入参数数量
    if nargin < 3
        error('至少需要输入两个图像和一个线段参数');
    end
    
    % 获取最后一个参数（线段参数）
    line_params = varargin{end};
    
    % 根据参数数量判断是合成两个还是三个图像
    if nargin == 3
        % 两个图像的情况（保持不变）
        img1 = varargin{1};
        img2 = varargin{2};
        
        % 验证图像大小相同
        if ~isequal(size(img1), size(img2))
            error('图像大小必须相同');
        end
        
        % 获取图像尺寸
        [height, width, channels] = size(img1);
        
        % 解析线段参数（归一化坐标转实际像素坐标）
        x_start = round(line_params(1) * width);  % 第一行的x坐标
        x_end = round(line_params(2) * width);    % 最后一行的x坐标
        
        % 创建合成图像
        composite_img = zeros(size(img1), 'like', img1);
        
        % 为图像中的每个像素分配属于哪个区域
        for row = 1:height
            % 计算当前行对应的x坐标（线性插值）
            x_current = round(x_start + (row-1) * (x_end - x_start) / (height-1));
            
            % 根据x_current分割左右区域
            for col = 1:width
                if col <= x_current
                    composite_img(row, col, :) = img1(row, col, :);
                else
                    composite_img(row, col, :) = img2(row, col, :);
                end
            end
        end
        
        % 绘制黄色虚线
        composite_img = draw_dotted_line(composite_img, x_start, x_end, [1 1 0]);
        
    elseif nargin == 4
        % 三个图像的情况（重新设计逻辑）
        img1 = varargin{1};
        img2 = varargin{2};
        img3 = varargin{3};
        
        % 验证图像大小相同
        if ~isequal(size(img1), size(img2), size(img3))
            error('图像大小必须相同');
        end
        
        % 获取图像尺寸
        [height, width, channels] = size(img1);
        
        % 解析线段参数
        % [y_A, x_C, x_B] 其中：
        % y_A: 第一列A点的y坐标（归一化）
        % x_C: 第一行C点的x坐标（归一化）
        % x_B: 最后一行B点的x坐标（归一化）
        y_A = round(line_params(1) * height);    % A点的y坐标（第一列）
        x_C = round(line_params(2) * width);     % C点的x坐标（第一行）
        x_B = round(line_params(3) * width);     % B点的x坐标（最后一行）
        
        % 确保坐标在有效范围内
        y_A = max(1, min(height, y_A));
        x_C = max(1, min(width, x_C));
        x_B = max(1, min(width, x_B));
        
        % 创建合成图像
        composite_img = zeros(size(img1), 'like', img1);
        
        % 定义点A、B、C的坐标
        % A: (1, y_A) - 第一列，y坐标是y_A
        % C: (x_C, 1) - 第一行，x坐标是x_C
        % B: (x_B, height) - 最后一行，x坐标是x_B
        
        % 简单逻辑：根据像素相对于两条线的位置分配
        for row = 1:height
            for col = 1:width
                % 判断像素在两条线的哪一侧
                
                % 对于线段AB：从A(1,y_A)到B(x_B,height)
                % 判断像素是在线段AB的左侧还是右侧
                % 使用向量叉积的方法判断
                vec_AB = [x_B-1, height-y_A];  % 向量AB
                vec_AP = [col-1, row-y_A];     % 向量AP，P是当前像素(col,row)
                
                % 计算叉积的z分量
                cross_AB_AP = vec_AB(1)*vec_AP(2) - vec_AB(2)*vec_AP(1);
                
                % 对于线段CB：从C(x_C,1)到B(x_B,height)
                % 判断像素是在线段CB的左侧还是右侧
                vec_CB = [x_B-x_C, height-1];  % 向量CB
                vec_CP = [col-x_C, row-1];     % 向量CP
                
                % 计算叉积的z分量
                cross_CB_CP = vec_CB(1)*vec_CP(2) - vec_CB(2)*vec_CP(1);
                
                % 根据位置分配图像
                if cross_AB_AP > 0
                    % 在线段AB的左侧
                    composite_img(row, col, :) = img1(row, col, :);
                elseif cross_CB_CP > 0
                    % 在线段AB的右侧，但在线段CB的左侧
                    composite_img(row, col, :) = img2(row, col, :);
                else
                    % 在线段AB的右侧，且在线段CB的右侧
                    composite_img(row, col, :) = img3(row, col, :);
                end
            end
        end
        
        % 绘制黄色虚线
        composite_img = draw_two_lines(composite_img, y_A, x_C, x_B, [1 1 0]);
        
    else
        error('输入参数数量不正确');
    end
end

function img_with_line = draw_dotted_line(img, x_start, x_end, color)
% 在图像上绘制黄色虚线（两个图像的情况）
    [height, width, channels] = size(img);
    
    % 确保颜色值在正确范围内
    if max(color) > 1
        color = color / 255;
    end
    
    % % 绘制虚线
    % for row = 1:height
    %     % 计算当前行对应的x坐标
    %     x_current = round(x_start + (row-1) * (x_end - x_start) / (height-1));
    % 
    %     % 确保x在图像范围内
    %     if x_current < 1 || x_current > width
    %         continue;
    %     end
    % 
    %     % 绘制虚线（每隔5个像素画一个点）
    %     if mod(row, 10) < 3
    %         if channels == 1  % 灰度图像
    %             img(row, x_current) = 1.0;  % 白色
    %         else  % RGB图像
    %             img(row, x_current, 1) = color(1);
    %             img(row, x_current, 2) = color(2);
    %             img(row, x_current, 3) = color(3);
    %         end
    %     end
    % end
    
    img_with_line = img;
end

function img_with_lines = draw_two_lines(img, y_A, x_C, x_B, color)
% 绘制两条线段：AB和CB
    [height, width, channels] = size(img);
    
    % 确保颜色值在正确范围内
    if max(color) > 1
        color = color / 255;
    end
    
    % 绘制线段AB：从(1, y_A)到(x_B, height)
    for col = 1:width
        % 计算当前列在线段AB上的y值
        if col <= x_B && x_B > 1
            row_ab = round(y_A + (height-y_A)*(col-1)/(x_B-1));
        elseif col > x_B
            row_ab = height;
        else
            row_ab = y_A;
        end
        
        % 确保坐标在图像范围内
        if row_ab >= 1 && row_ab <= height && col >= 1 && col <= width
            % 绘制虚线（每隔3个像素画一个点）
            if mod(col, 3) == 0
                if channels == 1
                    img(row_ab, col) = 1.0;
                else
                    img(row_ab, col, 1) = color(1);
                    img(row_ab, col, 2) = color(2);
                    img(row_ab, col, 3) = color(3);
                end
            end
        end
    end
    
    % 绘制线段CB：从(x_C, 1)到(x_B, height)
    for row = 1:height
        % 计算当前行在线段CB上的x值
        if height > 1
            col_cb = round(x_C + (x_B-x_C)*(row-1)/(height-1));
        else
            col_cb = x_C;
        end
        
        % 确保坐标在图像范围内
        if row >= 1 && row <= height && col_cb >= 1 && col_cb <= width
            % 绘制虚线（每隔3个像素画一个点）
            if mod(row, 3) == 0
                if channels == 1
                    img(row, col_cb) = 1.0;
                else
                    img(row, col_cb, 1) = color(1);
                    img(row, col_cb, 2) = color(2);
                    img(row, col_cb, 3) = color(3);
                end
            end
        end
    end
    
    img_with_lines = img;
end