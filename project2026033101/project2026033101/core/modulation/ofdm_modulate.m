function tx_sig = ofdm_modulate(freq_syms, N_fft, cp_len)
% OFDM_MODULATE - OFDM 调制器（IFFT + CP）
%
% 输入:
%   freq_syms - 频域符号向量 [N_fft x num_symbols] 或 [N_fft x 1]
%   N_fft     - FFT 点数
%   cp_len    - 循环前缀长度
%
% 输出:
%   tx_sig    - 时域发射信号向量

    if size(freq_syms, 2) == 1
        % 单个 OFDM 符号
        time_sym = ifft(freq_syms, N_fft);
        cp_part = time_sym((N_fft-cp_len+1):N_fft);
        tx_sig = [cp_part; time_sym];
    else
        % 多个 OFDM 符号
        num_symbols = size(freq_syms, 2);
        tx_sig = zeros((N_fft + cp_len) * num_symbols, 1);
        
        for m = 1:num_symbols
            time_sym = ifft(freq_syms(:, m), N_fft);
            cp_part = time_sym((N_fft-cp_len+1):N_fft);
            
            start_idx = (m-1) * (N_fft + cp_len) + 1;
            tx_sig(start_idx:start_idx+cp_len-1) = cp_part;
            tx_sig(start_idx+cp_len:start_idx+N_fft-1) = time_sym;
        end
    end
end
