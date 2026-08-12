function lineData = manualLineDataExtraction()
    % manualLineDataExtraction 允许用户在图上手动选择一条线并返回线上的数据
    % 返回值:
    %   lineData - 包含线上点坐标和数据的结构体，包含以下字段:
    %       x - 线上点的x坐标
    %       y - 线上点的y坐标
    %       intensity - 线上点的数据值（如果有图像数据）
    
    % 获取当前图形和坐标轴
    fig = gcf;
    ax = gca;
    
    % 检查当前坐标轴是否有图像或数据
    hasImage = ~isempty(findobj(ax, 'Type', 'image'));
    hasPlot = ~isempty(findobj(ax, 'Type', 'line'));
    
    if ~hasImage && ~hasPlot
        error('当前图上没有图像或数据线可供选择');
    end
    
    % 提示用户选择两个点定义线段
    title(ax, '请点击选择线段的起点和终点', 'FontSize', 12);
    
    % 获取两个点
    [x, y] = ginput(2);
    
    % 绘制选择的线段
    hold on;
    lineHandle = plot(ax, x, y, 'r--', 'LineWidth', 1);
    scatter(ax, x, y, 20, 'ro', 'filled');
    hold off;
    
    % 根据选择的内容类型提取数据
    if hasImage
        % 如果是图像，提取沿着线段的强度值
        imageHandle = findobj(ax, 'Type', 'image');
        imageData = get(imageHandle, 'CData');
        
        % 获取图像坐标范围
        xData = get(imageHandle, 'XData');
        yData = get(imageHandle, 'YData');
        
        if isempty(xData)
            xData = [1 size(imageData, 2)];
        end
        if isempty(yData)
            yData = [1 size(imageData, 1)];
        end
        
        % 在图像坐标空间中生成线段上的点
        numPoints = 1000;  % 采样点数
        xLine = linspace(x(1), x(2), numPoints);
        yLine = linspace(y(1), y(2), numPoints);
        
        % 将坐标转换为图像像素索引
        xIdx = round((xLine - xData(1)) / (xData(2) - xData(1)) * (size(imageData, 2) - 1) + 1);
        yIdx = round((yLine - yData(1)) / (yData(2) - yData(1)) * (size(imageData, 1) - 1) + 1);
        
        % 确保索引在有效范围内
        xIdx = max(1, min(size(imageData, 2), xIdx));
        yIdx = max(1, min(size(imageData, 1), yIdx));
        
        % 提取强度值
        intensities = zeros(1, numPoints);
        for i = 1:numPoints
            intensities(i) = imageData(yIdx(i), xIdx(i));
        end
        
        % 存储结果
        lineData.x = xLine;
        lineData.y = yLine;
        lineData.intensity = intensities;
        
    else
        % 如果是普通数据线，找到与选择线段相交的数据点
        lineHandles = findobj(ax, 'Type', 'line');
        
        % 这里简化处理：返回用户选择的两个端点
        lineData.x = x;
        lineData.y = y;
        lineData.intensity = [];
        
        warning('对于数据线，目前只返回选择的端点坐标。如需更复杂的线段数据提取，请提供更多信息。');
    end
    
    % 更新标题
    title(ax, '线段选择完成', 'FontSize', 12);
    
    
    % 显示提取的数据信息
    fprintf('线段选择完成:\n');
    fprintf('起点: (%.2f, %.2f)\n', x(1), y(1));
    fprintf('终点: (%.2f, %.2f)\n', x(2), y(2));
    
    if hasImage && ~isempty(lineData.intensity)
        fprintf('提取了 %d 个数据点\n', length(lineData.intensity));
    end
end