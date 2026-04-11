function rx_vec = apply_channel_otfs(tx_vec, h_dd, N, M, cp_len, delays_ns, powers_dB, fd, fs)
% APPLY_CHANNEL_OTFS - OTFS 信号通过 DD 域信道
%
% 论文参考: arXiv 1808.00519, Eq. (40)-(42)
%   DD 域接收模型: y_p[k,l] = h_w ⊛ x_p[k,l] + v_p[k,l]
%   其中 ⊛ 表示 2D 循环卷积
%   h_w(kΔτ, lΔν) 为 DD 域等效信道冲激响应
%
% 输入:
%   tx_vec     - 发射时域信号 [M*(N+cp_len) x 1]
%   h_dd       - DD 域信道矩阵 [N x M]（如果为空则自动生成）
%   N, M       - OTFS 网格尺寸
%   cp_len     - 循环前缀长度
%   delays_ns  - 多径时延 (ns)
%   powers_dB  - 多径功率 (dB)
%   fd         - 多普勒频移 (Hz)
%   fs         - 采样频率 (Hz)
%
% 输出:
%   rx_vec     - 接收时域信号
%
% 算法 (严格遵循论文):
%   1. 解调 tx_vec → X_dd (Wigner + SFFT)
%   2. DD 域 2D 循环卷积: Y_dd = h_dd ⊛ X_dd
%      - 利用稀疏性: 仅计算非零抽头位置
%      - 使用 2D FFT 加速: Y_dd = ifft2(fft2(h_dd) .* fft2(X_dd))
%   3. 调制 Y_dd → rx_vec (ISFFT + Heisenberg)

    %% 生成信道（如果未提供）
    if nargin < 2 || isempty(h_dd)
        if nargin < 6 || isempty(delays_ns)
            delays_ns = [0, 30, 70, 90, 110, 190, 410, 490, 570, 700, 1000, 2600];
        end
        if nargin < 7 || isempty(powers_dB)
            powers_dB = [-1, -1, -1, 0, 0, 0, -3, -5, -7, -9, -11, -14];
        end
        if nargin < 8 || isempty(fd)
            fd = 444;
        end
        if nargin < 9 || isempty(fs)
            fs = 15.36e6;
        end
        h_dd = tdlc_channel(N, M, fd, fs, delays_ns, powers_dB);
    end

    %% 方法 1: 稀疏 2D 循环卷积 (利用 DD 域信道稀疏性)
    % 论文强调: DD 域信道是稀疏的（少数抽头），可利用此特性优化
    % 对于每个非零抽头 (n_tau, m_nu):
    %   Y_dd(k,l) += h_dd(n_tau, m_nu) * X_dd(k-n_tau, l-m_nu)
    % 其中索引运算是模 N 和模 M 的（循环卷积）
    
    % 解调得到 DD 域发送符号
    X_dd = otfs_demodulate(tx_vec, N, M, cp_len);
    
    % 检测稀疏性
    h_power = abs(h_dd).^2;
    max_h_power = max(h_power(:));
    sparse_threshold = 1e-4 * max_h_power;  % -40 dB 阈值
    [nz_row, nz_col] = find(h_power > sparse_threshold);
    sparsity = length(nz_row) / (N * M);
    
    if sparsity < 0.1 && N * M > 1000
        % 稀疏信道: 直接时域卷积更高效
        Y_dd = zeros(N, M);
        for idx = 1:length(nz_row)
            n_tau = nz_row(idx);
            m_nu = nz_col(idx);
            h_val = h_dd(n_tau, m_nu);
            
            % 循环移位 X_dd
            X_shifted = circshift(X_dd, [n_tau-1, m_nu-1]);
            Y_dd = Y_dd + h_val * X_shifted;
        end
    else
        % 非稀疏信道: 2D FFT 加速
        % 论文 Eq. (40): 2D 循环卷积定理
        %   y = h ⊛ x  ←→  Y = H · X (频域逐点乘法)
        H_fft = fft2(h_dd);
        X_fft = fft2(X_dd);
        Y_dd = ifft2(H_fft .* X_fft);
    end

    %% 调制回时域
    rx_vec = otfs_modulate(Y_dd, N, M, cp_len);
end
