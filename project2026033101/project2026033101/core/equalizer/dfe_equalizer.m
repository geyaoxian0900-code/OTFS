function x_hat = dfe_equalizer(y_dd, h_dd, noise_var, M_order, constell)
% DFE_EQUALIZER - 判决反馈均衡器 (基于 2D FFT 域)
%
% 输入:
%   y_dd       - 接收 DD 域矩阵 [N x M]
%   h_dd       - DD 域信道矩阵 [N x M]
%   noise_var  - 噪声方差
%   M_order    - 调制阶数
%   constell   - 星座点向量
%
% 输出:
%   x_hat      - 硬判决符号估计矩阵 [N x M]
%
% 算法:
%   1. LMMSE 前馈滤波 (2D FFT 域)
%   2. 逐符号判决反馈干扰消除

    [N, M_size] = size(y_dd);
    x_hat = zeros(N, M_size);

    % 2D FFT 域 LMMSE 前馈滤波
    H_fft = fft2(h_dd);
    Y_fft = fft2(y_dd);
    H_power = abs(H_fft).^2;
    W_ff = conj(H_fft) ./ (H_power + noise_var);
    y_ff = ifft2(W_ff .* Y_fft);

    % 计算干扰系数 (DD 域)
    % 干扰来自 h_dd 中非主对角线位置的泄漏
    % 理论最优阈值: 当 |h_leak|² < noise_var 时，干扰低于噪声 floor
    % 此时消除干扰无益（反而引入判决误差传播）
    interference_threshold = noise_var;

    % 逐符号 DFE
    for k = 1:N
        for l = 1:M_size
            y_curr = y_ff(k, l);
            fb_interference = 0;

            % 收集所有已判决符号的干扰
            for kp = 1:N
                for lp = 1:M_size
                    if kp == k && lp == l
                        continue;
                    end

                    % 循环延迟索引
                    dk = mod(k - kp, N) + 1;
                    dl = mod(l - lp, M_size) + 1;

                    h_leak = h_dd(dk, dl);

                    if abs(h_leak)^2 > interference_threshold
                        % 获取已判决符号
                        if kp < k || (kp == k && lp < l)
                            prev_sym = x_hat(kp, lp);
                        else
                            continue;
                        end

                        fb_interference = fb_interference + h_leak * prev_sym;
                    end
                end
            end

            y_dec = y_curr - fb_interference;
            [~, idx] = min(abs(y_dec - constell));
            x_hat(k, l) = constell(idx);
        end
    end
end
