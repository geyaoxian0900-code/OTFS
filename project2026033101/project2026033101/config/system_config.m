%% system_config.m - 系统参数配置（基于论文 arXiv 1808.00519 Table I）
%
% 本文件定义了所有论文标准参数，确保仿真与论文完全一致
% 所有其他模块都应从这里读取配置

function cfg = system_config(scenario)
% SYSTEM_CONFIG 返回系统配置参数
%
% 输入:
%   scenario - 场景名称: 'fig5', 'fig6', 'fig7', 'fig8', 'fig9'
%
% 输出:
%   cfg - 配置结构体

    %% ========== 论文 Table I 标准参数 ==========
    % 这些参数来自论文的 Table I，不应修改
    
    cfg.carrier_frequency = 4e9;        % 载波频率: 4 GHz
    cfg.duplex_mode = 'FDD';            % 双工模式: FDD
    cfg.subcarrier_spacing = 15e3;      % 子载波间隔: 15 kHz
    cfg.fft_size = 1024;                % FFT 大小: 1024 点
    cfg.bandwidth_prb = 50;             % 带宽: 50 个 PRB (600 子载波)
    cfg.cp_duration = 4.7e-6;           % 循环前缀: 4.7 μs
    cfg.antenna_config = '1x1';         % 天线配置: SISO
    cfg.channel_model = 'TDL-C';        % 信道模型: TDL-C
    cfg.delay_spread = 300e-9;          % 时延扩展: 300 ns
    cfg.channel_estimation = 'Ideal';   % 信道估计: 理想
    
    %% ========== 采样频率和 CP 长度计算 ==========
    cfg.fs = cfg.fft_size * cfg.subcarrier_spacing;  % 采样频率 = 15.36 MHz
    cfg.cp_len = round(cfg.cp_duration * cfg.fs);    % CP 长度 ≈ 72 采样点
    
    %% ========== 场景特定参数 ==========
    switch scenario
        case 'fig5'
            % Figure 5: 未编码 BER vs SNR
            cfg.N = 128;                    % OTFS 时延维度
            cfg.M = 64;                     % OTFS 多普勒维度
            cfg.velocity = 120;             % 移动速度: 120 km/h
            cfg.modulation_orders = [4, 16, 64, 256];  % QPSK, 16QAM, 64QAM, 256QAM
            cfg.snr_range = 0:2:40;         % SNR 范围: 0-40 dB
            cfg.encoding = false;           % 无编码
            cfg.equalizers = {'OTFS-MMSE', 'OTFS-DFE', 'OTFS-DFE(Genie)', 'OFDM-MMSE'};
            
        case 'fig6'
            % Figure 6: 编码 PER vs SNR
            cfg.N = 128;
            cfg.M = 64;
            cfg.velocity = 120;
            cfg.subfig1 = struct(...
                'modulation', 4, ...        % QPSK
                'code_rate', 1/2, ...
                'snr_range', 0:1:9);
            cfg.subfig2 = struct(...
                'modulation', 64, ...       % 64QAM
                'code_rate', 2/3, ...
                'snr_range', 0:1:30);
            cfg.encoding = true;
            cfg.equalizers = {'OTFS-Iter', 'OTFS-DFE(Genie)', 'OTFS-DFE', 'OTFS-MMSE', 'OFDM-MMSE'};
            
        case 'fig7'
            % Figure 7: 短包 BLER
            cfg.N = 128;
            cfg.M = 32;
            cfg.velocity = 30;              % 30 km/h
            cfg.num_prb = 4;                % 4 个 PRB
            cfg.modulation_orders = [16, 64];
            cfg.code_rate = 1/2;
            cfg.snr_range = 8:1:24;
            cfg.encoding = true;
            
        case 'fig8'
            % Figure 8: 不同 PRB 配置
            cfg.N = 128;
            cfg.M = 64;
            cfg.velocity = 120;
            cfg.prb_configs = [50, 16, 8, 4, 2];
            cfg.modulation = 4;             % QPSK
            cfg.code_rate = 1/2;
            cfg.snr_range = 0:0.5:18;
            cfg.encoding = true;
            
        case 'fig9'
            % Figure 9: SNR 时间演化（使用 ETU 信道）
            cfg.channel_model = 'ETU';      % Figure 9 使用 ETU 信道
            cfg.velocity = 120;
            cfg.time_duration = 0.7;        % 仿真时长: 0.7 秒
            cfg.sampling_rate = 10000;      % 采样率: 10 kHz
            cfg.avg_snr_db = 23;            % 平均 SNR: 23 dB
            cfg.otfs_windows = [1e-3, 10e-3];  % OTFS 时间窗口: 1ms, 10ms
            
        otherwise
            error('未知场景: %s', scenario);
    end
    
    %% ========== 计算多普勒频移 ==========
    c_light = 3e8;  % 光速
    cfg.fd = round(cfg.carrier_frequency * cfg.velocity/3.6 / c_light);
    
    %% ========== TDL-C 信道标准参数（3GPP TR 38.901）==========
    cfg.tdlc_delays_ns = [0, 30, 70, 90, 110, 190, 410, 490, 570, 700, 1000, 2600];
    cfg.tdlc_powers_dB = [-1, -1, -1, 0, 0, 0, -3, -5, -7, -9, -11, -14];
    
    %% ========== ETU 信道参数 ==========
    cfg.etu_delays_ns = [0, 50, 120, 200, 230, 500, 1600, 2300, 5000];
    cfg.etu_powers_dB = [-1, -1, -1, 0, 0, 0, -3, -5, -7];
end
