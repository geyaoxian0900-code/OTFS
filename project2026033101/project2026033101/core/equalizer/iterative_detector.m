function [x_hard, x_soft_iter, num_iterations] = iterative_detector(y_dd, h_dd, noise_var, max_iter, M_order, constell)
% ITERATIVE_DETECTOR - 迭代检测器 (基于 2D FFT 域)
%
% 输入:
%   y_dd       - 接收 DD 域矩阵 [N x M]
%   h_dd       - DD 域信道矩阵 [N x M]
%   noise_var  - 噪声方差
%   max_iter   - 最大迭代次数
%   M_order    - 调制阶数
%   constell   - 星座点向量
%
% 输出:
%   x_hard      - 最终硬判决符号矩阵 [N x M]
%   x_soft_iter - 各迭代的软符号估计记录（元胞数组）
%   num_iterations - 实际迭代次数

    [Nr, Mc] = size(y_dd);
    conv_threshold = 1e-3;
    x_soft_iter = cell(max_iter, 1);

    % 2D FFT 域 LMMSE 权重
    H_fft = fft2(h_dd);
    H_conj = conj(H_fft);
    H_power = abs(H_fft).^2;
    W_mmse = H_conj ./ (H_power + noise_var);

    %% 迭代 1: 初始 LMMSE 均衡
    Y_fft = fft2(y_dd);
    x_soft_prev = ifft2(W_mmse .* Y_fft);
    x_soft_iter{1} = x_soft_prev;

    %% 迭代 2~max_iter: 干扰消除 + 重均衡
    num_iterations = 1;

    for iter = 2:max_iter
        % 步骤 1: 硬判决
        x_hard_temp = zeros(Nr, Mc);
        for k = 1:Nr
            for l = 1:Mc
                [~, idx] = min(abs(x_soft_prev(k, l) - constell));
                x_hard_temp(k, l) = constell(idx);
            end
        end

        % 步骤 2: 重构干扰 (DD 域 2D 卷积)
        y_reconstructed = ifft2(fft2(h_dd) .* fft2(x_hard_temp));

        % 步骤 3: 干扰 = 重构接收 - 自身贡献
        % 论文方法: 自贡献是 DD 域信道的"对角线"部分
        % 在 2D 循环卷积中，自贡献对应 h_dd(1,1) * x_hard_temp
        % 但更精确: 使用 2D FFT 域的对角线 (主路径响应)
        %
        % 方法 1: 简单近似 (当前)
        %   self_contribution = h_dd(1,1) * x_hard_temp
        %
        % 方法 2: 精确对角线 (推荐)
        %   2D FFT 域的对角线对应时域的主对角线路径
        %   self_contrib_fft = mean(fft2(h_dd), 'all') 不正確
        %   正确: 提取 h_dd 的"主抽头" (能量最大位置)
        
        % 使用 2D FFT 域方法: 自贡献 = ifft2(mean(H_fft(:)) * X_fft)
        % 但更简单且正确: 自贡献 = h_dd ⊛ x_hard_temp 的对角线部分
        % 实际实现: 使用 h_dd 的"主抽头" (能量最大位置)
        [max_val, max_idx_1d] = max(abs(h_dd(:)));
        [max_r, max_c] = ind2sub(size(h_dd), max_idx_1d);
        % 仅保留主抽头
        h_self = zeros(size(h_dd));
        h_self(max_r, max_c) = h_dd(max_r, max_c);
        self_contribution = ifft2(fft2(h_self) .* fft2(x_hard_temp));
        
        interference = y_reconstructed - self_contribution;

        % 步骤 4: 干扰消除 + 重新均衡
        y_clean = y_dd - interference;
        x_soft_new = ifft2(W_mmse .* fft2(y_clean));

        x_soft_iter{iter} = x_soft_new;
        num_iterations = iter;

        % 步骤 5: 收敛检查
        change_norm = norm(x_soft_new(:) - x_soft_prev(:)) / (norm(x_soft_prev(:)) + eps);
        x_soft_prev = x_soft_new;

        if change_norm < conv_threshold
            x_soft_iter = x_soft_iter(1:iter);
            break;
        end
    end

    %% 最终硬判决
    x_hard = zeros(Nr, Mc);
    for k = 1:Nr
        for l = 1:Mc
            [~, idx] = min(abs(x_soft_prev(k, l) - constell));
            x_hard(k, l) = constell(idx);
        end
    end
end
