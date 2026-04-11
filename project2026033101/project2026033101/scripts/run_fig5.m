%% Figure 5: 未编码 BER vs SNR 对比曲线（OTFS vs OFDM）
% 论文 arXiv 1808.00519 Figure 5 复现
% 信道模型：TDL-C, fd=444Hz (120km/h), SISO, 理想信道估计

clear; close all; clc;

%% 添加路径
% 获取项目根目录
project_root = fileparts(fileparts(mfilename('fullpath')));

% 显式添加所有核心模块路径
addpath(fullfile(project_root, 'config'));
addpath(fullfile(project_root, 'core', 'modulation'));
addpath(fullfile(project_root, 'core', 'channel'));
addpath(fullfile(project_root, 'core', 'equalizer'));
addpath(fullfile(project_root, 'core', 'utils'));

%% 加载配置
cfg = system_config('fig5');

fprintf('============================================================\n');
fprintf('  图5：未编码 BER vs SNR 对比仿真\n');
fprintf('  信道模型：TDL-C, fd=%dHz (120km/h), SISO\n', cfg.fd);
fprintf('  载波频率：%.1f GHz, 子载波间隔：%.1f kHz\n', ...
    cfg.carrier_frequency/1e9, cfg.subcarrier_spacing/1e3);
fprintf('============================================================\n\n');

%% 系统参数
N = cfg.N;
M_val = cfg.M;
cp_len = cfg.cp_len;
fd = cfg.fd;
fs = cfg.fs;
SNR_dB = cfg.snr_range;
num_snr = length(SNR_dB);

mod_orders = cfg.modulation_orders;
mod_names = {'QPSK', '16-QAM', '64-QAM', '256-QAM'};
num_mod = length(mod_orders);

eq_types = cfg.equalizers;
num_eq = length(eq_types);

ber_results = zeros(num_snr, num_mod, num_eq);

%% 输出目录设置
output_dir = fullfile(project_root, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% 快速测试模式检测
% 检查环境变量或调用栈
try
    batch_mode = getenv('OTFS_BATCH_MODE');
    if strcmp(batch_mode, '1')
        % 完整仿真：论文标准参数
        % N=128, M=64, 完整 SNR 范围，4 种调制，100 次试验
        % 预计时间：2-4 小时
        fprintf('🔬 完整仿真模式：论文标准参数（N=128,M=64, 21 SNR 点，100 trials）\n');
        fprintf('   预计时间：2-4 小时\n\n');
    end
catch
end

%% 蒙特卡洛仿真
for m_idx = 1:num_mod
    M_ord = mod_orders(m_idx);
    k = log2(M_ord);
    
    fprintf('\n========== 调制方式：%s (M=%d, 每符号%d bit) ==========\n', ...
            mod_names{m_idx}, M_ord, k);
    
    % 构建星座
    test_bits = randi([0, 1], 1, 1000*k);
    test_syms = qam_mod(test_bits, M_ord);
    constell = unique(test_syms);
    % Octave 兼容：按绝对值排序
    [~, sort_idx] = sort(abs(constell));
    constell = constell(sort_idx);
    
    for snr_idx = 1:num_snr
        snr = SNR_dB(snr_idx);
        noise_var = 10^(-snr / 10);
        
        fprintf('  SNR = %2d dB [%2d/%2d] ... ', snr, snr_idx, num_snr);
        
        for eq_idx = 1:num_eq
            total_errors = 0;
            total_bits = 0;
            
            % 根据运行模式设置试验次数
            try
                [STACK, ~] = dbstack;
                is_batch = false;
                for i = 1:length(STACK)
                    if contains(STACK(i).file, 'run_all_figures')
                        is_batch = true;
                        break;
                    end
                end
                if is_batch
                    max_trials = 100;   % 完整仿真：100 次试验
                    min_errors = 50;
                else
                    max_trials = 10;  % 单独运行：标准测试
                    min_errors = 100;
                end
            catch
                max_trials = 10;
                min_errors = 100;
            end
            
            for trial = 1:max_trials
                % 生成随机比特
                num_bits = N * M_val * k;
                tx_bits = randi([0, 1], 1, num_bits);
                
                % QAM 调制
                data_syms = qam_mod(tx_bits, M_ord);
                X_dd = reshape(data_syms, N, M_val);
                
                % OTFS 调制
                tx_vec = otfs_modulate(X_dd, N, M_val, cp_len);
                
                % TDL-C 信道
                h_dd = tdlc_channel(N, M_val, fd, fs, cfg.tdlc_delays_ns, cfg.tdlc_powers_dB);
                
                % 通过信道
                rx_vec = apply_channel_otfs(tx_vec, h_dd, N, M_val, cp_len);
                
                % 添加 AWGN
                rx_vec = rx_vec + sqrt(noise_var / 2) * ...
                    (randn(size(rx_vec)) + 1j * randn(size(rx_vec)));
                
                % 接收机处理
                if eq_idx <= 3  % OTFS 接收机
                    Y_dd = otfs_demodulate(rx_vec, N, M_val, cp_len);
                    
                    switch eq_idx
                        case 1  % OTFS-MMSE
                            X_hat = mmse_equalizer(Y_dd, h_dd, noise_var);
                        case 2  % OTFS-DFE
                            X_hat = dfe_equalizer(Y_dd, h_dd, noise_var, M_ord, constell);
                        case 3  % OTFS-DFE(Genie)
                            X_hat = genie_equalizer(Y_dd, h_dd, noise_var, X_dd, constell);
                    end
                    
                    rx_syms = X_hat(:)';
                    rx_bits = qam_demod(rx_syms, M_ord, noise_var, 'hard');
                    
                else  % OFDM-MMSE
                    % OFDM: 使用第一列作为频域数据
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
                    rx_ofdm = rx_ofdm + sqrt(noise_var / 2) * ...
                        (randn(size(rx_ofdm)) + 1j * randn(size(rx_ofdm)));
                    
                    Y_freq = ofdm_demodulate(rx_ofdm, N, cp_len, 1);
                    
                    % 频域信道响应
                    h_freq = fft(h_time, N);
                    X_hat = mmse_equalizer(Y_freq, h_freq, noise_var);
                    
                    rx_syms = X_hat(:)';
                    % 只解调第一个 OFDM 符号的比特
                    rx_bits = qam_demod(rx_syms, M_ord, noise_var, 'hard');
                    tx_bits = tx_bits(1:length(rx_bits));
                end
                
                % 统计误码
                compare_len = min(length(tx_bits), length(rx_bits));
                num_err = sum(tx_bits(1:compare_len) ~= rx_bits(1:compare_len));
                total_errors = total_errors + num_err;
                total_bits = total_bits + compare_len;
                
                if total_errors >= min_errors && trial >= 200
                    break;
                end
            end
            
            ber_val = total_errors / max(total_bits, 1);
            if ber_val == 0 && snr >= 30
                ber_val = 1e-8;
            end
            
            ber_results(snr_idx, m_idx, eq_idx) = ber_val;
        end
        
        fprintf('BER=%.2e\n', ber_results(snr_idx, m_idx, 1));
    end
end

fprintf('\n===== 蒙特卡洛仿真完成！ =====\n\n');

% 裁剪到实际仿真范围
SNR_dB = SNR_dB(1:num_snr);
ber_results = ber_results(1:num_snr, 1:num_mod, :);

% 保存结果到 output 目录
%output_file = fullfile(output_dir, 'fig5_data.mat');
%save(output_file, 'SNR_dB', 'ber_results', 'mod_orders', 'eq_types');

%fprintf('数据已保存到: %s (%.1f KB)\n', output_file, (dir(output_file)).bytes/1024);

%finfo = dir(output_file);  % 获取文件信息结构体
%fprintf('数据已保存到: %s (%.1f KB)\n', output_file, finfo.bytes/1024);
%fprintf('\n===== 图5仿真全部完成 =====\n');


% 保存结果到 output 目录
output_file = fullfile(output_dir, 'fig5_data.mat');
save(output_file, 'SNR_dB', 'ber_results', 'mod_orders', 'eq_types');

% 安全获取文件信息并输出
finfo = dir(output_file);
if ~isempty(finfo)
    fprintf('数据已保存到: %s (%.1f KB)\n', output_file, finfo.bytes/1024);
else
    warning('数据文件未生成: %s', output_file);
end

fprintf('\n===== 图5仿真全部完成 =====\n');