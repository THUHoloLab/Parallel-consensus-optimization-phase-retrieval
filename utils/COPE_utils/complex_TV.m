% =========================================================================

function o = complex_TV(S, lambda)
% 复数全变分正则化
%
% 输入参数：
%   S : 输入复数图像
%   lambda : 正则化参数

betamax = 1e5;
[N, M] = size(S);

% 梯度算子
fx = [1, -1];
fy = [1; -1];
otfFx = gpuArray(psf2otf(fx, [N, M]));
otfFy = gpuArray(psf2otf(fy, [N, M]));

Normin1 = gpuArray(fft2(S));
Denormin2 = abs(otfFx).^2 + abs(otfFy).^2;

beta = lambda;
o = gpuArray(S);

while beta < betamax
    lambeta = lambda / beta;
    Denormin = 1 + beta * Denormin2;
    
    % h-v子问题
    u = [diff(o, 1, 2), o(:, 1) - o(:, end)];
    v = [diff(o, 1, 1); o(1, :) - o(end, :)];
    
    den = sqrt(u.^2 + v.^2) + 1e-5;
    u = u ./ abs(den) .* max(abs(den) - lambeta, 0);
    v = v ./ abs(den) .* max(abs(den) - lambeta, 0);
    
    % o子问题
    Normin2 = [u(:, end) - u(:, 1), -diff(u, 1, 2)];
    Normin2 = Normin2 + [v(end,:,:) - v(1,:, :); -diff(v, 1, 1)];
    Fo = (Normin1 + beta * fft2(Normin2)) ./ Denormin;
    o = ifft2(Fo);
    
    beta = beta * 2;
end
end
