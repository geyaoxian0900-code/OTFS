%% run('scripts/run_fig5.m') - 一键运行 Figure 5-9 全部仿真
%
% 本脚本会自动：
% 1. 设置项目路径
% 2. 依次运行 Figure 5 到 Figure 9
% 3. 所有结果保存到 output/ 目录（仅 .mat 和 .png 格式）
% 4. 显示详细进度和统计信息
%
% 用法：在 Octave/MATLAB 中直接运行 run('run_all_figures.m')
% 或在命令行：octave-cli --no-gui --eval "run('run_all_figures.m')"
%
% 作者：OTFS 仿真系统
% 日期：2026-04-06

clear; close all; clc;

%% ========== 系统初始化 ==========
fprintf('\n');
fprintf('================================================\n');
fprintf('  OTFS vs OFDM 批量仿真系统 v2.0\n');
fprintf('  论文复现: arXiv 1808.00519\n');
fprintf('================================================\n\n');

% 获取项目根目录
project_root = fileparts(mfilename('fullpath'));

% 显式添加所有核心模块路径
fprintf('[1/4] 初始化项目路径...\n');
addpath(fullfile(project_root, 'config'));
addpath(fullfile(project_root, 'core', 'modulation'));
addpath(fullfile(project_root, 'core', 'channel'));
addpath(fullfile(project_root, 'core', 'equalizer'));
addpath(fullfile(project_root, 'core', 'utils'));
fprintf('      路径配置完成\n\n');

% 创建输出目录
fprintf('[2/4] 创建输出目录...\n');
output_dir = fullfile(project_root, 'output');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
fprintf('      输出目录: %s\n\n', output_dir);

% 设置快速模式
fprintf('[3/4] 设置仿真模式...\n');
quick_test_mode = false;
setenv('OTFS_BATCH_MODE', '1');
if quick_test_mode
    fprintf('      模式: 快速验证 (减少 SNR 点和试验次数)\n\n');
else
    fprintf('      模式: 完整仿真 (需要 2-6 小时)\n\n');
end

% 配置 graphics toolkit (兼容 MATLAB 和 Octave)
fprintf('[4/4] 配置图形环境...\n');
graphics_configured = false;
is_octave = exist('OCTAVE_VERSION', 'builtin') > 0;
is_headless = false;

% 检测无头环境 (Octave --no-gui 或无 DISPLAY)
if is_octave
    display_var = getenv('DISPLAY');
    if isempty(display_var) || strcmp(display_var, '')
        is_headless = true;
    end
end

if is_headless
    fprintf('      无头模式: 仅保存数据 (.mat)，不生成图片\n');
    fprintf('      提示: 在桌面环境运行 run_all_figures.m 可生成图片\n\n');
elseif is_octave
    try
        graphics_toolkit('gnuplot');
        graphics_configured = true;
        fprintf('      图形工具包: gnuplot (Octave)\n\n');
    catch
        try
            graphics_toolkit('fltk');
            graphics_configured = true;
            fprintf('      图形工具包: fltk (Octave)\n\n');
        catch
            fprintf('      警告: 无法设置图形工具包，将仅保存数据\n\n');
        end
    end
else
    % MATLAB 不需要设置
    graphics_configured = true;
    fprintf('      图形工具包: MATLAB 默认\n\n');
end

%% ========== 记录开始时间 ==========
start_time = clock;
fprintf('仿真开始时间: %04d-%02d-%02d %02d:%02d:%02d\n\n', ...
    start_time(1), start_time(2), start_time(3), start_time(4), start_time(5), round(start_time(6)));

%% ========== 运行仿真 ==========
total_figures = 5;
success_count = 0;
fail_count = 0;
failed_figures = {};

% ---------- Figure 5: 未编码 BER vs SNR ----------
fprintf('----------------------------------------\n');
fprintf('[1/5] Figure 5: 未编码 BER vs SNR\n');
fprintf('      TDL-C, 120km/h, QPSK/16QAM/64QAM/256QAM\n');
fprintf('----------------------------------------\n\n');

try
    run(fullfile(project_root, 'scripts', 'run_fig5.m'));
    
    % 生成 Figure 5 图片
    data5 = load(fullfile(output_dir, 'fig5_data.mat'));
    fig5_file = fullfile(output_dir, 'fig5_uncoded_ber_comparison.png');
    
    if generate_fig5(data5, fig5_file, graphics_configured)
        fprintf('      图片已保存\n');
    end
    
    fprintf('\n[OK] Figure 5 完成\n\n');
    success_count = success_count + 1;
catch ME
    fprintf('\n[FAIL] Figure 5 失败: %s\n\n', ME.message);
    fail_count = fail_count + 1;
    failed_figures{end+1} = 'Figure 5';
end

% ---------- Figure 6: 编码 PER vs SNR ----------
fprintf('----------------------------------------\n');
fprintf('[2/5] Figure 6: 编码 PER vs SNR\n');
fprintf('      TDL-C, 120km/h, QPSK R=1/2\n');
fprintf('----------------------------------------\n\n');

try
    run(fullfile(project_root, 'scripts', 'run_fig6.m'));
    
    data6 = load(fullfile(output_dir, 'fig6_data.mat'));
    fig6_file = fullfile(output_dir, 'fig6_per_vs_snr.png');
    
    if generate_fig6(data6, fig6_file, graphics_configured)
        fprintf('      图片已保存\n');
    end
    
    fprintf('\n[OK] Figure 6 完成\n\n');
    success_count = success_count + 1;
catch ME
    fprintf('\n[FAIL] Figure 6 失败: %s\n\n', ME.message);
    fail_count = fail_count + 1;
    failed_figures{end+1} = 'Figure 6';
end

% ---------- Figure 7: 短包 BLER ----------
fprintf('----------------------------------------\n');
fprintf('[3/5] Figure 7: 短包 BLER vs SNR\n');
fprintf('      TDL-C, 30km/h, 4PRB, 16QAM/64QAM\n');
fprintf('----------------------------------------\n\n');

try
    run(fullfile(project_root, 'scripts', 'run_fig7.m'));
    
    data7 = load(fullfile(output_dir, 'fig7_data.mat'));
    fig7_file = fullfile(output_dir, 'fig7_bler_short_packet.png');
    
    if generate_fig7(data7, fig7_file, graphics_configured)
        fprintf('      图片已保存\n');
    end
    
    fprintf('\n[OK] Figure 7 完成\n\n');
    success_count = success_count + 1;
catch ME
    fprintf('\n[FAIL] Figure 7 失败: %s\n\n', ME.message);
    fail_count = fail_count + 1;
    failed_figures{end+1} = 'Figure 7';
end

% ---------- Figure 8: 不同 PRB 配置 ----------
fprintf('----------------------------------------\n');
fprintf('[4/5] Figure 8: 不同 PRB 配置的 PER\n');
fprintf('      TDL-C, 120km/h, QPSK R=1/2\n');
fprintf('----------------------------------------\n\n');

try
    run(fullfile(project_root, 'scripts', 'run_fig8.m'));
    
    data8 = load(fullfile(output_dir, 'fig8_data.mat'));
    fig8_file = fullfile(output_dir, 'fig8_per_different_prb.png');
    
    if generate_fig8(data8, fig8_file, graphics_configured)
        fprintf('      图片已保存\n');
    end
    
    fprintf('\n[OK] Figure 8 完成\n\n');
    success_count = success_count + 1;
catch ME
    fprintf('\n[FAIL] Figure 8 失败: %s\n\n', ME.message);
    fail_count = fail_count + 1;
    failed_figures{end+1} = 'Figure 8';
end

% ---------- Figure 9: SNR 时间演化 ----------
fprintf('----------------------------------------\n');
fprintf('[5/5] Figure 9: SNR 时间演化与 CDF\n');
fprintf('      ETU, 120km/h, OFDM vs OTFS\n');
fprintf('----------------------------------------\n\n');

try
    run(fullfile(project_root, 'scripts', 'run_fig9.m'));
    
    data9 = load(fullfile(output_dir, 'fig9_data.mat'));
    fig9_file = fullfile(output_dir, 'fig9_snr_evolution_cdf.png');
    
    if generate_fig9(data9, fig9_file, graphics_configured)
        fprintf('      图片已保存\n');
    end
    
    fprintf('\n[OK] Figure 9 完成\n\n');
    success_count = success_count + 1;
catch ME
    fprintf('\n[FAIL] Figure 9 失败: %s\n\n', ME.message);
    fail_count = fail_count + 1;
    failed_figures{end+1} = 'Figure 9';
end

%% ========== 仿真总结 ==========
end_time = clock;
elapsed_seconds = etime(end_time, start_time);
elapsed_hours = floor(elapsed_seconds / 3600);
elapsed_minutes = floor(mod(elapsed_seconds, 3600) / 60);
elapsed_secs = round(mod(elapsed_seconds, 60));

fprintf('================================================\n');
fprintf('  仿真完成总结\n');
fprintf('================================================\n\n');

fprintf('统计:\n');
fprintf('  总数: %d | 成功: %d | 失败: %d\n\n', total_figures, success_count, fail_count);

if fail_count > 0
    fprintf('失败的图表:\n');
    for i = 1:length(failed_figures)
        fprintf('  - %s\n', failed_figures{i});
    end
    fprintf('\n');
end

fprintf('运行时间:\n');
fprintf('  总计: %d 小时 %d 分钟 %d 秒\n\n', elapsed_hours, elapsed_minutes, elapsed_secs);

% 输出文件列表
fprintf('输出文件 (%s):\n', output_dir);
if exist(output_dir, 'dir')
    files = dir(fullfile(output_dir, '*.*'));
    total_size = 0;
    file_count = 0;

    for i = 1:length(files)
        if ~files(i).isdir && ~startsWith(files(i).name, '.')
            fprintf('  - %-45s %8.1f KB\n', files(i).name, files(i).bytes/1024);
            total_size = total_size + files(i).bytes;
            file_count = file_count + 1;
        end
    end

    fprintf('\n  总计: %d 个文件, %.1f MB\n\n', file_count, total_size/(1024*1024));
end

% 最终状态
if success_count == total_figures
    fprintf('================================================\n');
    fprintf('  所有仿真成功完成!\n');
    fprintf('================================================\n');
elseif success_count > 0
    fprintf('================================================\n');
    fprintf('  部分仿真完成 (%d/%d)\n', success_count, total_figures);
    fprintf('================================================\n');
else
    fprintf('================================================\n');
    fprintf('  所有仿真均失败\n');
    fprintf('================================================\n');
end

fprintf('\n');

%% ========== 辅助函数 ==========

function success = generate_fig5(data, fig_file, graphics_ok)
% 生成 Figure 5: 未编码 BER vs SNR
    success = false;
    if ~isfield(data, 'ber_results')
        fprintf('      跳过图片生成 (数据不完整)\n');
        return;
    end
    
    SNR_dB = data.SNR_dB;
    ber_results = data.ber_results;
    num_mod = size(ber_results, 2);
    
    mod_names_all = {'QPSK', '16-QAM', '64-QAM', '256-QAM'};
    if num_mod < length(mod_names_all)
        mod_names_all = mod_names_all(1:num_mod);
    end
    
    try
        fig = figure('Visible', 'off');
        hold on; box on; grid on;
        
        line_styles_mod = {'-', '--', ':', '-.'};
        color_mmse = [0, 0.4470, 0.7410];
        color_dfe = [0.8500, 0.3250, 0.0980];
        color_genie = [0.4660, 0.6740, 0.1880];
        color_ofdm = [0.5, 0.5, 0.5];
        
        for m_idx = 1:num_mod
            ls = line_styles_mod{m_idx};
            semilogy(SNR_dB, ber_results(:, m_idx, 1), [ls, 'o'], 'Color', color_mmse, 'LineWidth', 1.6, 'MarkerSize', 5);
            semilogy(SNR_dB, ber_results(:, m_idx, 2), [ls, 's'], 'Color', color_dfe, 'LineWidth', 1.6, 'MarkerSize', 5);
            semilogy(SNR_dB, ber_results(:, m_idx, 3), [ls, '^'], 'Color', color_genie, 'LineWidth', 1.6, 'MarkerSize', 5);
            semilogy(SNR_dB, ber_results(:, m_idx, 4), [ls, 'd'], 'Color', color_ofdm, 'LineWidth', 1.6, 'MarkerSize', 5);
        end
        
        hold off;
        xlim([0, 40]);
        ylim([1e-7, 1]);
        xlabel('SNR [dB]', 'FontSize', 13, 'FontWeight', 'bold');
        ylabel('Uncoded BER', 'FontSize', 13, 'FontWeight', 'bold');
        title('TDL-C, 444 Hz (120 Kph), 1x1, Ideal Ch.Est', 'FontSize', 14, 'FontWeight', 'bold');
        set(gca, 'FontSize', 11, 'LineWidth', 1.2);
        
        legend_entries = {};
        for m_idx = 1:num_mod
            legend_entries{end+1} = sprintf('%s MMSE', mod_names_all{m_idx});
            legend_entries{end+1} = sprintf('%s DFE', mod_names_all{m_idx});
            legend_entries{end+1} = sprintf('%s DFE(G)', mod_names_all{m_idx});
            legend_entries{end+1} = sprintf('%s OFDM', mod_names_all{m_idx});
        end
        legend(legend_entries, 'Location', 'southwest', 'FontSize', 9);
        
        % 保存图片
        if graphics_ok
            try
                print(fig, '-dpng', '-r150', fig_file);
                success = true;
            catch
                try
                    saveas(fig, fig_file);
                    success = true;
                catch
                    fprintf('      警告: 图片保存失败\n');
                end
            end
        end
        close(fig);
    catch
        fprintf('      警告: 图片生成失败\n');
    end
end

function success = generate_fig6(data, fig_file, graphics_ok)
% 生成 Figure 6: 编码 PER vs SNR
    success = false;
    if ~isfield(data, 'per_results_1')
        return;
    end
    
    try
        fig = figure('Visible', 'off');
        hold on; box on; grid on;
        
        eq_names = {'OTFS-Iter', 'OTFS-DFE(Genie)', 'OTFS-DFE', 'OTFS-MMSE', 'OFDM-MMSE'};
        colors = {[0, 0.4470, 0.7410], [0.8500, 0.3250, 0.0980], [0.4660, 0.6740, 0.1880], [0, 0.75, 0.75], [0, 0, 0]};
        line_styles = {'-', '-', '-', '--', '-.'};
        
        for eq_idx = 1:5
            semilogy(data.SNR_dB_1, data.per_results_1(:, eq_idx), line_styles{eq_idx}, ...
                'Color', colors{eq_idx}, 'LineWidth', 1.8);
        end
        
        hold off;
        xlim([0, 9]); ylim([1e-4, 1]);
        xlabel('SNR [dB]', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('PER', 'FontSize', 12, 'FontWeight', 'bold');
        title('TDL-C, 444 Hz (120 Kph), 1x1, QPSK 1/2', 'FontSize', 12, 'FontWeight', 'bold');
        legend(eq_names, 'Location', 'northeast', 'FontSize', 9);
        
        if graphics_ok
            try
                print(fig, '-dpng', '-r150', fig_file);
                success = true;
            catch
                try
                    saveas(fig, fig_file);
                    success = true;
                catch
                end
            end
        end
        close(fig);
    catch
    end
end

function success = generate_fig7(data, fig_file, graphics_ok)
% 生成 Figure 7: 短包 BLER
    success = false;
    if ~isfield(data, 'bler_results')
        return;
    end
    
    try
        fig = figure('Visible', 'off');
        hold on; box on; grid on;
        
        color_otfs_blue = [0, 0.4470, 0.7410];
        color_ofdm_red = [0.8500, 0.3250, 0.0980];
        
        semilogy(data.SNR_dB, data.bler_results(:, 1), '-', 'Color', color_otfs_blue, 'LineWidth', 2.2);
        semilogy(data.SNR_dB, data.bler_results(:, 2), '-', 'Color', color_ofdm_red, 'LineWidth', 2.2);
        semilogy(data.SNR_dB, data.bler_results(:, 3), '--', 'Color', color_otfs_blue, 'LineWidth', 2.2);
        semilogy(data.SNR_dB, data.bler_results(:, 4), '--', 'Color', color_ofdm_red, 'LineWidth', 2.2);
        
        hold off;
        xlim([8, 24]); ylim([1e-3, 1]);
        xlabel('SNR [dB]', 'FontSize', 13, 'FontWeight', 'bold');
        ylabel('BLER', 'FontSize', 13, 'FontWeight', 'bold');
        title('TDL-C, 30kmph, 4RB', 'FontSize', 14, 'FontWeight', 'bold');
        legend({'OTFS 16QAM', 'OFDM 16QAM', 'OTFS 64QAM', 'OFDM 64QAM'}, ...
            'Location', 'northeast', 'FontSize', 11);
        
        if graphics_ok
            try
                print(fig, '-dpng', '-r150', fig_file);
                success = true;
            catch
                try
                    saveas(fig, fig_file);
                    success = true;
                catch
                end
            end
        end
        close(fig);
    catch
    end
end

function success = generate_fig8(data, fig_file, graphics_ok)
% 生成 Figure 8: 不同 PRB 配置
    success = false;
    if ~isfield(data, 'per_otfs')
        return;
    end
    
    try
        fig = figure('Visible', 'off');
        hold on; grid on; box on;
        
        color_otfs = [0, 0.4470, 0.7410];
        color_ofdm = [0.8500, 0.3250, 0.0980];
        
        for p = 1:length(data.prb_configs)
            num_prb = data.prb_configs(p);
            switch num_prb
                case 50, ls = '-';
                case 16, ls = '--';
                case 8, ls = ':';
                case 4, ls = '-.';
                case 2, ls = '-';
            end
            semilogy(data.SNR_dB, data.per_otfs(:,p), ls, 'Color', color_otfs, 'LineWidth', 1.5);
            semilogy(data.SNR_dB, data.per_ofdm(:,p), ls, 'Color', color_ofdm, 'LineWidth', 1.5);
        end
        
        xlim([0, 18]); ylim([1e-3, 1e0]);
        set(gca, 'YScale', 'log');
        xlabel('SNR [dB]', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('PER', 'FontSize', 12, 'FontWeight', 'bold');
        
        legend_entries = cell(2 * length(data.prb_configs), 1);
        for p = 1:length(data.prb_configs)
            legend_entries{2*p-1} = sprintf('OTFS (%d PRB)', data.prb_configs(p));
            legend_entries{2*p} = sprintf('OFDM (%d PRB)', data.prb_configs(p));
        end
        legend(legend_entries, 'Location', 'northeast', 'FontSize', 9);
        
        if graphics_ok
            try
                print(fig, '-dpng', '-r150', fig_file);
                success = true;
            catch
                try
                    saveas(fig, fig_file);
                    success = true;
                catch
                end
            end
        end
        close(fig);
    catch
    end
end

function success = generate_fig9(data, fig_file, graphics_ok)
% 生成 Figure 9: SNR 时间演化与 CDF
    success = false;
    if ~isfield(data, 'time_axis')
        return;
    end
    
    try
        fig = figure('Visible', 'off');
        
        % 左图: SNR vs time
        subplot(1, 2, 1);
        plot(data.time_axis, 10*log10(data.snr_ofdm), '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 0.8);
        hold on;
        plot(data.time_axis, 10*log10(data.snr_otfs_10ms), '-', 'Color', [0, 0.45, 0.74], 'LineWidth', 1.5);
        plot(data.time_axis(1:8:end), 10*log10(data.snr_otfs_1ms(1:8:end)), 'o', 'Color', [0, 0, 0], 'MarkerSize', 3);
        hold off;
        grid on;
        xlabel('time (s)', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('SNR (dB)', 'FontSize', 11, 'FontWeight', 'bold');
        title('ETU, 120 km/h', 'FontSize', 12, 'FontWeight', 'bold');
        xlim([0, 0.7]);
        ylim([5, 35]);
        legend('OFDM', 'OTFS 10 ms', 'OTFS 1 ms', 'Location', 'northeast', 'FontSize', 9);
        
        % 右图: CDF
        subplot(1, 2, 2);
        if isfield(data, 'cdf_snr') && isfield(data, 'cdf_ofdm')
            semilogy(data.cdf_snr, data.cdf_ofdm, '-', 'Color', [0.85, 0.33, 0.10], 'LineWidth', 2);
            hold on;
            if isfield(data, 'cdf_otfs_10ms')
                semilogy(data.cdf_snr, data.cdf_otfs_10ms, '-', 'Color', [0, 0.45, 0.74], 'LineWidth', 2);
            end
            if isfield(data, 'cdf_otfs_1ms')
                semilogy(data.cdf_snr, data.cdf_otfs_1ms, '-', 'Color', [0, 0, 0], 'LineWidth', 2);
            end
            hold off;
        end
        grid on;
        xlabel('SNR (dB)', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('CDF', 'FontSize', 11, 'FontWeight', 'bold');
        title('ETU, 120 km/h', 'FontSize', 12, 'FontWeight', 'bold');
        xlim([0, 35]);
        ylim([1e-3, 1]);
        legend('OFDM', 'OTFS 10 ms', 'OTFS 1 ms', 'Location', 'southeast', 'FontSize', 9);
        
        if graphics_ok
            try
                print(fig, '-dpng', fig_file);
                success = true;
            catch
                try
                    saveas(fig, fig_file);
                    success = true;
                catch
                end
            end
        end
        close(fig);
    catch
    end
end
