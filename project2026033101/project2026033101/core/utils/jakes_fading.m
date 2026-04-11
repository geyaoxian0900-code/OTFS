function fading_env = jakes_fading(num_samples, fd, fs)
% JAKES_FADING - Jakes 相关瑞利衰落生成器
%
% 输入:
%   num_samples - 生成的样本点数
%   fd          - 最大多普勒频移 (Hz)
%   fs          - 采样频率 (Hz)
%
% 输出:
%   fading_env  - 衰落包络（实数正数向量），单位平均功率

    % 构造 Jakes PSD
    f_base = (-floor(num_samples/2) : floor((num_samples-1)/2)) * (fs / num_samples);
    f_base = f_base(:);
    
    fd_eff = max(fd, eps);
    norm_factor = 1 / (pi * fd_eff);
    jakes_psd = zeros(size(f_base));
    inside_band = abs(f_base) < fd_eff;
    jakes_psd(inside_band) = norm_factor ./ sqrt(max(eps, 1 - (f_base(inside_band) / fd_eff).^2));
    
    % 复高斯白噪声
    g_noise = randn(num_samples, 1) + 1j * randn(num_samples, 1);
    
    % 频域滤波
    G_freq = fft(g_noise);
    H_filter = sqrt(jakes_psd);
    filtered_G = G_freq .* H_filter;
    h_time = ifft(filtered_G);
    
    % 归一化为单位平均功率
    avg_power = mean(abs(h_time).^2);
    fading_env = abs(h_time) / sqrt(max(avg_power, eps));
end
