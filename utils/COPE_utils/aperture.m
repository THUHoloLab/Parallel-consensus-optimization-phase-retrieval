
function mask = aperture(N1, N2, center_x, center_y, radius)
% 创建圆形孔径掩模
[X, Y] = meshgrid(1:N2, 1:N1);
mask = sqrt((X - center_x).^2 + (Y - center_y).^2) <= radius;
end