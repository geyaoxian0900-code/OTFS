%% test_figures.m - 从 .mat 数据通过 gnuplot 生成仿真图
% 加载 .mat 数据，写 gnuplot 脚本，直接调用 gnuplot 生成 PNG

clear; clc;
project_root = fileparts(mfilename('fullpath'));
output_dir = fullfile(project_root, 'output');

fprintf('========================================\n');
fprintf('  从 .mat 数据生成仿真图 (gnuplot)\n');
fprintf('========================================\n\n');

% 找 gnuplot
gnuplot_exe = '';
candidates = {
    'C:\Program Files\gnuplot\bin\gnuplot.exe'
    'C:\Program Files (x86)\gnuplot\bin\gnuplot.exe'
    'C:\Octave\gnuplot\bin\gnuplot.exe'
    'C:\Users\dengkaile\OneDrive\Desktop\gnuplot\bin\gnuplot.exe'
};
for i = 1:length(candidates)
    if exist(candidates{i}, 'file')
        gnuplot_exe = candidates{i};
        break;
    end
end
% 试 PATH
if isempty(gnuplot_exe)
    [s, r] = system('where gnuplot.exe 2>nul');
    if s == 0 && ~isempty(strtrim(r))
        gnuplot_exe = strtrim(r);
        % 取第一行
        nl = find(r == 10, 1);
        if ~isempty(nl), gnuplot_exe = r(1:nl-1); end
    end
end

if isempty(gnuplot_exe)
    fprintf('⚠️ gnuplot 未找到，无法生成图片\n');
    fprintf('提示: 安装 gnuplot 或在桌面环境运行 run_all_figures.m\n');
    return;
end

fprintf('gnuplot: %s\n\n', gnuplot_exe);

%% 写 gnuplot 脚本并运行
gp_file = fullfile(output_dir, 'plot_all.gp');
fid = fopen(gp_file, 'w');

fprintf(fid, '# OTFS Figure Generation\n');
fprintf(fid, 'set terminal pngcairo size 900,650 enhanced font "Arial,11"\n');
fprintf(fid, 'set output "%s"\n\n', strrep(fullfile(output_dir, 'fig5_uncoded_ber_comparison.png'), '\', '/'));

% --- Figure 5 ---
fig5_mat = fullfile(output_dir, 'fig5_data.mat');
if exist(fig5_mat, 'file')
    % 读数据写 gnuplot
    data = load(fig5_mat);
    SNR_dB = data.SNR_dB;
    ber = data.ber_results;
    num_mod = size(ber, 2);
    
    % 写数据文件
    for m_idx = 1:num_mod
        for e_idx = 1:4
            dfile = fullfile(output_dir, sprintf('tmp_f5_m%d_e%d.dat', m_idx, e_idx));
            fd = fopen(dfile, 'w');
            for i = 1:length(SNR_dB)
                v = ber(i, m_idx, e_idx);
                if v > 0
                    fprintf(fd, '%g %g\n', SNR_dB(i), v);
                end
            end
            fclose(fd);
        end
    end
    
    fprintf(fid, '# Figure 5\n');
    fprintf(fid, 'set title "TDL-C, 444Hz, QPSK" font ",14"\n');
    fprintf(fid, 'set xlabel "SNR [dB]"\n');
    fprintf(fid, 'set ylabel "Uncoded BER"\n');
    fprintf(fid, 'set logscale y\n');
    fprintf(fid, 'set yrange [1e-7:1]\n');
    fprintf(fid, 'set xrange [0:40]\n');
    fprintf(fid, 'set grid\n');
    fprintf(fid, 'set key bottom left\n');
    fprintf(fid, 'plot ');
    
    first = true;
    colors = {'#0072BD', '#D95319', '#77AC30', '#7F7F7F'};
    pt_nums = {7, 5, 9, 13};  % gnuplot point types: circle=7, square=5, triangle=9, diamond=13
    names = {'MMSE', 'DFE', 'DFE(G)', 'OFDM'};
    for m_idx = 1:num_mod
        for e_idx = 1:4
            if ~first, fprintf(fid, ', \\\n     '); end
            dfile = strrep(fullfile(output_dir, sprintf('tmp_f5_m%d_e%d.dat', m_idx, e_idx)), '\', '/');
            fprintf(fid, '"%s" w lp lc rgb "%s" pt %d ps 1.5 lw 1.6 notitle', dfile, colors{e_idx}, pt_nums{e_idx});
            first = false;
        end
    end
    fprintf(fid, '\n\n');
    
    % --- Figure 6 ---
    fprintf(fid, 'set output "%s"\n\n', strrep(fullfile(output_dir, 'fig6_per_vs_snr.png'), '\', '/'));
    fig6_mat = fullfile(output_dir, 'fig6_data.mat');
    if exist(fig6_mat, 'file')
        data6 = load(fig6_mat);
        SNR6 = data6.SNR_dB_1;
        per6 = data6.per_results_1;
        
        for e_idx = 1:5
            dfile = fullfile(output_dir, sprintf('tmp_f6_e%d.dat', e_idx));
            fd = fopen(dfile, 'w');
            for i = 1:length(SNR6)
                v = per6(i, e_idx);
                if v > 0
                    fprintf(fd, '%g %g\n', SNR6(i), v);
                end
            end
            fclose(fd);
        end
        
        fprintf(fid, 'set title "TDL-C, QPSK R=1/2" font ",12"\n');
        fprintf(fid, 'set xlabel "SNR [dB]"\n');
        fprintf(fid, 'set ylabel "PER"\n');
        fprintf(fid, 'set logscale y\n');
        fprintf(fid, 'set yrange [1e-4:1]\n');
        fprintf(fid, 'set xrange [0:9]\n');
        fprintf(fid, 'set key top right\n');
        fprintf(fid, 'plot ');
        
        colors6 = {'#0072BD', '#D95319', '#77AC30', '#00BFFF', '#000000'};
        lstyles6 = {'-', '-', '-', '--', '-.'};
        eq_names = {'OTFS-Iter', 'OTFS-DFE(G)', 'OTFS-DFE', 'OTFS-MMSE', 'OFDM-MMSE'};
        for e_idx = 1:5
            if e_idx > 1, fprintf(fid, ', \\\n     '); end
            dfile = strrep(fullfile(output_dir, sprintf('tmp_f6_e%d.dat', e_idx)), '\', '/');
            fprintf(fid, '"%s" w l lc rgb "%s" lt %d lw 1.8 title "%s"', dfile, colors6{e_idx}, e_idx, eq_names{e_idx});
        end
        fprintf(fid, '\n\n');
    end
    
    % --- Figure 7 ---
    fprintf(fid, 'set output "%s"\n\n', strrep(fullfile(output_dir, 'fig7_bler_short_packet.png'), '\', '/'));
    fig7_mat = fullfile(output_dir, 'fig7_data.mat');
    if exist(fig7_mat, 'file')
        data7 = load(fig7_mat);
        SNR7 = data7.SNR_dB;
        bler = data7.bler_results;
        
        for c_idx = 1:4
            dfile = fullfile(output_dir, sprintf('tmp_f7_c%d.dat', c_idx));
            fd = fopen(dfile, 'w');
            for i = 1:length(SNR7)
                v = bler(i, c_idx);
                if v > 0
                    fprintf(fd, '%g %g\n', SNR7(i), v);
                end
            end
            fclose(fd);
        end
        
        fprintf(fid, 'set title "TDL-C, 30kmph, 4RB" font ",14"\n');
        fprintf(fid, 'set xlabel "SNR [dB]"\n');
        fprintf(fid, 'set ylabel "BLER"\n');
        fprintf(fid, 'set logscale y\n');
        fprintf(fid, 'set yrange [1e-3:1]\n');
        fprintf(fid, 'set xrange [8:24]\n');
        fprintf(fid, 'set key top right\n');
        fprintf(fid, 'plot ');
        
        names7 = {'OTFS 16QAM', 'OFDM 16QAM', 'OTFS 64QAM', 'OFDM 64QAM'};
        for c_idx = 1:4
            if c_idx > 1, fprintf(fid, ', \\\n     '); end
            dfile = strrep(fullfile(output_dir, sprintf('tmp_f7_c%d.dat', c_idx)), '\', '/');
            if c_idx <= 2
                fprintf(fid, '"%s" w l lc rgb "#%s" lw 2.2 title "%s"', dfile, '0072BD', names7{c_idx});
            else
                fprintf(fid, '"%s" w l lc rgb "#%s" lw 2.2 title "%s"', dfile, 'D95319', names7{c_idx});
            end
        end
        fprintf(fid, '\n\n');
    end
    
    % --- Figure 8 ---
    fprintf(fid, 'set output "%s"\n\n', strrep(fullfile(output_dir, 'fig8_per_different_prb.png'), '\', '/'));
    fig8_mat = fullfile(output_dir, 'fig8_data.mat');
    if exist(fig8_mat, 'file')
        data8 = load(fig8_mat);
        SNR8 = data8.SNR_dB;
        per_otfs = data8.per_otfs;
        per_ofdm = data8.per_ofdm;
        prbs = data8.prb_configs;
        
        p_idx = 1;
        for p = 1:length(prbs)
            dfile = fullfile(output_dir, sprintf('tmp_f8_otfs_p%d.dat', p));
            fd = fopen(dfile, 'w');
            for i = 1:length(SNR8)
                v = per_otfs(i, p);
                if v > 0, fprintf(fd, '%g %g\n', SNR8(i), v); end
            end
            fclose(fd);
            
            dfile2 = fullfile(output_dir, sprintf('tmp_f8_ofdm_p%d.dat', p));
            fd = fopen(dfile2, 'w');
            for i = 1:length(SNR8)
                v = per_ofdm(i, p);
                if v > 0, fprintf(fd, '%g %g\n', SNR8(i), v); end
            end
            fclose(fd);
            p_idx = p_idx + 1;
        end
        
        fprintf(fid, 'set title "TDL-C, QPSK R=1/2" font ",13"\n');
        fprintf(fid, 'set xlabel "SNR [dB]"\n');
        fprintf(fid, 'set ylabel "PER"\n');
        fprintf(fid, 'set logscale y\n');
        fprintf(fid, 'set yrange [1e-3:1]\n');
        fprintf(fid, 'set xrange [0:18]\n');
        fprintf(fid, 'set key top right\n');
        fprintf(fid, 'plot ');
        
        first = true;
        for p = 1:length(prbs)
            if ~first, fprintf(fid, ', \\\n     '); end
            dfile = strrep(fullfile(output_dir, sprintf('tmp_f8_otfs_p%d.dat', p)), '\', '/');
            fprintf(fid, '"%s" w l lc rgb "#0072BD" lw 1.5 title "OTFS %dPRB"', dfile, prbs(p));
            first = false;
            fprintf(fid, ', \\\n     ');
            dfile2 = strrep(fullfile(output_dir, sprintf('tmp_f8_ofdm_p%d.dat', p)), '\', '/');
            fprintf(fid, '"%s" w l lc rgb "#D95319" lw 1.5 title "OFDM %dPRB"', dfile2, prbs(p));
        end
        fprintf(fid, '\n\n');
    end
    
    % --- Figure 9 ---
    fprintf(fid, 'set terminal pngcairo size 1200,500\n');
    fprintf(fid, 'set output "%s"\n\n', strrep(fullfile(output_dir, 'fig9_snr_evolution_cdf.png'), '\', '/'));
    fig9_mat = fullfile(output_dir, 'fig9_data.mat');
    if exist(fig9_mat, 'file')
        data9 = load(fig9_mat);
        
        % 左图数据
        dfile_time = fullfile(output_dir, 'tmp_f9_time.dat');
        fd = fopen(dfile_time, 'w');
        for i = 1:length(data9.time_axis)
            fprintf(fd, '%g %g %g %g\n', data9.time_axis(i), ...
                10*log10(data9.snr_ofdm(i)), 10*log10(data9.snr_otfs_10ms(i)), 10*log10(data9.snr_otfs_1ms(i)));
        end
        fclose(fd);
        
        % 右图数据
        if isfield(data9, 'cdf_snr')
            dfile_cdf = fullfile(output_dir, 'tmp_f9_cdf.dat');
            fd = fopen(dfile_cdf, 'w');
            for i = 1:length(data9.cdf_snr)
                c1 = data9.cdf_ofdm(i);
                c2 = 0; c3 = 0;
                if isfield(data9, 'cdf_otfs_10ms'), c2 = data9.cdf_otfs_10ms(i); end
                if isfield(data9, 'cdf_otfs_1ms'), c3 = data9.cdf_otfs_1ms(i); end
                if c1 > 0, fprintf(fd, '%g %g %g %g\n', data9.cdf_snr(i), c1, c2, c3); end
            end
            fclose(fd);
        end
        
        fprintf(fid, 'set multiplot layout 1,2\n');
        fprintf(fid, 'set title "ETU, 120 km/h" font ",12"\n');
        fprintf(fid, 'set xlabel "time (s)"\n');
        fprintf(fid, 'set ylabel "SNR (dB)"\n');
        fprintf(fid, 'set xrange [0:0.7]\n');
        fprintf(fid, 'set yrange [5:35]\n');
        fprintf(fid, 'set grid\n');
        fprintf(fid, 'set key top left\n');
        
        dfile_time_gnuplot = strrep(dfile_time, '\', '/');
        fprintf(fid, 'plot "%s" u 1:2 w l lc rgb "#D95319" lw 0.8 title "OFDM", \\\n', dfile_time_gnuplot);
        fprintf(fid, '     "%s" u 1:3 w l lc rgb "#0072BD" lw 1.5 title "OTFS 10ms", \\\n', dfile_time_gnuplot);
        fprintf(fid, '     "%s" u 1:4 w p pt 7 ps 0.5 lc rgb "#000000" title "OTFS 1ms"\n\n', dfile_time_gnuplot);
        
        fprintf(fid, 'set xlabel "SNR (dB)"\n');
        fprintf(fid, 'set ylabel "CDF"\n');
        fprintf(fid, 'set xrange [0:35]\n');
        fprintf(fid, 'set yrange [1e-3:1]\n');
        fprintf(fid, 'set logscale y\n');
        fprintf(fid, 'set key bottom right\n');
        
        if isfield(data9, 'cdf_snr')
            dfile_cdf_gnuplot = strrep(dfile_cdf, '\', '/');
            fprintf(fid, 'plot "%s" u 1:2 w l lc rgb "#D95319" lw 2 title "OFDM", \\\n', dfile_cdf_gnuplot);
            fprintf(fid, '     "%s" u 1:3 w l lc rgb "#0072BD" lw 2 title "OTFS 10ms", \\\n', dfile_cdf_gnuplot);
            fprintf(fid, '     "%s" u 1:4 w l lc rgb "#000000" lw 2 title "OTFS 1ms"\n\n', dfile_cdf_gnuplot);
        end
        
        fprintf(fid, 'unset multiplot\n');
    end
else
    fprintf('⚠️ fig5_data.mat 不存在\n');
end

fclose(fid);
fprintf('gnuplot 脚本已生成: %s\n', gp_file);
fprintf('正在运行 gnuplot...\n\n');

% 运行 gnuplot
cmd = sprintf('"%s" "%s"', gnuplot_exe, gp_file);
[s, r] = system(cmd);

if s == 0
    fprintf('✅ gnuplot 运行成功\n\n');
else
    fprintf('⚠️ gnuplot 运行失败: %s\n\n', r);
end

% 列出 PNG 文件
fprintf('输出文件:\n');
files = dir(fullfile(output_dir, '*.png'));
if isempty(files)
    fprintf('  (无 .png 文件)\n');
else
    for i = 1:length(files)
        fprintf('  - %-45s %8.1f KB\n', files(i).name, files(i).bytes/1024);
    end
end
fprintf('\n');
