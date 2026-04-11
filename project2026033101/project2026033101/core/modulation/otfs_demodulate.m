function dd_est = otfs_demodulate(rx_vec, N, M, cp_len)
% OTFS_DEMODULATE - OTFS 解调器（Wigner 变换 + SFFT）
%
% 论文参考: arXiv 1808.00519, Eq. (6), (34)-(35)
%   Wigner: Y[n,m] = ∫ e^{-j*2π*ν*(t-τ)} * g_rx*(t-τ) * r(t) dt
%   SFFT: x_dd[k,l] = Σ_n Σ_m Y[n,m] * exp(-j*2π*(ln/N - km/M))
%
% 输入:
%   rx_vec  - 接收时域向量
%   N       - 时延网格大小
%   M       - 多普勒网格大小
%   cp_len  - 循环前缀长度
%
% 输出:
%   dd_est  - DD 域估计矩阵 [N x M]
%
% 注意: 与 otfs_modulate.m 形成逆变换对（使用能量归一化）

    total_len = length(rx_vec);
    expected_len = M * (N + cp_len);

    if total_len ~= expected_len
        warning('接收向量长度不匹配: 期望 %d, 实际 %d', expected_len, total_len);
        rx_vec = rx_vec(1:min(total_len, expected_len));
        if length(rx_vec) < expected_len
            rx_vec = [rx_vec; zeros(expected_len - length(rx_vec), 1)];
        end
    end

    %% Step 1: Wigner 变换（时域 → TF）
    rx_matrix = reshape(rx_vec, N + cp_len, M);
    rx_no_cp = rx_matrix((cp_len+1):end, :);  % [N x M]
    rx_tf = fft(rx_no_cp, [], 1);  % [N x M]

    %% Step 2: SFFT（辛傅里叶变换） TF → DD
    % 与调制器的 ISFFT 形成逆变换对
    % 调制: ifft(fft(X,[],1),[],2) -> ifft -> Time
    % 解调: fft -> fft(ifft(Y,[],1),[],2)
    
    dd_est = fft(ifft(rx_tf, [], 1), [], 2);
end
