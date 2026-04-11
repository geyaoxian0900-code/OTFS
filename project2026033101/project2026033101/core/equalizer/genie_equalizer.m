function x_hat = genie_equalizer(y_dd, h_dd, noise_var, x_true, constell)
% GENIE_EQUALIZER - 精灵 DFE 均衡器（理想反馈，理论上界）
%
% 输入:
%   y_dd       - 接收 DD 域矩阵 [N x M]
%   h_dd       - DD 域信道矩阵 [N x M]
%   noise_var  - 噪声方差
%   x_true     - 真实发送符号矩阵 [N x M]
%   constell   - 星座点向量
%
% 输出:
%   x_hat      - 符号估计矩阵 [N x M]

    [N, M_size] = size(y_dd);
    x_hat = zeros(N, M_size);

    % 2D FFT 域 LMMSE 前馈滤波
    H_fft = fft2(h_dd);
    Y_fft = fft2(y_dd);
    H_power = abs(H_fft).^2;
    W_ff = conj(H_fft) ./ (H_power + noise_var);
    y_ff = ifft2(W_ff .* Y_fft);

    % 干扰阈值
    h_power = abs(h_dd).^2;
    max_h_power = max(h_power(:));
    interference_threshold = 0.01 * max_h_power;

    % 使用真实符号进行完美干扰消除
    for k = 1:N
        for l = 1:M_size
            y_curr = y_ff(k, l);
            fb_interference = 0;

            for kp = 1:N
                for lp = 1:M_size
                    if kp == k && lp == l
                        continue;
                    end

                    dk = mod(k - kp, N) + 1;
                    dl = mod(l - lp, M_size) + 1;

                    h_leak = h_dd(dk, dl);

                    if abs(h_leak)^2 > interference_threshold
                        true_sym = x_true(kp, lp);
                        fb_interference = fb_interference + h_leak * true_sym;
                    end
                end
            end

            y_dec = y_curr - fb_interference;
            [~, idx] = min(abs(y_dec - constell));
            x_hat(k, l) = constell(idx);
        end
    end
end
