function H = transfunc_propagate(n1, n2, dist, pxsize, wavlen)
% 计算自由空间衍射传输函数

k1 = pi/pxsize * (-1:2/n1:1-2/n1);
k2 = pi/pxsize * (-1:2/n2:1-2/n2);
[K2, K1] = meshgrid(k2, k1);

k = 2*pi/wavlen;  % 波数

% 移除渐逝波
ind = (K1.^2 + K2.^2 >= k^2);
K1(ind) = 0;
K2(ind) = 0;

H = exp(1i * dist * sqrt(k^2 - K1.^2 - K2.^2));
end
