function x_hat = mmse_equalizer(y_dd, h_dd, noise_var)
% MMSE_EQUALIZER - 线性 MMSE 均衡器
%
% 输入:
%   y_dd       - 接收 DD 域矩阵 [N x M]
%   h_dd       - DD 域信道矩阵 [N x M]
%   noise_var  - 时域噪声方差 N0
%
% 输出:
%   x_hat      - 发送符号估计矩阵 [N x M]
%
% 算法:
%   对于 OTFS，DD 域接收信号模型为 2D 循环卷积:
%     Y_dd = h_dd ⊛ X_dd + V_dd
%
%   在 2D FFT 域:
%     Y_fft = H_fft .* X_fft + V_fft
%
%   LMMSE 均衡:
%     X_hat_fft = conj(H_fft) ./ (|H_fft|^2 + σ²_dd) .* Y_fft
%     x_hat = ifft2(X_hat_fft)
%
%   注意: 时域噪声经过 OTFS 解调后，DD 域噪声方差为 noise_var/N
%   (因为 Wigner 变换对每列做 N 点 FFT，噪声功率除以 N)

    [N, M_size] = size(y_dd);
    assert(isequal(size(h_dd), [N, M_size]), 'y_dd 与 h_dd 尺寸不一致');

    % DD 域有效噪声方差
    noise_var_dd = noise_var / N;

    % 2D FFT
    H_fft = fft2(h_dd);
    Y_fft = fft2(y_dd);

    % LMMSE 权重
    H_power = abs(H_fft).^2;
    W_mmse = conj(H_fft) ./ (H_power + noise_var_dd);

    % 均衡 + 反变换
    X_hat_fft = W_mmse .* Y_fft;
    x_hat = ifft2(X_hat_fft);
end
