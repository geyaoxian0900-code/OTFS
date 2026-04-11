%% Figure 7: 短包 BLER vs SNR
% 论文 arXiv 1808.00519 Figure 7 复现

clear; close all; clc;

% 获取项目根目录
project_root = fileparts(fileparts(mfilename('fullpath')));

% 显式添加所有核心模块路径
addpath(fullfile(project_root, 'config'));
addpath(fullfile(project_root, 'core', 'modulation'));
addpath(fullfile(project_root, 'core', 'channel'));
addpath(fullfile(project_root, 'core', 'equalizer'));
addpath(fullfile(project_root, 'core', 'utils'));

cfg = system_config('fig7');

fprintf('============================================================\n');
fprintf('  图7：短包传输 BLER vs SNR 对比仿真\n');
fprintf('  信道模型：TDL-C, fd=%dHz (%dkm/h), 4PRB\n', cfg.fd, cfg.velocity);
fprintf('============================================================\n\n');

N = cfg.N;
M_val = cfg.M;
cp_len = cfg.cp_len;
fd = cfg.fd;
fs = cfg.fs;

num_prb = cfg.num_prb;
sc_per_prb = 12;
total_sc = num_prb * sc_per_prb;

mod_orders = cfg.modulation_orders;
code_rate = cfg.code_rate;
SNR_dB = cfg.snr_range;

bler_results = zeros(length(SNR_dB), 4);

fprintf('  配置: %d PRB x %d SC/PRB = %d 子载波\n', num_prb, sc_per_prb, total_sc);

%% 快速模式检测
try
    batch_mode = getenv('OTFS_BATCH_MODE');
    if strcmp(batch_mode, '1')
        % 完整仿真：论文标准参数
        fprintf('  🔬 完整仿真模式：17 SNR 点，100 trials\n');
        fprintf('     预计时间：30-60 分钟\n');
    end
catch
end

%% 仿真
for snr_idx = 1:length(SNR_dB)
    snr = SNR_dB(snr_idx);
    noise_var = 10^(-snr / 10);
    
    fprintf('\n  SNR = %2d dB [%2d/%2d]\n', snr, snr_idx, length(SNR_dB));
    
    for curve_idx = 1:4
        otfs_flag = (curve_idx <= 2);
        mod_ord = mod_orders(otfs_flag + 1);
        k = log2(mod_ord);
        
        % 确保比特数是 k 的整数倍
        pkt_bits_raw = total_sc * M_val * k * code_rate;
        pkt_bits = floor(pkt_bits_raw / k) * k;

        if otfs_flag
            sys_name = 'OTFS';
        else
            sys_name = 'OFDM';
        end
        fprintf('    %s-%dQAM R1/2 ... ', sys_name, mod_ord);
        
        % 构建星座: 使用 k 的整数倍比特数
        test_bits = randi([0,1], 1, k*20);
        constell = unique(qam_mod(test_bits, mod_ord));
        % Octave 兼容：按绝对值排序
        [~, sort_idx] = sort(abs(constell));
        constell = constell(sort_idx);
        
        block_errors = 0;
        total_blocks = 0;
        max_trials = 100;
        
        for trial = 1:max_trials
            tx_bits = randi([0, 1], 1, pkt_bits);
            data_syms = qam_mod(tx_bits, mod_ord);
            num_syms = length(data_syms);

            % 放置到 DD 域网格
            X_dd = zeros(N, M_val);
            if otfs_flag
                % OTFS: 填充到可用网格
                X_dd(1:min(num_syms, N*M_val)) = data_syms(1:min(num_syms, N*M_val));
                tx_vec = otfs_modulate(X_dd, N, M_val, cp_len);
                h_dd = tdlc_channel(N, M_val, fd, fs, cfg.tdlc_delays_ns, cfg.tdlc_powers_dB);
                rx_vec = apply_channel_otfs(tx_vec, h_dd, N, M_val, cp_len);
                rx_vec = rx_vec + sqrt(noise_var/2) * (randn(size(rx_vec)) + 1j*randn(size(rx_vec)));
                
                Y_dd = otfs_demodulate(rx_vec, N, M_val, cp_len);
                X_hat = mmse_equalizer(Y_dd, h_dd, noise_var);
                rx_syms = X_hat(1:total_sc, :);
            else
                % OFDM: 使用第一个 OFDM 符号
                freq_syms = data_syms(1:min(num_syms, total_sc));
                if length(freq_syms) < total_sc
                    freq_syms = [freq_syms; zeros(total_sc - length(freq_syms), 1)];
                end
                
                % OFDM CP 长度按比例缩放 (确保 < total_sc)
                ofdm_cp_len = min(cp_len, floor(total_sc / 4));
                tx_ofdm = ofdm_modulate(freq_syms, total_sc, ofdm_cp_len);
                
                % 时域多径信道
                h_time = zeros(ofdm_cp_len + 1, 1);
                for tap = 1:length(cfg.tdlc_delays_ns)
                    delay_samples = round(cfg.tdlc_delays_ns(tap) * 1e-9 * fs);
                    if delay_samples <= ofdm_cp_len
                        h_time(delay_samples + 1) = sqrt(10^(cfg.tdlc_powers_dB(tap)/10)) * ...
                            (randn + 1j*randn) / sqrt(2);
                    end
                end
                h_time = h_time / sqrt(sum(abs(h_time).^2) + eps);

                rx_ofdm = apply_channel_ofdm(tx_ofdm, h_time, total_sc, ofdm_cp_len, 1);
                rx_ofdm = rx_ofdm + sqrt(noise_var/2) * (randn(size(rx_ofdm)) + 1j*randn(size(rx_ofdm)));

                Y_freq = ofdm_demodulate(rx_ofdm, total_sc, ofdm_cp_len, 1);
                h_freq = fft(h_time, total_sc);
                X_hat = mmse_equalizer(Y_freq, h_freq, noise_var);
                rx_syms = reshape(X_hat, total_sc, 1);
            end
            
            rx_bits = qam_demod(rx_syms(:)', mod_ord, noise_var, 'hard');
            comp_len = min(length(tx_bits), length(rx_bits));
            
            if any(tx_bits(1:comp_len) ~= rx_bits(1:comp_len))
                block_errors = block_errors + 1;
            end
            total_blocks = total_blocks + 1;
            
            if block_errors >= 100 && total_blocks >= 100
                break;
            end
        end
        
        bler_results(snr_idx, curve_idx) = block_errors / total_blocks;
        fprintf('BLER=%.4f (%d/%d)\n', bler_results(snr_idx, curve_idx), block_errors, total_blocks);
    end
end

%% 保存结果到 output 目录
%output_dir = fullfile(project_root, 'output');
%if ~exist(output_dir, 'dir')
 %   mkdir(output_dir);
%end

% 裁剪到实际仿真范围
%bler_results = bler_results(1:length(SNR_dB), :);

%save(fullfile(output_dir, 'fig7_data.mat'), 'SNR_dB', 'bler_results');

%fprintf('数据已保存到: %s\n', fullfile(output_dir, 'fig7_data.mat'));
%fprintf('\n===== 图7仿真完成 =====\n');




%% 保存结果到 output 目录
output_dir = fullfile(project_root, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 裁剪到实际仿真范围
bler_results = bler_results(1:length(SNR_dB), :);

% 输出文件路径
output_file = fullfile(output_dir, 'fig7_data.mat');

% 保存数据
save(output_file, 'SNR_dB', 'bler_results');

% 安全检查文件是否生成
finfo = dir(output_file);
if ~isempty(finfo)
    fprintf('数据已保存到: %s (%.1f KB)\n', output_file, finfo.bytes/1024);
else
    warning('数据文件未生成: %s', output_file);
end

fprintf('\n===== 图7仿真完成 =====\n');