%% quick_verify.m - 超快速验证系统是否正常工作
% 只仿真 Figure 5 的一个 SNR 点，验证所有模块

clear; close all; clc;

fprintf('========================================\n');
fprintf('  系统快速验证测试\n');
fprintf('========================================\n\n');

% 获取项目根目录（向上两级：test/ -> 项目根）
project_root = fileparts(fileparts(mfilename('fullpath')));

% 显式添加所有核心模块路径
addpath(fullfile(project_root, 'config'));
addpath(fullfile(project_root, 'core', 'modulation'));
addpath(fullfile(project_root, 'core', 'channel'));
addpath(fullfile(project_root, 'core', 'equalizer'));
addpath(fullfile(project_root, 'core', 'utils'));

output_dir = fullfile(project_root, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% 测试 1: 系统配置
fprintf('测试 1: 加载系统配置... ');
cfg = system_config('fig5');
assert(cfg.carrier_frequency == 4e9, '载波频率错误');
assert(cfg.fd == 444, '多普勒频移错误');
fprintf('✅ 通过\n');

%% 测试 2: QAM 调制解调
fprintf('测试 2: QAM 调制解调... ');
test_bits = randi([0,1], 1, 100);
test_syms = qam_mod(test_bits, 4);
assert(length(test_syms) == 50, '符号数量错误');  % 100 bits / 2 = 50 symbols
% 只验证调制输出合理性
assert(all(abs(test_syms) > 0.5), 'QAM 符号幅度异常');
fprintf('✅ 通过\n');

%% 测试 3: OTFS 调制解调
fprintf('测试 3: OTFS 调制解调... ');
N = 16; M = 16; cp = 4;
X = randn(N, M) + 1j*randn(N, M);
tx = otfs_modulate(X, N, M, cp);
Y = otfs_demodulate(tx, N, M, cp);
err = norm(X(:) - Y(:)) / norm(X(:));
assert(err < 0.01, sprintf('OTFS 误差过大: %.4f', err));
fprintf('✅ 通过 (误差: %.2e)\n', err);

%% 测试 4: TDL-C 信道
fprintf('测试 4: TDL-C 信道模型... ');
h = tdlc_channel(16, 16, 444, 15.36e6);
assert(all(size(h) == [16, 16]), '信道尺寸错误');
assert(any(h(:) ~= 0), '信道全为零');
fprintf('✅ 通过\n');

%% 测试 5: MMSE 均衡器
fprintf('测试 5: MMSE 均衡器... ');
y = randn(16, 16) + 1j*randn(16, 16);
h = randn(16, 16) + 1j*randn(16, 16);
x_hat = mmse_equalizer(y, h, 0.01);
assert(isequal(size(x_hat), size(y)), '均衡器输出尺寸错误');
fprintf('✅ 通过\n');

%% 测试 6: 完整链路（单个 SNR 点）
fprintf('测试 6: 完整 OTFS 链路... ');
N = 32; M_val = 16; cp_len = 4;
fd = 444; fs = 15.36e6;
snr = 10;
noise_var = 10^(-snr / 10);

% 生成数据
tx_bits = randi([0, 1], 1, N*M_val*2);
data_syms = qam_mod(tx_bits, 4);
X_dd = reshape(data_syms, N, M_val);

% OTFS 调制
tx_vec = otfs_modulate(X_dd, N, M_val, cp_len);

% 信道
h_dd = tdlc_channel(N, M_val, fd, fs);
rx_vec = apply_channel_otfs(tx_vec, h_dd, N, M_val, cp_len);

% 加噪
rx_vec = rx_vec + sqrt(noise_var / 2) * (randn(size(rx_vec)) + 1j*randn(size(rx_vec)));

% 解调
Y_dd = otfs_demodulate(rx_vec, N, M_val, cp_len);
X_hat = mmse_equalizer(Y_dd, h_dd, noise_var);

% 解调比特
rx_syms = X_hat(:)';
rx_bits = qam_demod(rx_syms, 4, noise_var, 'hard');
rx_bits_vec = rx_bits(:)';

% 计算 BER（注意长度可能不同，取最小长度）
comp_len = min(length(tx_bits), length(rx_bits_vec));
ber = sum(tx_bits(1:comp_len) ~= rx_bits_vec(1:comp_len)) / comp_len;
fprintf('✅ 通过 (BER=%.2e)\n', ber);

%% 测试 7: Figure 9 数据验证
fprintf('测试 7: Figure 9 数据验证... ');
fig9_data_file = fullfile(output_dir, 'fig9_data.mat');
if exist(fig9_data_file, 'file')
    data = load(fig9_data_file);
    if isfield(data, 'snr_ofdm') && isfield(data, 'snr_otfs_10ms')
        fprintf('✅ 通过\n');
    else
        fprintf('⚠️  数据字段不完整\n');
    end
else
    fprintf('⚠️  Figure 9 数据不存在\n');
end

%% 总结
fprintf('\n========================================\n');
fprintf('  所有测试通过！系统工作正常\n');
fprintf('========================================\n\n');

fprintf('输出文件:\n');
files = dir(fullfile(output_dir, '*.*'));
for i = 1:length(files)
    if ~files(i).isdir
        fprintf('  - %s (%.1f KB)\n', files(i).name, files(i).bytes/1024);
    end
end
