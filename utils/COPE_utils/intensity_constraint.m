function u = intensity_constraint(v, y, A, AH, gamma, subiter)
% ADMM强度约束子问题求解
%
% 输入参数：
%   v : 当前估计
%   y : 测量强度
%   A, AH : 前向和伴随算子
%   gamma : 步长
%   subiter : 子迭代次数

u = v;

for sub = 1:subiter
    % 梯度计算
    u_ft = A(u);
    res = abs(u_ft) - y;
    u_ft = u_ft .* (res ./ (abs(u_ft) + 1e-10));
    g = AH(u_ft);
    
    % 更新
    u = u - gamma * g;
    
    % Nesterov
    if sub == 1
        v_current = u;
    else
        v_current = u + (sub-1)/(sub+2) * (u - u_prev);
    end
    u_prev = u;
    u = v_current;
end
end
