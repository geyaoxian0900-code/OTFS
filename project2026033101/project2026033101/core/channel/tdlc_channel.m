function h_dd = tdlc_channel(N, M, fd, fs, delays_ns, powers_dB)
% TDLC_CHANNEL - TDL-C 多径信道生成器（3GPP TR 38.901）
%
% 生成 DD 域等效信道矩阵，用于 OTFS 2D 循环卷积模型:
%   Y_dd = h_dd ⊛ X_dd + V_dd
%
% 输入:
%   N          - 时延网格大小
%   M          - 多普勒网格大小
%   fd         - 最大多普勒频移 (Hz)
%   fs         - 采样频率 (Hz)
%   delays_ns  - 抽头延迟 (ns)
%   powers_dB  - 抽头功率 (dB)
%
% 输出:
%   h_dd       - DD 域等效信道矩阵 [N x M]（功率归一化为 1）

    if nargin < 5 || isempty(delays_ns)
        delays_ns = [0, 30, 70, 90, 110, 190, 410, 490, 570, 700, 1000, 2600];
    end
    if nargin < 6 || isempty(powers_dB)
        powers_dB = [-1, -1, -1, 0, 0, 0, -3, -5, -7, -9, -11, -14];
    end

    powers_lin = 10.^(powers_dB / 10);
    powers_lin = powers_lin / sum(powers_lin);

    h_dd = zeros(N, M);
    ts = 1 / fs;
    num_taps = length(delays_ns);

    % DD 域分辨率
    delay_res = 1 / (M * fs / N);  % 每个 DD delay bin 对应的时延
    doppler_res = fs / (N * M);    % 每个 DD Doppler bin 对应的多普勒

    for tap_idx = 1:num_taps
        % 时延映射到 DD 网格索引
        delay_samples = delays_ns(tap_idx) * 1e-9 / ts;
        n_idx = mod(round(delay_samples), N) + 1;

        power_tap = powers_lin(tap_idx);

        % 多普勒扩展：能量分布在多个多普勒 bin 上
        % 最大多普勒对应的 bin 索引
        max_dopp_idx = round(fd / doppler_res);
        max_dopp_idx = min(max_dopp_idx, floor(M/2));

        % 生成该抽头的多普勒维衰落
        % 使用 Jakes 谱形状
        if max_dopp_idx > 0
            % 在多普勒维生成 Jakes 衰落
            fading_seq = generate_jakes_doppler(M, fd, fs, power_tap);
        else
            % 静态信道
            fading_seq = sqrt(power_tap) * (randn(1, M) + 1j * randn(1, M)) / sqrt(2);
        end

        % 放置到 DD 域的对应时延位置
        h_dd(n_idx, :) = fading_seq;
    end

    % 归一化信道功率为 1 (||h_dd||_F^2 = 1)
    h_dd = h_dd / sqrt(sum(abs(h_dd(:)).^2) + eps);
end

function fading = generate_jakes_doppler(num_samples, fd, fs, power)
% 生成具有 Jakes 多普勒谱的衰落序列（沿多普勒维）
%
% 论文参考: Jakes, "Microwave Mobile Communications", 1974
%   Jakes PSD: S(f) = 1/(π*fd) * 1/√(1-(f/fd)²),  |f| < fd
%              S(f) = 0,                           |f| ≥ fd
%
% 算法: 滤波复高斯噪声法
%   1. 生成复高斯白噪声 n(t) ~ CN(0, 1)
%   2. 构造 Jakes PSD 平方根滤波器 H(f) = √S(f)
%   3. 频域滤波: n_filtered(t) = IFFT[FFT(n(t)) · H(f)]
%   4. 功率归一化: fading(t) = √power · n_filtered(t) / √E[|n_filtered|²]

    if fd <= 0
        % 静态信道: 无多普勒扩展
        fading = sqrt(power/2) * (randn(1, num_samples) + 1j * randn(1, num_samples));
        return;
    end

    % 多普勒频率轴
    f_axis = (-floor(num_samples/2) : floor((num_samples-1)/2)) * (fs / num_samples);
    f_axis = f_axis(:)';

    % Jakes PSD (标准公式)
    % S(f) = 1/(π*fd) * 1/√(1-(f/fd)²),  |f| < fd
    jakes_psd = zeros(size(f_axis));
    inside_band = abs(f_axis) < fd;
    
    % 标准 Jakes PSD 公式
    jakes_psd(inside_band) = 1 ./ (pi * fd * sqrt(max(eps, 1 - (f_axis(inside_band) / fd).^2)));

    % 归一化 PSD 使得总和 = num_samples (功率归一化)
    % 这确保滤波后噪声的平均功率 = 1
    total_psd = sum(jakes_psd);
    if total_psd > 0
        jakes_psd = jakes_psd / total_psd * num_samples;
    end

    % 滤波复高斯噪声
    noise = randn(num_samples, 1) + 1j * randn(num_samples, 1);
    noise_freq = fft(noise);
    H_filter = sqrt(jakes_psd);  % 幅度响应 = √PSD
    filtered = noise_freq .* H_filter;
    fading_time = ifft(filtered);

    % 功率归一化: 确保 E[|fading|²] = power
    avg_power = mean(abs(fading_time).^2);
    fading = sqrt(power) * fading_time.' / sqrt(max(avg_power, eps));
end
