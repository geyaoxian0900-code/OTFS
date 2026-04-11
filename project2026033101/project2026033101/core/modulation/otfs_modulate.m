function tx_sig = otfs_modulate(dd_data, N, M, cp_len)
% OTFS_MODULATE - OTFS 调制器（ISFFT + Heisenberg 变换）
%
% 论文参考: arXiv 1808.00519, Eq. (31)-(33)
%   ISFFT: X_tf[n,m] = Σ_k Σ_l x_dd[k,l] * exp(j*2π*(mk/M - nl/N))
%   Heisenberg: s(t) = Σ_m Σ_n X_tf[n,m] * exp(j*2π*m*Δf*(t-nT)) * g_tx(t-nT)
%
% 输入:
%   dd_data - DD 域数据矩阵 [N x M]
%   N       - 时延网格大小
%   M       - 多普勒网格大小  
%   cp_len  - 循环前缀长度（采样点数）
%
% 输出:
%   tx_sig  - 时域发射信号向量

    [rows, cols] = size(dd_data);
    assert(rows == N && cols == M, ...
        sprintf('DD 数据尺寸不匹配: 期望 [%d x %d], 实际 [%d x %d]', N, M, rows, cols));

    %% Step 1: ISFFT（逆辛傅里叶变换）DD → TF
    % 辛耦合: 时延 k ↔ 多普勒频率 m, 多普勒 l ↔ 时延频率 n
    tf_data = ifft(fft(dd_data, [], 1), [], 2);

    %% Step 2: Heisenberg 变换（TF → 时域）
    time_grid = ifft(tf_data, [], 1);

    %% Step 3: 添加循环前缀
    tx_sig = zeros(N + cp_len, M);
    for col = 1:M
        cp_part = time_grid((N-cp_len+1):N, col);
        tx_sig(1:cp_len, col) = cp_part;
        tx_sig((cp_len+1):end, col) = time_grid(:, col);
    end

    tx_sig = tx_sig(:);
end
