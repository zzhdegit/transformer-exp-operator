import numpy as np
import matplotlib.pyplot as plt

NUM_SAMPLES = 800
Q4_12_SCALE = 4096.0
UQ1_15_SCALE = 32768.0

# 1. 提取 RTL 实际处理的输入 (还原真实 Q4.12)
hw_inputs = []
with open("stimulus_800.txt", "r") as f:
    for line in f:
        val = int(line.strip(), 16)
        hw_inputs.append(val - 65536 if val >= 32768 else val)

# 2. 提取 RTL 并行计算并解包后的输出 (UQ1.15)
hw_outputs = []
with open("rtl_output_800.txt", "r") as f:
    for line in f:
        hw_outputs.append(int(line.strip(), 16))

if len(hw_outputs) != NUM_SAMPLES:
    print(f"⚠️ 警告: 输出数据量 ({len(hw_outputs)}) 与预期 ({NUM_SAMPLES}) 不符！")

# 3. 对比计算
x_float = np.array(hw_inputs) / Q4_12_SCALE
y_true = np.exp(x_float)
y_hw = np.array(hw_outputs) / UQ1_15_SCALE

errors = np.abs(y_true - y_hw)
max_err = np.max(errors)
mean_err = np.mean(errors)
std_err = np.std(errors)

print("\n" + "="*40)
print("🚀 16路并行 NPLA 加速器精度评估报告")
print("="*40)
print(f"📊 总吞吐量:   {NUM_SAMPLES} 个数据 (耗时仅 ~53 时钟周期)")
print(f"🎯 最大绝对误差: {max_err:.6f}")
print(f"🎯 平均绝对误差: {mean_err:.6f}")
print(f"🎯 误差标准差:   {std_err:.6f}")
print("="*40 + "\n")

# 4. 绘图 (双子图并排显示)
# 设置画布大小 15x6，1行2列
fig, axes = plt.subplots(1, 2, figsize=(15, 6))

# --- 子图 1: 误差分布直方图 (左侧) ---
axes[0].hist(errors, bins=60, color='teal', edgecolor='black', alpha=0.7)
axes[0].axvline(mean_err, color='red', linestyle='dashed', linewidth=2, label=f'Mean Error: {mean_err:.6f}')
axes[0].axvline(max_err, color='orange', linestyle='dashed', linewidth=2, label=f'Max Error: {max_err:.6f}')
axes[0].set_title('Error Distribution Histogram', fontsize=14, fontweight='bold')
axes[0].set_xlabel('Absolute Error', fontsize=12)
axes[0].set_ylabel('Frequency / Number of Samples', fontsize=12)
axes[0].legend(fontsize=11)
axes[0].grid(axis='y', alpha=0.3)

# --- 子图 2: 输入值 vs 误差散点图 (右侧) ---
# 使用散点图展示每个输入点 x 对应的绝对误差
axes[1].scatter(x_float, errors, color='royalblue', alpha=0.6, s=15, label='Sample Error')
axes[1].axhline(0, color='black', linewidth=1) # 画一条 y=0 的基准线
axes[1].set_title('Absolute Error vs. Input Value ($x$)', fontsize=14, fontweight='bold')
axes[1].set_xlabel('Input Value ($x \in [-8.0, 0]$)', fontsize=12)
axes[1].set_ylabel('Absolute Error', fontsize=12)
axes[1].legend(fontsize=11)
axes[1].grid(linestyle='--', alpha=0.5)

# 调整子图间距并显示
plt.tight_layout()
plt.show()