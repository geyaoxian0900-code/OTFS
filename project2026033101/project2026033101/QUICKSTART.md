# OTFS 仿真系统 - 使用指南

## 🚀 一键运行

### 方法 1: 完整批量仿真（推荐）

在项目根目录运行：

```bash
octave-cli --no-gui --eval "run('run_all_figures.m')"
```

或在 Octave GUI 中：
```matlab
cd('C:\Users\dengkaile\OneDrive\Desktop\project2026033101')
run('run_all_figures.m')
```

**特点**：
- ✅ 自动运行 Figure 5-9
- ✅ 快速测试模式（几分钟完成）
- ✅ 所有结果保存到 `output/` 目录
- ✅ 详细进度和统计信息

### 方法 2: 单独运行某个图表

```bash
# Figure 5: BER vs SNR
octave-cli --no-gui --eval "run('scripts/run_fig5.m')"

# Figure 6: PER vs SNR
octave-cli --no-gui --eval "run('scripts/run_fig6.m')"

# Figure 7: 短包 BLER
octave-cli --no-gui --eval "run('scripts/run_fig7.m')"

# Figure 8: 不同 PRB 配置
octave-cli --no-gui --eval "run('scripts/run_fig8.m')"

# Figure 9: SNR 时间演化（已完成）
octave-cli --no-gui --eval "run('scripts/run_fig9.m')"
```

## 📊 输出文件

所有仿真结果保存在 `output/` 目录：

```
output/
├── fig5_data.mat                  # Figure 5 数据
├── fig6_data.mat                  # Figure 6 数据
├── fig7_data.mat                  # Figure 7 数据
├── fig8_data.mat                  # Figure 8 数据
├── fig9_data.mat                  # Figure 9 数据
├── fig9_snr_evolution_cdf.png     # Figure 9 图表 ✅
├── fig9_time_data.txt             # Figure 9 时间序列
└── fig9_cdf_data.txt              # Figure 9 CDF 数据
```

## ⚙️ 仿真模式

### 快速测试模式（默认）
- SNR 点：5 个
- 试验次数：200 次
- 运行时间：几分钟
- 适用：验证系统、调试

### 完整仿真模式
修改 `run_all_figures.m` 中的：
```matlab
quick_test_mode = false;  % 改为 false
```
- SNR 点：完整范围
- 试验次数：5000 次
- 运行时间：2-6 小时
- 适用：最终结果

## ✅ 当前状态

| 图表 | 状态 | 说明 |
|------|------|------|
| Figure 5 | ✅ 就绪 | BER vs SNR，需运行 |
| Figure 6 | ✅ 就绪 | PER vs SNR，需运行 |
| Figure 7 | ✅ 就绪 | 短包 BLER，需运行 |
| Figure 8 | ✅ 就绪 | PRB 配置，需运行 |
| Figure 9 | ✅ 完成 | SNR 演化，已生成 |

## 🔧 故障排除

### 问题：仿真时间过长
**解决**：使用快速测试模式（默认）

### 问题：路径错误
**解决**：确保在项目根目录运行：
```matlab
cd('C:\Users\dengkaile\OneDrive\Desktop\project2026033101')
```

### 问题：函数未定义
**解决**：检查 `core/` 目录是否完整，所有 `.m` 文件是否存在

## 📚 参考

- 论文：arXiv 1808.00519
- README.md：详细文档
- quick_verify.m：系统验证脚本

---
**最后更新**：2026-04-06
