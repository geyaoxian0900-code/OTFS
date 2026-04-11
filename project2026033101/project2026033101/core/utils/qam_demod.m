function [rx_bits, llr_out, hard_dec] = qam_demod(symbols, M, noise_var, mode)
% QAM_DEMOD - QAM 解调器（硬判决/软 LLR 输出）
%
% 输入:
%   symbols   - 接收到的复符号向量
%   M         - 调制阶数
%   noise_var - 噪声方差 N0（用于软判决 LLR 计算）
%   mode      - 'hard' 硬判决 或 'soft' 软判决
%
% 输出:
%   rx_bits   - 解调后的比特向量
%   llr_out   - 各比特的近似 LLR 值（mode='soft' 时有效）
%   hard_dec  - 硬判决复符号向量

    k = log2(M);
    num_syms = length(symbols);
    
    constell = build_constellation(M);
    num_const = length(constell);
    
    const_bits = zeros(num_const, k, 'uint8');
    for idx = 1:num_const
        const_bits(idx, :) = symbol_to_bits(constell(idx), M)';
    end
    
    hard_dec = zeros(num_syms, 1);
    rx_bits = [];
    llr_out = [];
    
    for idx = 1:num_syms
        r = symbols(idx);
        dists = abs(r - constell).^2;
        [~, min_idx] = min(dists);
        hard_dec(idx) = constell(min_idx);
        
        if strcmp(mode, 'hard')
            rx_bits = [rx_bits; const_bits(min_idx, :)];
        elseif strcmp(mode, 'soft')
            llrs = zeros(1, k);
            for bit_pos = 1:k
                idx_0 = find(const_bits(:, bit_pos) == 0);
                idx_1 = find(const_bits(:, bit_pos) == 1);
                min_d0 = min(dists(idx_0));
                min_d1 = min(dists(idx_1));
                llrs(bit_pos) = (min_d0 - min_d1) / max(noise_var, eps);
            end
            llr_out = [llr_out; llrs];
            rx_bits = [rx_bits; double(llrs < 0)];
        else
            error('mode 必须是 ''hard'' 或 ''soft''');
        end
    end
end

function c = build_constellation(M)
% BUILD_CONSTELLATION - 构建 M-QAM 星座点集合

    if M == 4
        d = 1/sqrt(2);
        c = [d+1j*d, -d+1j*d, -d-1j*d, d-1j*d].';
    else
        half_M = sqrt(M);
        levels = (1:2:(2*half_M-1))';
        levels = levels - mean(levels);
        [Re, Im] = meshgrid(levels, levels);
        c = Re(:) + 1j * Im(:);
        norm_factor = sqrt(2/3 * (M - 1));
        c = c / norm_factor;
    end
end

function bits_row = symbol_to_bits(sym, M)
% SYMBOL_TO_BITS - 复符号反查比特映射

    k = log2(M);
    
    if M == 4
        s = sym * sqrt(2);
        b0 = real(s) < 0;
        b1 = imag(s) < 0;
        bits_row = [b0, b1];
    else
        half_k = k / 2;
        norm_factor = sqrt(2/3 * (M - 1));
        s = sym * norm_factor;
        I_val = round(real(s));
        Q_val = round(imag(s));
        
        L_half = 2^half_k;
        I_nat = uint32((I_val + L_half - 1) / 2);
        Q_nat = uint32((Q_val + L_half - 1) / 2);
        
        I_gray = nat_to_gray_vec(I_nat, half_k);
        Q_gray = nat_to_gray_vec(Q_nat, half_k);
        
        bits_row = [I_gray, Q_gray];
    end
end

function g = nat_to_gray_vec(val, n)
% NAT_TO_GRAY_VEC - 自然二进制转 Gray 码向量

    g = zeros(1, n, 'uint8');
    tmp = val;
    for i = n:-1:1
        g(i) = mod(tmp, 2);
        tmp = floor(tmp / 2);
    end
    for i = 1:n-1
        g(i) = bitxor(g(i), g(i+1));
    end
    g = g(end:-1:1);
end
