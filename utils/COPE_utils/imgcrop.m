function u = imgcrop(x, cropsize)
% 裁剪图像中心部分
u = x(cropsize+1:end-cropsize, cropsize+1:end-cropsize);
end
