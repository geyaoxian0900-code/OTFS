%% Figure 6: 编码 PER vs SNR 对比曲线
% 论文 arXiv 1808.00519 Figure 6 复现

clear; close all; clc;

% 获取项目根目录
project_root = fileparts(fileparts(mfilename('fullpath')));

% 显式添加所有核心模块路径
addpath(fullfile(project_root, 'config'));
addpath(fullfile(project_root, 'core', 'modulation'));
addpath(fullfile(project_root, 'core', 'channel'));
addpath(fullfile(project_root, 'core', 'equalizer'));
addpath(fullfile(project_root, 'core', 'utils'));

cfg = system_config('fig6');

fprintf('============================================================\n');
fprintf('  图6：编码 PER vs SNR 对比仿真\n');
fprintf('============================================================\n\n');

N = cfg.N;
M_val = cfg.M;
cp_len = cfg.cp_len;
fd = cfg.fd;
fs = cfg.fs;

%% 子图1: QPSK R=1/2
M_qpsk = cfg.subfig1.modulation;
k_qpsk = log2(M_qpsk);
R1 = cfg.subfig1.code_rate;
SNR_dB_1 = cfg.subfig1.snr_range;

%% 快速模式检测
try
    batch_mode = getenv('OTFS_BATCH_MODE');
    if strcmp(batch_mode, '1')
        % 完整仿真：论文标准参数
        N = 128;
        M_val = 64;
        cp_len = 72;
        max_trials_fig6 = 100;
        fprintf('  🔬 完整仿真模式：N=%d,M=%d, %d trials\n', N, M_val, max_trials_fig6);
        fprintf('     预计时间：1-2 小时\n');
    end
catch
end

%% 子图1仿真
fprintf('\n========== 子图1：QPSK, 码率R=1/2 ==========\n');
constell_qpsk = unique(qam_mod(randi([0,1],1,100), M_qpsk));
% Octave 兼容：按绝对值排序
[~, sort_idx] = sort(abs(constell_qpsk));
constell_qpsk = constell_qpsk(sort_idx);

for snr_idx = 1:length(SNR_dB_1)
    snr = SNR_dB_1(snr_idx);
    noise_var = 10^(-snr / 10);
    fprintf('  SNR = %d dB [%d/%d] ... ', snr, snr_idx, length(SNR_dB_1));
    
    for eq_idx = 1:5
        pkt_errors = 0;
        total_pkts = 0;
        try
            max_trials = max_trials_fig6;
        catch
            max_trials = 10;
        end
        
        for trial = 1:max_trials
            tx_bits = randi([0, 1], 1, N*M_val*k_qpsk);
            data_syms = qam_mod(tx_bits, M_qpsk);
            X_dd = reshape(data_syms, N, M_val);
            tx_vec = otfs_modulate(X_dd, N, M_val, cp_len);
            
            h_dd = tdlc_channel(N, M_val, fd, fs, cfg.tdlc_delays_ns, cfg.tdlc_powers_dB);
            rx_vec = apply_channel_otfs(tx_vec, h_dd, N, M_val, cp_len);
            rx_vec = rx_vec + sqrt(noise_var/2) * (randn(size(rx_vec)) + 1j*randn(size(rx_vec)));
            
            switch eq_idx
                case 1
                    Y_dd = otfs_demodulate(rx_vec, N, M_val, cp_len);
                    [X_hat, ~, ~] = iterative_detector(Y_dd, h_dd, noise_var, 3, M_qpsk, constell_qpsk);
                case 2
                    Y_dd = otfs_demodulate(rx_vec, N, M_val, cp_len);
                    X_hat = genie_equalizer(Y_dd, h_dd, noise_var, X_dd, constell_qpsk);
                case 3
                    Y_dd = otfs_demodulate(rx_vec, N, M_val, cp_len);
                    X_hat = dfe_equalizer(Y_dd, h_dd, noise_var, M_qpsk, constell_qpsk);
                case 4
                    Y_dd = otfs_demodulate(rx_vec, N, M_val, cp_len);
                    X_hat = mmse_equalizer(Y_dd, h_dd, noise_var);
                case 5
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
                    X_hat = mmse_equalizer(Y_freq, h_freq, noise_var);
            end
            
            rx_syms = X_hat(:)';
            rx_bits = qam_demod(rx_syms, M_qpsk, noise_var, 'hard');
            
            comp_len = min(length(tx_bits), length(rx_bits));
            if any(tx_bits(1:comp_len) ~= rx_bits(1:comp_len))
                pkt_errors = pkt_errors + 1;
            end
            total_pkts = total_pkts + 1;
            
            if pkt_errors >= 50 && total_pkts >= 200
                break;
            end
        end
        
        per_results_1(snr_idx, eq_idx) = pkt_errors / total_pkts;
    end
    fprintf('PER(Iter)=%.2e\n', per_results_1(snr_idx, 1));
end

%% 裁剪到实际仿真范围
SNR_dB_1 = SNR_dB_1(1:length(SNR_dB_1));
per_results_1 = per_results_1(1:length(SNR_dB_1), 1:5);

%% 保存结果到 output 目录
output_dir = fullfile(project_root, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 仅保存子图1数据
save(fullfile(output_dir, 'fig6_data.mat'), 'SNR_dB_1', 'per_results_1');
fprintf('数据已保存到: %s\n', fullfile(output_dir, 'fig6_data.mat'));
fprintf('===== 图6仿真完成 =====\n');




% 输出文件路径
%output_file = fullfile(output_dir, 'fig6_data.mat');

% 保存数据
%save(output_file, 'SNR_dB_1', 'per_results_1');

% 检查文件是否生成
%finfo = dir(output_file);
%if ~isempty(finfo)
%    fprintf('数据已保存到: %s (%.1f KB)\n', output_file, finfo.bytes/1024);
%else
%    warning('数据文件未生成: %s', output_file);
%end

%fprintf('===== 图6仿真完成 =====\n');