function freq_syms = ofdm_demodulate(rx_vec, N_fft, cp_len, num_symbols)
% OFDM_DEMODULATE - OFDM 解调器（CP 移除 + FFT）
%
% 输入:
%   rx_vec      - 接收时域向量
%   N_fft       - FFT 点数
%   cp_len      - 循环前缀长度
%   num_symbols - OFDM 符号数量
%
% 输出:
%   freq_syms   - 频域符号向量 [N_fft x num_symbols]

    freq_syms = zeros(N_fft, num_symbols);
    
    for m = 1:num_symbols
        start_idx = (m-1) * (N_fft + cp_len) + cp_len + 1;
        end_idx = start_idx + N_fft - 1;
        
        if end_idx <= length(rx_vec)
            rx_block = rx_vec(start_idx:end_idx);
            freq_syms(:, m) = fft(rx_block, N_fft);
        end
    end
end
