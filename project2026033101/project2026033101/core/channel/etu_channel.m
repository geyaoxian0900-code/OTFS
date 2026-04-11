function h_dd = etu_channel(N, M, fd, fs)
% ETU_CHANNEL - ETU（Extended Typical Urban）多径信道生成器
%
% 输入:
%   N   - 时延网格大小
%   M   - 多普勒网格大小
%   fd  - 最大多普勒频移 (Hz)
%   fs  - 采样频率 (Hz)
%
% 输出:
%   h_dd - DD 域等效信道矩阵 [N x M]
%
% ETU 抽头参数:
%   delays_ns = [0, 50, 120, 200, 230, 500, 1600, 2300, 5000]
%   powers_dB  = [-1, -1, -1, 0, 0, 0, -3, -5, -7]

    % ETU 信道模型参数
    delays_ns = [0, 50, 120, 200, 230, 500, 1600, 2300, 5000];
    powers_dB = [-1, -1, -1, 0, 0, 0, -3, -5, -7];
    
    % 调用 TDL-C 信道生成器（复用 Jakes 衰落逻辑）
    h_dd = tdlc_channel(N, M, fd, fs, delays_ns, powers_dB);
end
