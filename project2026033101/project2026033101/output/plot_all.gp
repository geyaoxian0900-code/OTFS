# OTFS Figure Generation
set terminal pngcairo size 900,650 enhanced font "Arial,11"
set output "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/fig5_uncoded_ber_comparison.png"

# Figure 5
set title "TDL-C, 444Hz, QPSK" font ",14"
set xlabel "SNR [dB]"
set ylabel "Uncoded BER"
set logscale y
set yrange [1e-7:1]
set xrange [0:40]
set grid
set key bottom left
plot "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m1_e1.dat" w lp lc rgb "#0072BD" pt 7 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m1_e2.dat" w lp lc rgb "#D95319" pt 5 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m1_e3.dat" w lp lc rgb "#77AC30" pt 9 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m1_e4.dat" w lp lc rgb "#7F7F7F" pt 13 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m2_e1.dat" w lp lc rgb "#0072BD" pt 7 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m2_e2.dat" w lp lc rgb "#D95319" pt 5 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m2_e3.dat" w lp lc rgb "#77AC30" pt 9 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m2_e4.dat" w lp lc rgb "#7F7F7F" pt 13 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m3_e1.dat" w lp lc rgb "#0072BD" pt 7 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m3_e2.dat" w lp lc rgb "#D95319" pt 5 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m3_e3.dat" w lp lc rgb "#77AC30" pt 9 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m3_e4.dat" w lp lc rgb "#7F7F7F" pt 13 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m4_e1.dat" w lp lc rgb "#0072BD" pt 7 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m4_e2.dat" w lp lc rgb "#D95319" pt 5 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m4_e3.dat" w lp lc rgb "#77AC30" pt 9 ps 1.5 lw 1.6 notitle, \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f5_m4_e4.dat" w lp lc rgb "#7F7F7F" pt 13 ps 1.5 lw 1.6 notitle

set output "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/fig6_per_vs_snr.png"

set title "TDL-C, QPSK R=1/2" font ",12"
set xlabel "SNR [dB]"
set ylabel "PER"
set logscale y
set yrange [1e-4:1]
set xrange [0:9]
set key top right
plot "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f6_e1.dat" w l lc rgb "#0072BD" lt 1 lw 1.8 title "OTFS-Iter", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f6_e2.dat" w l lc rgb "#D95319" lt 2 lw 1.8 title "OTFS-DFE(G)", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f6_e3.dat" w l lc rgb "#77AC30" lt 3 lw 1.8 title "OTFS-DFE", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f6_e4.dat" w l lc rgb "#00BFFF" lt 4 lw 1.8 title "OTFS-MMSE", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f6_e5.dat" w l lc rgb "#000000" lt 5 lw 1.8 title "OFDM-MMSE"

set output "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/fig7_bler_short_packet.png"

set title "TDL-C, 30kmph, 4RB" font ",14"
set xlabel "SNR [dB]"
set ylabel "BLER"
set logscale y
set yrange [1e-3:1]
set xrange [8:24]
set key top right
plot "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f7_c1.dat" w l lc rgb "#0072BD" lw 2.2 title "OTFS 16QAM", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f7_c2.dat" w l lc rgb "#0072BD" lw 2.2 title "OFDM 16QAM", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f7_c3.dat" w l lc rgb "#D95319" lw 2.2 title "OTFS 64QAM", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f7_c4.dat" w l lc rgb "#D95319" lw 2.2 title "OFDM 64QAM"

set output "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/fig8_per_different_prb.png"

set title "TDL-C, QPSK R=1/2" font ",13"
set xlabel "SNR [dB]"
set ylabel "PER"
set logscale y
set yrange [1e-3:1]
set xrange [0:18]
set key top right
plot "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_otfs_p1.dat" w l lc rgb "#0072BD" lw 1.5 title "OTFS 50PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_ofdm_p1.dat" w l lc rgb "#D95319" lw 1.5 title "OFDM 50PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_otfs_p2.dat" w l lc rgb "#0072BD" lw 1.5 title "OTFS 16PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_ofdm_p2.dat" w l lc rgb "#D95319" lw 1.5 title "OFDM 16PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_otfs_p3.dat" w l lc rgb "#0072BD" lw 1.5 title "OTFS 8PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_ofdm_p3.dat" w l lc rgb "#D95319" lw 1.5 title "OFDM 8PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_otfs_p4.dat" w l lc rgb "#0072BD" lw 1.5 title "OTFS 4PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_ofdm_p4.dat" w l lc rgb "#D95319" lw 1.5 title "OFDM 4PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_otfs_p5.dat" w l lc rgb "#0072BD" lw 1.5 title "OTFS 2PRB", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f8_ofdm_p5.dat" w l lc rgb "#D95319" lw 1.5 title "OFDM 2PRB"

set terminal pngcairo size 1200,500
set output "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/fig9_snr_evolution_cdf.png"

set multiplot layout 1,2
set title "ETU, 120 km/h" font ",12"
set xlabel "time (s)"
set ylabel "SNR (dB)"
set xrange [0:0.7]
set yrange [5:35]
set grid
set key top left
plot "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f9_time.dat" u 1:2 w l lc rgb "#D95319" lw 0.8 title "OFDM", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f9_time.dat" u 1:3 w l lc rgb "#0072BD" lw 1.5 title "OTFS 10ms", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f9_time.dat" u 1:4 w p pt 7 ps 0.5 lc rgb "#000000" title "OTFS 1ms"

set xlabel "SNR (dB)"
set ylabel "CDF"
set xrange [0:35]
set yrange [1e-3:1]
set logscale y
set key bottom right
plot "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f9_cdf.dat" u 1:2 w l lc rgb "#D95319" lw 2 title "OFDM", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f9_cdf.dat" u 1:3 w l lc rgb "#0072BD" lw 2 title "OTFS 10ms", \
     "D:/MATLAB/MATLABfiles/OTFS/project2026033101/project2026033101/output/tmp_f9_cdf.dat" u 1:4 w l lc rgb "#000000" lw 2 title "OTFS 1ms"

unset multiplot
