% =========================================================================

function u = zeropad(x, padsize)
% 零填充图像
u = padarray(x, [padsize, padsize], 0);
end
