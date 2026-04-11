function [ber, num_errors, total_bits] = calc_ber(tx_bits, rx_bits)
% CALC_BER - 计算误码率
%
% 输入:
%   tx_bits - 发送比特向量
%   rx_bits - 接收比特向量
%
% 输出:
%   ber         - 误码率
%   num_errors  - 错误比特数
%   total_bits  - 总比特数

    assert(length(tx_bits) == length(rx_bits), '发送与接收比特长度不一致');
    total_bits = length(tx_bits);
    num_errors = sum(xor(tx_bits, rx_bits));
    
    if total_bits == 0
        ber = 0;
    else
        ber = num_errors / total_bits;
    end
end

function [per, num_errors, total_packets] = calc_per(ber, packet_bits)
% CALC_PER - 由 BER 计算误包率
%
% 输入:
%   ber         - 误码率
%   packet_bits - 每包比特数
%
% 输出:
%   per          - 误包率
%   num_errors   - 错误包数（基于 BER 计算）
%   total_packets - 总包数

    per = 1 - (1 - ber)^packet_bits;
    per = max(per, 1e-10);
    per = min(per, 1.0);
    
    num_errors = 0;
    total_packets = 0;
end

function [bler, is_block_error] = calc_bler(tx_bits, rx_bits)
% CALC_BLER - 计算误块率
%
% 输入:
%   tx_bits - 发送比特向量
%   rx_bits - 接收比特向量
%
% 输出:
%   bler          - 误块率
%   is_block_error - 是否误块（1=误块, 0=正确）

    num_errors = sum(xor(tx_bits, rx_bits));
    is_block_error = double(num_errors > 0);
    bler = is_block_error;
end
