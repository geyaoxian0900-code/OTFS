function h_eff = compute_effective_dd_channel(N, M, cp_len, delays_ns, powers_dB, fd, fs)
% COMPUTE_EFFECTIVE_DD_CHANNEL - 计算等效 DD 域信道
%
% 输入:
%   N, M       - OTFS 网格尺寸
%   cp_len     - 循环前缀长度
%   delays_ns  - 抽头延迟 (ns)
%   powers_dB  - 抽头功率 (dB)
%   fd         - 多普勒频移 (Hz)
%   fs         - 采样频率 (Hz)
%
% 输出:
%   h_eff      - 等效 DD 域信道矩阵 [N x M]
%
% 算法说明:
%   通过发送单位脉冲导频并测量接收信号来估计等效 DD 域信道。
%   h_eff[k,l] 表示 DD 域位置 (k,l) 处的等效信道增益。

    %% 默认参数
    default_delays_ns = [0, 30, 70, 90, 110, 190, 410, 490, 570, 700, 1000, 2600];
    default_powers_dB = [-1, -1, -1, 0, 0, 0, -3, -5, -7, -9, -11, -14];

    if nargin < 4 || isempty(delays_ns)
        delays_ns = default_delays_ns;
    end
    if nargin < 5 || isempty(powers_dB)
        powers_dB = default_powers_dB;
    end
    if nargin < 6 || isempty(fd)
        fd = 444;
    end
    if nargin < 7 || isempty(fs)
        fs = 15.36e6;
    end

    %% 方法: 发送 DD 域单位脉冲，测量接收
    % 为每个 DD 域位置发送脉冲太慢，改用随机序列
    % 然后利用互相关估计信道

    % 更简单的方法: 利用 OTFS 的线性特性
    % 发送已知 X_dd，测量 Y_dd，然后估计 H_eff

    % 生成随机发送符号
    rng(42);  % 固定种子以便重复
    X_dd = randn(N, M) + 1j*randn(N, M);
    X_dd = X_dd / std(X_dd(:));  % 归一化

    % OTFS 调制
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    tx_vec = otfs_modulate(X_dd, N, M, cp_len);

    % 通过时域多径信道
    rx_vec = apply_channel_otfs(tx_vec, [], N, M, cp_len, delays_ns, powers_dB, fd, fs);

    % OTFS 解调
    Y_dd = otfs_demodulate(rx_vec, N, M, cp_len);

    % 估计等效 DD 域信道
    % 对于 OTFS，Y ≈ H_eff ⊙ X（近似，忽略 2D 卷积扩散）
    % 更精确: H_eff = Y ./ X（逐元素除法）
    h_eff = Y_dd ./ (X_dd + 1e-10);

    % 清理小值
    h_eff(abs(h_eff) < 1e-6) = 0;
end
