function mask = drawCircleMask(img)
% drawCircleMaskSimple - 简化版本的圆形掩膜绘制函数
% 
% 输入参数：
%   img - 输入图像
% 
% 输出参数：
%   mask - 二进制掩膜

    % 检查输入
    if nargin == 0
        error('请输入图像');
    end
    
    % 显示图像
    figure;
    imshow(img);
    title('请绘制圆形：点击确定圆心，拖动确定半径');
    
    % 绘制圆形
    h = drawcircle('Color','r','LineWidth',2);
    
    % 等待用户完成绘制（按回车键或双击）
    pause;
    
    % 创建掩膜
    mask = createMask(h);
    
    % 关闭窗口
    close gcf;
end