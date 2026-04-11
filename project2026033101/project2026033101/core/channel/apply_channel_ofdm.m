function rx_vec = apply_channel_ofdm(tx_vec, h_time, N_fft, cp_len, num_symbols)
% APPLY_CHANNEL_OFDM - OFDM 信号通过时域多径信道
%
% 标准 OFDM 信道模型:
%   1. 每个 OFDM 符号: [CP | 数据] 通过多径信道
%   2. 线性卷积: rx = tx * h + n
%   3. CP 吸收 ISI: 当信道长度 ≤ CP+1 时，无符号间干扰
%   4. 接收端: 移除 CP → FFT → 频域均衡
%
% 输入:
%   tx_vec      - OFDM 发射时域信号 [(N_fft+cp_len)*num_symbols x 1]
%   h_time      - 时域信道冲激响应 [L x 1] (L 为抽头数量)
%   N_fft       - FFT 点数
%   cp_len      - CP 长度
%   num_symbols - OFDM 符号数量
%
% 输出:
%   rx_vec      - 接收时域信号（与 tx_vec 同长度）
%
% 算法 (标准 OFDM 信道模型):
%   对每个 OFDM 符号:
%     1. 完整线性卷积: rx_full = conv(tx_sym, h_time)
%     2. 提取有效部分: 跳过 transient (L-1 个采样)
%     3. 保留 N_fft + cp_len 个采样 (保持符号结构)
%   注意: 当 L ≤ cp_len+1 时，CP 完全吸收 ISI

    L = length(h_time);
    rx_vec = zeros(size(tx_vec));
    
    for sym = 1:num_symbols
        % 提取当前 OFDM 符号
        tx_start = (sym-1) * (N_fft + cp_len) + 1;
        tx_end = tx_start + N_fft + cp_len - 1;
        tx_sym = tx_vec(tx_start:tx_end);
        
        % 完整线性卷积
        rx_full = conv(tx_sym, h_time);
        
        % 提取有效接收部分
        % 线性卷积输出长度: (N_fft+cp_len) + L - 1
        % 我们保留从索引 L 开始的 N_fft+cp_len 个采样
        % 这对应于信道瞬态结束后的部分
        rx_start = L;
        rx_end = rx_start + N_fft + cp_len - 1;
        
        if rx_end <= length(rx_full)
            rx_sym = rx_full(rx_start:rx_end);
        else
            % 边界处理: 零填充
            rx_sym = zeros(N_fft + cp_len, 1);
            available = length(rx_full) - rx_start + 1;
            if available > 0
                rx_sym(1:available) = rx_full(rx_start:end);
            end
        end
        
        % 存储到输出
        rx_vec(tx_start:tx_end) = rx_sym;
    end
end
