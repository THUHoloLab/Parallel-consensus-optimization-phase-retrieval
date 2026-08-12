function r = corr_c(array1, array2)
% Pearson相关系数

    % 中心化
    array1_centered = array1(:);% - mean(array1(:));
    array2_centered = array2(:);%- mean(array2(:));
    % 标准化
    array1_norm = array1_centered / norm(array1_centered);
    array2_norm = array2_centered / norm(array2_centered);
    % 计算Pearson相关系数
%     r = array1_norm' * array2_norm;
r = abs(array1_norm' * array2_norm);

end

