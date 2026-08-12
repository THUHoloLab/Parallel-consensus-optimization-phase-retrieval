function c = corr_c(a, b)
% 计算两个图像的相关系数
a = a(:);
b = b(:);
c = abs(a' * b) / (norm(a) * norm(b));
end