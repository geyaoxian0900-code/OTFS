function syms = qam_mod(bits, M)
% QAM_MOD - Gray 编码 QAM 调制器（功率归一化）
%
% 输入:
%   bits - 二进制比特向量，长度必须是 log2(M) 的整数倍
%   M    - 调制阶数: 4(QPSK), 16, 64, 256
%
% 输出:
%   syms - 复符号向量，功率归一化至 E[|s|^2] = 1

    k = log2(M);
    assert(fix(k) == k && k > 0, 'M 必须为 2 的幂');
    assert(mod(length(bits), k) == 0, 'bits 长度必须为 log2(M) 的整数倍');
    
    num_syms = length(bits) / k;
    bits_mat = reshape(bits, k, num_syms)';
    
    if M == 4
        % QPSK Gray 映射
        I = 1 - 2 * bits_mat(:, 1);
        Q = 1 - 2 * bits_mat(:, 2);
        syms = (I + 1j * Q) / sqrt(2);
    else
        % M-QAM (M>=16) 方形星座 Gray 映射
        half_k = k / 2;
        assert(mod(half_k, 1) == 0, 'M 必须是平方数');
        
        I_bits = bits_mat(:, 1:half_k);
        Q_bits = bits_mat(:, (half_k+1):end);
        
        I_val = gray_to_pam(I_bits, half_k);
        Q_val = gray_to_pam(Q_bits, half_k);
        
        norm_factor = sqrt(2/3 * (M - 1));
        syms = (I_val + 1j * Q_val) / norm_factor;
    end
end

function val = gray_to_pam(gray_bits, nb)
% GRAY_TO_PAM - Gray 码到 PAM 电平值映射

    natural = zeros(size(gray_bits, 1), nb);
    natural(:, nb) = gray_bits(:, nb);
    for i = (nb-1):-1:1
        natural(:, i) = xor(gray_bits(:, i), natural(:, i+1));
    end
    
    L = 2^nb;
    val = zeros(size(natural, 1), 1);
    for i = 1:nb
        val = val + natural(:, i) * 2^(nb-i);
    end
    val = 2*val - L + 1;
end
