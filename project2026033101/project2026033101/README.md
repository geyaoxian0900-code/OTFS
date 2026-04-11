# OTFS vs OFDM 性能对比仿真系统

> **论文复现**: Orthogonal Time Frequency Space Modulation (arXiv:1808.00519)  
> **版本**: 2.0 (重构版)  
> **更新日期**: 2026-04-06

---

## 📋 项目简介

本系统是论文 **"Orthogonal Time Frequency Space Modulation"** 的 MATLAB/Octave 完整复现实现。

系统实现了 **OTFS**（正交时频空间）与 **OFDM**（正交频分复用）两种调制技术的全面性能对比，用于验证 OTFS 在高移动性场景下的性能优势。

### 核心特性

- ✅ **精确复现**论文 Table I 标准参数（fc=4GHz, 15kHz, TDL-C 信道）
- ✅ **模块化架构**：配置管理、核心算法、仿真脚本分离
- ✅ **3GPP 标准信道**：TDL-C（12 抽头）和 ETU 模型
- ✅ **多种接收机**：MMSE、DFE、Genie-DFE、迭代检测器
- ✅ **完整性能指标**：BER、PER、BLER、SNR 时间演化

---

## 🗂️ 目录结构

```
project2026033101/
│
├── 📂 config/                          ← 系统配置
│   └── system_config.m                 # 论文参数集中管理
│
├── 📂 core/                            ← 核心算法库
│   ├── 📂 modulation/                  # 调制解调器
│   │   ├── otfs_modulate.m             # OTFS 调制（ISFFT）
│   │   ├── otfs_demodulate.m           # OTFS 解调（SFFT）
│   │   ├── ofdm_modulate.m             # OFDM 调制
│   │   └── ofdm_demodulate.m           # OFDM 解调
│   │
│   ├── 📂 channel/                     # 信道模型
│   │   ├── tdlc_channel.m              # TDL-C（3GPP 12抽头）
│   │   ├── etu_channel.m               # ETU 信道
│   │   └── apply_channel.m             # 信道应用
│   │
│   ├── 📂 equalizer/                   # 均衡器/检测器
│   │   ├── mmse_equalizer.m            # MMSE 均衡器
│   │   ├── dfe_equalizer.m             # DFE 均衡器
│   │   ├── genie_equalizer.m           # Genie-DFE（理论上界）
│   │   └── iterative_detector.m        # 迭代检测器
│   │
│   └── 📂 utils/                       # 工具函数
│       ├── qam_mod.m                   # QAM 调制
│       ├── qam_demod.m                 # QAM 解调
│       ├── jakes_fading.m              # Jakes 衰落
│       └── metrics.m                   # BER/PER/BLER 计算
│
├── 📂 scripts/                         ← 仿真脚本
│   ├── run_fig5.m                      # Figure 5: 未编码 BER vs SNR
│   ├── run_fig6.m                      # Figure 6: 编码 PER vs SNR
│   ├── run_fig7.m                      # Figure 7: 短包 BLER vs SNR
│   ├── run_fig8.m                      # Figure 8: 不同 PRB 配置
│   └── run_fig9.m                      # Figure 9: SNR 时间演化
│
├── 📂 results/                         ← 仿真结果（自动生成）
│
├── 📂 fig/                             ← 原始截图参考
├── 📂 table/                           ← 原始表格参考
│
├── main.m                              # 主运行脚本
├── README.md                           # 本文件
│
└── [原始文件保留供参考]
    ├── sim_core.m                      # 原始核心库
    ├── fig5_uncoded_ber_vs_snr.m       # 原始脚本
    ├── fig6_per_vs_snr.m
    ├── fig7_bler_short_packet.m
    ├── fig8_per_different_prb.m
    └── fig9_snr_evolution_cdf.m
```

---

## ⚙️ 系统参数

### 论文 Table I 标准配置

| 参数 | 值 | 说明 |
|------|------|------|
| **载波频率** | 4.0 GHz | FDD 频段 |
| **双工模式** | FDD | 频分双工 |
| **子载波间隔** | 15 kHz | LTE 标准 |
| **FFT 大小** | 1024 点 | 对应 1024 子载波 |
| **循环前缀** | 4.7 μs | 标准 CP 长度 |
| **系统带宽** | 50 PRB (600 子载波) | 约 10 MHz |
| **天线配置** | 1×1 SISO | 单输入单输出 |
| **信道模型** | TDL-C, DS=300ns | 3GPP TR 38.901 |
| **信道估计** | Ideal | 理想信道估计 |

### 仿真场景配置

| 图表 | 信道 | 速度 | 调制 | 编码 | SNR 范围 |
|------|------|------|------|------|----------|
| **Fig 5** | TDL-C | 120 km/h | QPSK/16QAM/64QAM/256QAM | 无 | 0-40 dB |
| **Fig 6** (子图1) | TDL-C | 120 km/h | QPSK | R=1/2 | 0-9 dB |
| **Fig 6** (子图2) | TDL-C | 120 km/h | 64QAM | R=2/3 | 0-30 dB |
| **Fig 7** | TDL-C | 30 km/h | 16QAM/64QAM | R=1/2 | 8-24 dB |
| **Fig 8** | TDL-C | 120 km/h | QPSK | R=1/2 | 0-18 dB |
| **Fig 9** | ETU | 120 km/h | - | - | 统计 SNR |

### TDL-C 信道参数（3GPP TR 38.901）

| 抽头 | 延迟 (ns) | 功率 (dB) |
|------|-----------|-----------|
| 1 | 0 | -1 |
| 2 | 30 | -1 |
| 3 | 70 | -1 |
| 4 | 90 | 0 |
| 5 | 110 | 0 |
| 6 | 190 | 0 |
| 7 | 410 | -3 |
| 8 | 490 | -5 |
| 9 | 570 | -7 |
| 10 | 700 | -9 |
| 11 | 1000 | -11 |
| 12 | 2600 | -14 |

**多普勒频移计算**（120 km/h @ 4 GHz）：
```
fd = fc × v / c = 4e9 × (120/3.6) / 3e8 ≈ 444 Hz
```

---

## 🚀 快速开始

### 环境要求

| 软件 | 最低版本 | 推荐版本 |
|------|---------|---------|
| **MATLAB** | R2018b | R2023b 或更新 |
| **GNU Octave** | 6.0 | 11.x |

**必需工具箱**（MATLAB）：
- Signal Processing Toolbox
- Communications Toolbox（可选，用于对比）

**Octave 包**：
```octave
pkg install signal
pkg load signal
```

### 运行仿真

#### 方法 1：运行单个图表

```bash
# Octave 命令行
octave-cli --no-gui --eval "run('scripts/run_fig9.m')"

# MATLAB 命令行
matlab -batch "run('scripts/run_fig5.m')"
```

#### 方法 2：使用主脚本

```matlab
% 在 MATLAB/Octave 中
cd C:\Users\dengkaile\OneDrive\Desktop\project2026033101
run('main.m')
```

#### 方法 3：快速测试（推荐首次使用）

修改脚本中的 `max_trials` 为较小值（如 100）进行快速验证：

```matlab
% 在 run_fig5.m 中修改
max_trials = 100;  % 从 5000 改为 100
min_errors = 10;   % 从 100 改为 10

% 然后运行
run('scripts/run_fig5.m')
```

### 输出结果

所有仿真结果自动保存到 `results/` 目录：

```
results/
├── fig5_data.mat                         # Figure 5 数据
├── fig5_uncoded_ber_comparison.png       # Figure 5 图表
├── fig6_data.mat
├── fig6_per_vs_snr.png
├── fig7_data.mat
├── fig7_bler_short_packet.png
├── fig8_data.mat
├── fig8_per_different_prb.png
├── fig9_data.mat
├── fig9_snr_evolution_cdf.png            # Figure 9 双图
├── fig9_time_data.txt                    # SNR 时间序列
└── fig9_cdf_data.txt                     # CDF 数据
```

---

## 📊 仿真图表详解

### Figure 5: 未编码 BER vs SNR

**目标**: 展示无信道编码下，OTFS 与 OFDM 的误码率性能对比

**关键观察**:
- 低阶调制（QPSK/16QAM）下，OTFS 显著优于 OFDM
- OFDM 存在误码平层（error floor）——ICI 导致
- 高阶调制（64QAM/256QAM）下，OTFS-MMSE 性能下降，需 DFE 改善
- Genie-DFE 与标准 DFE 差距 ≤ 1 dB（低阶调制）

**预期曲线特征**:
```
BER
1 |
  |    ╭─ OFDM (所有调制)
  |   ╱
  |  ╱
  | ╱  ╭─ OTFS-MMSE (高阶调制)
  |╱  ╱
  |  ╱  ╭─ OTFS-MMSE (低阶调制)
  | ╱  ╱
  |╱  ╱
  |  ╱
  | ╱   ╭─ OTFS-DFE
  |╱   ╱
  |   ╱    ╭─ OTFS-DFE(Genie)
  |  ╱    ╱
1e-7──────╱───────────── SNR [dB]
  0      40
```

### Figure 6: 编码 PER vs SNR

**目标**: 展示有信道编码下，不同接收机的误包率性能

**关键观察**:
- MMSE 不适用于 OTFS（尤其高阶调制）
- 标准 DFE 存在误差传播
- **迭代检测器**逼近 Genie-DFE 性能
- OTFS-Iterative 显著优于 OFDM-MMSE（2-4 dB 增益 @ 10% PER）

**两个子图**:
1. **QPSK R=1/2**: SNR 0-9 dB，展示低阶调制性能
2. **64QAM R=2/3**: SNR 0-30 dB，展示高阶调制性能

### Figure 7: 短包 BLER

**目标**: 窄带短包传输场景下，OTFS 的分集增益

**场景配置**:
- 仅 4 个 PRB（48 个子载波）
- 30 km/h 低速移动
- 16QAM/64QAM，码率 1/2

**关键观察**:
- OTFS 将符号扩展至全时频网格，提取全分集
- OTFS 获得 **≥4 dB** 的 BLER 增益（@ 10% BLER）
- OFDM 窄带传输无法利用频率分集

### Figure 8: 不同 PRB 配置

**目标**: 展示 OTFS 性能不受资源分配比例影响

**关键观察**:
- **OFDM**: 性能随 PRB 减少而显著恶化（可用频率分集降低）
- **OTFS**: 性能稳定，不受资源分配影响（始终扩展至全带宽）
- 低 PRB 时两者差距缩小（OFDM 分集进一步降低）

**预期曲线**:
```
PER
1 |
  |  OFDM (2 PRB)  ← 最差
  |  OFDM (4 PRB)
  |  OFDM (8 PRB)
  |  OFDM (16 PRB)
  |  OFDM (50 PRB)
  |
  |  ─────────── OTFS (所有 PRB 配置，几乎重叠) ← 最优
1e-3───────────────────────────────────────── SNR [dB]
  0           18
```

### Figure 9: SNR 时间演化与 CDF

**目标**: 展示 OTFS 的信道硬化效应

**关键观察**:
- **OFDM**: SNR 波动大，标准差 > 4 dB
- **OTFS 1ms**: SNR 标准差 1.1 dB
- **OTFS 10ms**: SNR 标准差 0.2 dB（近乎恒定）
- @ 0.01 中断概率，OTFS 可减少 7-9 dB 衰落余量

**双图展示**:
1. **左图**: SNR 随时间演化曲线
2. **右图**: SNR 累积分布函数（CDF）

---

## 🔧 算法实现

### OTFS 调制解调

#### 调制流程

```
DD 域符号 X[k,l]
    ↓
ISFFT (逆辛傅里叶变换)
    ↓
TF 域 X[n,m] = (1/√(NM)) × Σ_k Σ_l X[k,l] × e^(j2π(nk/M - lm/N))
    ↓
Heisenberg 变换 (每列 IFFT)
    ↓
时域信号 s(t)
    ↓
添加循环前缀 (CP)
    ↓
发射
```

**MATLAB 实现**:
```matlab
% ISFFT: DD → TF
tf_data = fft(ifft(dd_data, [], 2), [], 1) / sqrt(N * M);

% Heisenberg: TF → 时域
time_grid = ifft(tf_data, [], 1);

% 添加 CP
tx_sig = [time_grid(end-cp_len+1:end, :); time_grid];
```

#### 解调流程

```
接收信号 r(t)
    ↓
移除循环前缀
    ↓
Wigner 变换 (每列 FFT)
    ↓
TF 域 Y[n,m]
    ↓
SFFT (辛傅里叶变换)
    ↓
DD 域估计 Ŷ[k,l] = (1/√(NM)) × ifft(fft(Y_tf, [], 1), [], 2)
    ↓
符号检测
```

**MATLAB 实现**:
```matlab
% Wigner: 时域 → TF
rx_tf = fft(rx_no_cp, [], 1);

% SFFT: TF → DD
dd_est = ifft(fft(rx_tf, [], 1), [], 2) * sqrt(N * M);
```

### 均衡器算法

#### 1. MMSE 均衡器

**原理**: 最小化均方误差
```
W_MMSE = H* / (|H|² + σ²/P_signal)
X̂ = Y ⊙ W_MMSE
```

**适用场景**: 低阶调制、低 SNR  
**局限**: 忽略 DD 域信道扩散，高阶调制性能下降

#### 2. DFE (判决反馈均衡器)

**原理**: 利用先前判决消除干扰
```
y_ff = Y ⊙ W_MMSE                          # 前馈均衡
y_dec = y_ff - Σ h_leak × x_prev          # 反馈干扰消除
X̂ = Q(y_dec)                               # 硬判决
```

**适用场景**: 中阶调制  
**局限**: 误差传播效应（错误判决影响后续符号）

#### 3. Genie-DFE (理想反馈)

**原理**: 使用真实发送符号作为反馈源
```
y_dec = y_ff - Σ h_leak × x_true          # 完美干扰消除
X̂ = Q(y_dec)
```

**意义**: 理论上界，无误差传播  
**用途**: 评估标准 DFE 的误差传播影响

#### 4. 迭代检测器

**原理**: 迭代干扰消除逼近 Genie-DFE
```
迭代 1: X̂_0 = MMSE(Y, H)
迭代 2~N:
  1. 重构干扰: I = H ⊛ X̂_prev - diag(H)⊙X̂_prev
  2. 干扰消除: Y_clean = Y - I
  3. 重新均衡: X̂_new = MMSE(Y_clean, H)
  4. 收敛检查: ||X̂_new - X̂_prev|| < ε
```

**适用场景**: 高阶调制、编码系统  
**优势**: 显著优于 MMSE，逼近 Genie-DFE

### 信道模型

#### TDL-C (Tapped Delay Line - C)

**来源**: 3GPP TR 38.901  
**特点**: 12 抽头，时延扩展 DS=300ns

**实现**:
```matlab
% 抽头延迟映射到 DD 网格
delay_samples = round(delays_ns * 1e-9 / ts);
n_idx = mod(delay_samples, N) + 1;

% 生成时间相关衰落（Jakes 模型）
fading_sequence = generate_jakes_sequence(M, fd, fs, power_tap);

% 放置到 DD 域信道矩阵
h_dd(n_idx, :) = fading_sequence;
```

#### Jakes 衰落

**原理**: 滤波高斯法生成具有 Jakes 功率谱的时间相关衰落

**Jakes PSD**:
```
S(f) = 1/(π×fd) × 1/√(1-(f/fd)²),  |f| < fd
```

**实现**:
```matlab
% 构造 Jakes PSD
jakes_psd(inside_band) = 1 ./ sqrt(1 - (f/fd).^2);

% 复高斯噪声滤波
noise_freq = fft(randn(N, 1) + 1j*randn(N, 1));
fading_time = ifft(noise_freq .* sqrt(jakes_psd));
```

---

## 🔍 验证与测试

### 单元测试

建议首次运行时执行以下测试：

```matlab
%% 测试 1: QAM 调制解调
fprintf('测试 1: QAM 调制解调... ');
bits = randi([0,1], 1, 1000);
syms = qam_mod(bits, 4);
[rx_bits, ~, ~] = qam_demod(syms, 4, 0.01, 'hard');
assert(all(bits' == rx_bits), 'QAM 测试失败');
fprintf('通过 ✓\n');

%% 测试 2: OTFS 调制解调（无信道）
fprintf('测试 2: OTFS 调制解调... ');
N = 16; M = 16; cp = 4;
X = randn(N, M) + 1j*randn(N, M);
tx = otfs_modulate(X, N, M, cp);
Y = otfs_demodulate(tx, N, M, cp);
err = norm(X(:) - Y(:)) / norm(X(:));
assert(err < 0.01, sprintf('OTFS 误差过大: %.4f', err));
fprintf('通过 ✓ (误差: %.2e)\n', err);

%% 测试 3: 信道模型
fprintf('测试 3: TDL-C 信道... ');
h = tdlc_channel(16, 16, 100, 1e6);
assert(all(size(h) == [16, 16]), '信道尺寸错误');
assert(any(h(:) ~= 0), '信道全为零');
fprintf('通过 ✓\n');

%% 测试 4: MMSE 均衡器
fprintf('测试 4: MMSE 均衡器... ');
y = randn(16, 16) + 1j*randn(16, 16);
h = randn(16, 16) + 1j*randn(16, 16);
x_hat = mmse_equalizer(y, h, 0.01);
assert(isequal(size(x_hat), size(y)), '均衡器输出尺寸错误');
fprintf('通过 ✓\n');

fprintf('\n所有测试通过！\n');
```

### 快速集成测试

```matlab
% 修改 run_fig5.m 中的参数
max_trials = 100;      % 减少试验次数
min_errors = 10;       % 降低阈值
SNR_dB = 0:5:20;       % 减少 SNR 点

% 运行
run('scripts/run_fig5.m')

% 预期: 应快速完成（< 1 分钟），生成 BER 曲线趋势
```

---

## ⚠️ 注意事项

### 仿真时间估计

| 图表 | 完整仿真 | 快速测试 |
|------|---------|---------|
| **Figure 9** | < 1 分钟 | < 1 分钟 |
| **Figure 5** | 2-4 小时 | 1-2 分钟 |
| **Figure 6** | 3-6 小时 | 1-2 分钟 |
| **Figure 7** | 1-3 小时 | < 1 分钟 |
| **Figure 8** | 4-8 小时 | 2-3 分钟 |

### 内存需求

- **最小**: 4 GB RAM
- **推荐**: 8 GB RAM
- **Figure 5/6 完整仿真**: 可能需要 16 GB

### 已知限制

1. **FEC 编码简化**: Figure 6/7/8 中的 `code_rate` 仅用于计算包大小，无实际编解码
2. **信道估计理想化**: 假设完美信道知识，无估计误差
3. **蒙特卡洛随机性**: 每次运行结果略有不同
4. **高阶调制性能**: 256QAM 在高 SNR 下可能需要更多试验次数

### 调试技巧

```matlab
% 1. 设置随机种子（可重复结果）
rng(42);

% 2. 显示中间结果
fprintf('SNR=%.1f dB, Trial=%d, BER=%.2e\n', snr, trial, ber);

% 3. 保存中间数据
save('debug_checkpoint.mat', 'tx_vec', 'rx_vec', 'h_dd', 'X_hat');

% 4. 可视化信道
imagesc(abs(h_dd)); colorbar; title('DD 域信道响应');
```

---

## 🆚 与原始代码对比

### 修复的问题

| 问题 | 原始代码 | 新系统 |
|------|---------|--------|
| **物理层参数** | 硬编码，多处不一致 | 集中管理，严格对齐论文 |
| **TDL-C 抽头** | 6/9 抽头（错误） | 12 抽头（3GPP 标准） |
| **载波频率** | 未定义或 2 GHz | 4 GHz |
| **OTFS ISFFT** | `ifft(eye(M))` 错误 | `fft(ifft(X, [], 2), [], 1)` |
| **MMSE 均衡** | 忽略信道扩散 | 考虑信道能量分布 |
| **DFE 反馈** | 魔数 0.05 | 基于信道结构动态计算 |
| **迭代检测** | 干扰自相抵消 | 正确干扰消除逻辑 |
| **代码重复** | 同名函数多版本 | 模块化，单一实现 |
| **多普勒计算** | 硬编码 fd | `fd = fc*v/c` 动态计算 |

### 保留的原始文件

为便于对比研究，保留了所有原始文件：

- `sim_core.m` - 原始核心库
- `fig5_uncoded_ber_vs_snr.m` - 原始 Figure 5
- `fig6_per_vs_snr.m` - 原始 Figure 6
- `fig7_bler_short_packet.m` - 原始 Figure 7
- `fig8_per_different_prb.m` - 原始 Figure 8
- `fig9_snr_evolution_cdf.m` - 原始 Figure 9

**建议**: 使用新系统进行研究，原始文件仅供对比参考。

---

## 📚 学术参考

### 论文

- **主论文**: R. Hadani et al., "Orthogonal Time Frequency Space Modulation", arXiv:1808.00519
- **3GPP 标准**: 3GPP TR 38.901, "Channel model for frequency spectrum up to 100 GHz"
- **OTFS 综述**: P. Raviteja et al., "Orthogonal Time Frequency Space Modulation: A Promising Next-Generation Waveform", IEEE Vehicular Technology Magazine, 2021

### 相关资源

- **GNU Octave**: https://www.gnu.org/software/octave/
- **3GPP 规范**: https://www.3gpp.org/
- **arXiv 论文**: https://arxiv.org/abs/1808.00519

### 引用格式

如果您在研究中使用了本系统，请引用：

```bibtex
@article{hadani2018orthogonal,
  title={Orthogonal Time Frequency Space Modulation},
  author={Hadani, Ronny and Rakib, Shlomi and Tsatsanis, Michail and Monk, Arie and Calderbank, A Robert and Ionescu, Constantin R and Goldsmith, Andrea and Poor, H Vincent},
  journal={arXiv preprint arXiv:1808.00519},
  year={2018}
}
```

---

## 📄 许可证

本实现仅供**学术研究和教育**使用。

- ✅ 允许：学习、研究、教学
- ⚠️ 限制：商业使用、专利申请
- 📝 要求：引用原论文

---

## 🤝 贡献与反馈

如有问题或建议，请：

1. 检查本 README 的「注意事项」和「调试技巧」部分
2. 运行单元测试验证环境
3. 使用快速测试模式排查问题

---

**祝研究顺利！** 🚀
