%% Figure 8: PER vs SNR for Different PRB Allocations
% 论文 arXiv 1808.00519 Figure 8 复现

clear; close all; clc;

% 获取项目根目录
project_root = fileparts(fileparts(mfilename('fullpath')));

% 显式添加所有核心模块路径
addpath(fullfile(project_root, 'config'));
addpath(fullfile(project_root, 'core', 'modulation'));
addpath(fullfile(project_root, 'core', 'channel'));
addpath(fullfile(project_root, 'core', 'equalizer'));
addpath(fullfile(project_root, 'core', 'utils'));

cfg = system_config('fig8');

fprintf('========================================\n');
fprintf('Figure 8: PER vs SNR (不同PRB分配)\n');
fprintf('场景: TDL-C, fd=%dHz, QPSK 1/2\n', cfg.fd);
fprintf('========================================\n\n');

N = cfg.N;
M_val = cfg.M;
cp_len = cfg.cp_len;
fd = cfg.fd;
fs = cfg.fs;

prb_configs = cfg.prb_configs;
M_ord = cfg.modulation;
code_rate = cfg.code_rate;
bits_per_symbol = log2(M_ord);
SNR_dB = cfg.snr_range;

color_otfs = [0, 0.4470, 0.7410];
color_ofdm = [0.8500, 0.3250, 0.0980];

per_otfs = zeros(length(SNR_dB), length(prb_configs));
per_ofdm = zeros(length(SNR_dB), length(prb_configs));

% 快速模式检测
try
    batch_mode = getenv('OTFS_BATCH_MODE');
    if strcmp(batch_mode, '1')
        % 完整仿真：论文标准参数（5 个 PRB 配置，完整 SNR）
        fprintf('  🔬 完整仿真模式：5 PRB 配置，37 SNR 点，100 trials\n');
        fprintf('     预计时间：2-3 小时\n');
    end
catch
end

constell = unique(qam_mod(randi([0,1],1,100), M_ord));
% Octave 兼容：按绝对值排序
[~, sort_idx] = sort(abs(constell));
constell = constell(sort_idx);

%% 仿真
for p_idx = 1:length(prb_configs)
    num_prb = prb_configs(p_idx);
    packet_bits = round(64 * num_prb * code_rate * bits_per_symbol);
    num_data_symbols = min(ceil(packet_bits / bits_per_symbol), N * M_val);
    
    fprintf('--- PRB=%d (包大小=%d bit) ---\n', num_prb, packet_bits);
    
    for snr_idx = 1:length(SNR_dB)
        snr_val = SNR_dB(snr_idx);
        noise_var = 10^(-snr_val / 10);
        
        pkt_errors_otfs = 0;
        pkt_errors_ofdm = 0;
        total_trials = 0;
        max_trials = 100;
        
        for trial = 1:max_trials
            tx_bits = randi([0, 1], 1, packet_bits);
            tx_syms = qam_mod(tx_bits, M_ord);
            
            if length(tx_syms) < num_data_symbols
                pad_bits = randi([0,1], 1, (num_data_symbols-length(tx_syms))*bits_per_symbol);
                tx_syms = [tx_syms, qam_mod(pad_bits, M_ord)];
            end
            tx_syms = tx_syms(1:num_data_symbols);
            
            X_dd = zeros(N, M_val);
            X_dd(1:num_data_symbols) = tx_syms(:);
            
            h_dd = tdlc_channel(N, M_val, fd, fs, cfg.tdlc_delays_ns, cfg.tdlc_powers_dB);
            
            % OTFS 路径
            tx_otfs = otfs_modulate(X_dd, N, M_val, cp_len);
            rx_otfs = apply_channel_otfs(tx_otfs, h_dd, N, M_val, cp_len);
            rx_otfs = rx_otfs + sqrt(noise_var/2) * (randn(size(rx_otfs)) + 1j*randn(size(rx_otfs)));
            Y_dd = otfs_demodulate(rx_otfs, N, M_val, cp_len);
            [x_hat_otfs, ~, ~] = iterative_detector(Y_dd, h_dd, noise_var, 3, M_ord, constell);
            rx_bits_otfs = qam_demod(x_hat_otfs(:), M_ord, noise_var, 'hard');
            
            comp_len = min(length(rx_bits_otfs), packet_bits);
            if any(rx_bits_otfs(1:comp_len) ~= tx_bits(1:comp_len))
                pkt_errors_otfs = pkt_errors_otfs + 1;
            end
            
            % OFDM 路径
            freq_syms = X_dd(:, 1);
            tx_ofdm = ofdm_modulate(freq_syms, N, cp_len);
            
            % 时域多径信道
            h_time = zeros(cp_len + 1, 1);
            for tap = 1:length(cfg.tdlc_delays_ns)
                delay_samples = round(cfg.tdlc_delays_ns(tap) * 1e-9 * fs);
                if delay_samples <= cp_len
                    h_time(delay_samples + 1) = sqrt(10^(cfg.tdlc_powers_dB(tap)/10)) * ...
                        (randn + 1j*randn) / sqrt(2);
                end
            end
            h_time = h_time / sqrt(sum(abs(h_time).^2) + eps);
            
            rx_ofdm = apply_channel_ofdm(tx_ofdm, h_time, N, cp_len, 1);
            rx_ofdm = rx_ofdm + sqrt(noise_var/2) * (randn(size(rx_ofdm)) + 1j*randn(size(rx_ofdm)));
            Y_freq = ofdm_demodulate(rx_ofdm, N, cp_len, 1);
            h_freq = fft(h_time, N);
            x_hat_ofdm = mmse_equalizer(Y_freq, h_freq, noise_var);
            rx_bits_ofdm = qam_demod(x_hat_ofdm(:), M_ord, noise_var, 'hard');
            
            comp_len_ofdm = min(length(rx_bits_ofdm), packet_bits);
            if any(rx_bits_ofdm(1:comp_len_ofdm) ~= tx_bits(1:comp_len_ofdm))
                pkt_errors_ofdm = pkt_errors_ofdm + 1;
            end
            
            total_trials = total_trials + 1;
            if pkt_errors_otfs >= 50 && pkt_errors_ofdm >= 50 && total_trials >= 500
                break;
            end
        end
        
        per_otfs(snr_idx, p_idx) = pkt_errors_otfs / total_trials;
        per_ofdm(snr_idx, p_idx) = pkt_errors_ofdm / total_trials;
        
        if mod(snr_idx, 6) == 0 || snr_idx == length(SNR_dB)
            fprintf('  SNR=%5.1fdB | OTFS=%.3e | OFDM=%.3e\n', ...
                snr_val, per_otfs(snr_idx,p_idx), per_ofdm(snr_idx,p_idx));
        end
    end
end

%% 保存结果到 output 目录
%output_dir = fullfile(project_root, 'output');
%if ~exist(output_dir, 'dir')
 %   mkdir(output_dir);
%end

% 裁剪到实际仿真范围
%per_otfs = per_otfs(1:length(SNR_dB), 1:length(prb_configs));
%per_ofdm = per_ofdm(1:length(SNR_dB), 1:length(prb_configs));
%prb_configs = prb_configs;  % 已在快速模式中裁剪

%save(fullfile(output_dir, 'fig8_data.mat'), 'SNR_dB', 'per_otfs', 'per_ofdm', 'prb_configs');
%fprintf('数据已保存到: %s\n', fullfile(output_dir, 'fig8_data.mat'));
%fprintf('\nFigure 8 已保存\n');



%% 保存结果到 output 目录
output_dir = fullfile(project_root, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 裁剪到实际仿真范围
per_otfs = per_otfs(1:length(SNR_dB), 1:length(prb_configs));
per_ofdm = per_ofdm(1:length(SNR_dB), 1:length(prb_configs));

% 输出文件路径
output_file = fullfile(output_dir, 'fig8_data.mat');

% 保存数据
save(output_file, 'SNR_dB', 'per_otfs', 'per_ofdm', 'prb_configs');

% 安全检查文件是否生成
finfo = dir(output_file);
if ~isempty(finfo)
    fprintf('数据已保存到: %s (%.1f KB)\n', output_file, finfo.bytes/1024);
else
    warning('数据文件未生成: %s', output_file);
end

fprintf('\n===== 图8仿真完成 =====\n');