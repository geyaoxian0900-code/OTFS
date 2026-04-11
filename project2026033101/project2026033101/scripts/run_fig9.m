%% Figure 9: 接收 SNR 时间演化与 CDF 对比
% 论文 arXiv 1808.00519 Figure 9 复现
% 使用 ETU 多径信道模型

clear; close all; clc;

% 添加项目路径
project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(project_root));

fprintf('========================================\n');
fprintf('Figure 9: SNR 演化与 CDF 仿真\n');
fprintf('========================================\n\n');

%% 系统参数
time_duration = 0.7;
sampling_rate = 10000;
num_samples = round(time_duration * sampling_rate);
time_axis = linspace(0, time_duration, num_samples);

velocity = 120;
fc = 4e9;
fd = round(fc * velocity/3.6 / 3e8);
avg_snr_db = 23;
avg_snr_lin = 10^(avg_snr_db / 10);

fprintf('信道: ETU, %d km/h, fd = %d Hz\n', velocity, fd);
fprintf('平均 SNR: %d dB\n', avg_snr_db);

%% 生成 ETU 多径衰落
etu_delays_ns = [0, 50, 120, 200, 230, 500, 1600, 2300, 5000];
etu_powers_dB = [-1, -1, -1, 0, 0, 0, -3, -5, -7];
etu_powers_lin = 10.^(etu_powers_dB / 10);
etu_powers_lin = etu_powers_lin / sum(etu_powers_lin);

num_paths = length(etu_delays_ns);
path_fading = zeros(num_samples, num_paths);

for p = 1:num_paths
    f_vec = (-floor(num_samples/2) : floor((num_samples-1)/2)) * (sampling_rate / num_samples);
    f_vec = f_vec(:);
    
    fd_path = max(abs(fd * cos(rand() * pi)), 1);
    
    S_jakes = zeros(size(f_vec));
    idx = abs(f_vec) < fd_path;
    S_jakes(idx) = 1 ./ sqrt(max(eps, 1 - (f_vec(idx)/fd_path).^2));
    S_jakes = S_jakes / sum(S_jakes) * num_samples;
    
    G = randn(num_samples, 1) + 1j * randn(num_samples, 1);
    G_freq = fft(G);
    H_filter = sqrt(S_jakes);
    filtered_G = G_freq .* H_filter;
    h_time = ifft(filtered_G);
    
    fading_env = abs(h_time) / sqrt(mean(abs(h_time).^2));
    path_fading(:, p) = fading_env * sqrt(etu_powers_lin(p));
end

instantaneous_power = sum(abs(path_fading).^2, 2);
instantaneous_power = instantaneous_power / mean(instantaneous_power);

% OFDM SNR (有快衰落)
snr_ofdm = avg_snr_lin * instantaneous_power;

% OTFS 10ms SNR (窗口平均)
window_10ms = round(0.01 * sampling_rate);
snr_otfs_10ms = movmean(snr_ofdm, window_10ms);

% OTFS 1ms SNR (窗口平均)
window_1ms = round(0.001 * sampling_rate);
snr_otfs_1ms = movmean(snr_ofdm, window_1ms);

fprintf('\nSNR 统计:\n');
fprintf('  OFDM:      std = %.2f dB\n', std(10*log10(snr_ofdm)));
fprintf('  OTFS 1ms:  std = %.2f dB\n', std(10*log10(snr_otfs_1ms)));
fprintf('  OTFS 10ms: std = %.2f dB\n', std(10*log10(snr_otfs_10ms)));

%% 计算 CDF (Octave 兼容)
nbins = 200;
edges = linspace(min([10*log10(snr_ofdm); 10*log10(snr_otfs_10ms); 10*log10(snr_otfs_1ms)]), ...
                 max([10*log10(snr_ofdm); 10*log10(snr_otfs_10ms); 10*log10(snr_otfs_1ms)]), nbins+1);

cdf_ofdm = zeros(1, nbins);
cdf_otfs_10ms = zeros(1, nbins);
cdf_otfs_1ms = zeros(1, nbins);

for i = 1:nbins
    cdf_ofdm(i) = sum(10*log10(snr_ofdm) <= edges(i+1)) / length(snr_ofdm);
    cdf_otfs_10ms(i) = sum(10*log10(snr_otfs_10ms) <= edges(i+1)) / length(snr_otfs_10ms);
    cdf_otfs_1ms(i) = sum(10*log10(snr_otfs_1ms) <= edges(i+1)) / length(snr_otfs_1ms);
end

cdf_snr = edges(1:end-1);

%% 保存数据
%output_dir = fullfile(project_root, 'output');
%if ~exist(output_dir, 'dir'), mkdir(output_dir); end

%save(fullfile(output_dir, 'fig9_data.mat'), 'time_axis', 'snr_ofdm', 'snr_otfs_10ms', 'snr_otfs_1ms', ...
%    'cdf_snr', 'cdf_ofdm', 'cdf_otfs_10ms', 'cdf_otfs_1ms');

%fprintf('数据已保存到 output/ 目录 (仅 .mat 格式)\n');
%fprintf('\n========================================\n');
%fprintf('Figure 9 完成！\n');
%fprintf('========================================\n');




%% 保存数据到 output 目录
output_dir = fullfile(project_root, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 输出文件路径
output_file = fullfile(output_dir, 'fig9_data.mat');

% 保存数据
save(output_file, 'time_axis', 'snr_ofdm', 'snr_otfs_10ms', 'snr_otfs_1ms', ...
    'cdf_snr', 'cdf_ofdm', 'cdf_otfs_10ms', 'cdf_otfs_1ms');

% 检查文件是否生成
finfo = dir(output_file);
if ~isempty(finfo)
    fprintf('数据已保存到: %s (%.1f KB)\n', output_file, finfo.bytes/1024);
else
    warning('数据文件未生成: %s', output_file);
end

fprintf('\n===== Figure 9 仿真完成 =====\n');