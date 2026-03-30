import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import root_scalar, minimize_scalar
from scipy.special import erf
import warnings

warnings.filterwarnings('ignore')  # 忽略底层优化时的一些无关警告


# ==========================================
# 1. 定义三种目标算子函数
# ==========================================
def ex(x):
    return np.exp(x)


def gelu(x):
    return 0.5 * x * (1.0 + erf(x / np.sqrt(2.0)))


def silu(x):
    return x / (1.0 + np.exp(-x))


# ==========================================
# 2. 通用 NPLA 训练核心函数 (支持任意非线性)
# ==========================================
def optimal_pwl(func, N, x_min, x_max):
    # 计算单段误差及平移量 (数值优化寻找峰值，兼容拐点)
    def get_segment_error(x1, x2):
        if x2 - x1 < 1e-12: return 0.0, 0.0, 0.0
        a = (func(x2) - func(x1)) / (x2 - x1)

        def err_func(x):
            return func(x) - (a * (x - x1) + func(x1))

        res_min = minimize_scalar(err_func, bounds=(x1, x2), method='bounded')
        res_max = minimize_scalar(lambda x: -err_func(x), bounds=(x1, x2), method='bounded')

        E_min = res_min.fun if res_min.success else 0.0
        E_max = -res_max.fun if res_max.success else 0.0

        max_abs_err = (E_max - E_min) / 2.0
        shift_amount = (E_max + E_min) / 2.0
        return max_abs_err, a, shift_amount

    def max_err(x1, x2):
        err, _, _ = get_segment_error(x1, x2)
        return err

    # 寻界求解器，带二分查找兜底
    def next_knot(x1, target_err):
        if max_err(x1, x_max) <= target_err: return x_max

        def obj(x2):
            return max_err(x1, x2) - target_err

        try:
            res = root_scalar(obj, bracket=[x1 + 1e-9, x_max], method='brentq', xtol=1e-7)
            return res.root
        except ValueError:
            low, high = x1, x_max
            for _ in range(40):
                mid = (low + high) / 2
                if obj(mid) > 0:
                    high = mid
                else:
                    low = mid
            return low

    low_err, high_err = 1e-9, 1.0
    best_knots, best_err = [], 1.0

    for _ in range(40):
        mid_err = (low_err + high_err) / 2
        curr = x_min
        knots = [curr]
        for _ in range(N):
            curr = next_knot(curr, mid_err)
            knots.append(curr)
            if curr >= x_max: break

        if knots[-1] >= x_max:
            high_err = mid_err
            best_err = mid_err
            best_knots = knots
        else:
            low_err = mid_err

    # 组装最终硬件系数表
    table = []
    for i in range(N):
        x1 = best_knots[i]
        x2 = best_knots[i + 1] if i < len(best_knots) - 1 else x_max
        if x2 - x1 < 1e-12: continue
        _, a, shift = get_segment_error(x1, x2)
        b = func(x1) - a * x1 + shift
        table.append((x1, x2, a, b))

    return best_err, table


# ==========================================
# 3. 运行 9 组训练、打印参数并保存绘图数据
# ==========================================
configs = [
    ("e^x", ex, -8.0, 0.0),
    ("GELU", gelu, -6.0, 6.0),
    ("SiLU", silu, -6.0, 6.0)
]
segment_sizes = [16, 24, 32]

results_data = {}

print(f"硬件物理分辨率底噪 (1:4:11): ~0.000488\n")

for name, func, x_min, x_max in configs:
    results_data[name] = {}
    print("=" * 85)
    print(f"开始训练算子: {name} | 训练区间: [{x_min}, {x_max}]")
    print("=" * 85)

    for n in segment_sizes:
        # 执行训练
        err, res_table = optimal_pwl(func, n, x_min, x_max)
        results_data[name][n] = (err, res_table, func)

        # 格式化打印每一组的表格
        print(f"\n[{name}] [N={n:2d}] 理论最大误差: {err:.8f}")
        print("-" * 85)
        print(f"| {'区间 [Start, End)':<24} | {'斜率 a':<15} | {'截距 b':<15} | {'段长':<10} |")
        print("-" * 85)
        for t in res_table:
            print(f"| [{t[0]:7.4f}, {t[1]:7.4f}) | {t[2]:15.8f} | {t[3]:15.8f} | {t[1] - t[0]:10.4f} |")
        print("-" * 85)
    print("\n")

# ==========================================
# 4. 绘制 3x3 (9张) 误差对比矩阵图
# ==========================================
fig, axs = plt.subplots(3, 3, figsize=(18, 15))

for i, (name, func, x_min, x_max) in enumerate(configs):
    for j, n in enumerate(segment_sizes):
        ax = axs[i, j]
        err, res_table, _ = results_data[name][n]

        global_max_err = -1
        max_err_x = 0
        max_err_y = 0

        # 逐个分段绘制误差曲线
        for t in res_table:
            x1, x2, a, b = t
            if x2 - x1 < 1e-12: continue

            x_vals = np.linspace(x1, x2, 500)
            # 误差 = 函数真实值 - 线性乘加拟合值
            err_vals = func(x_vals) - (a * x_vals + b)

            ax.plot(x_vals, err_vals, color='#800080', linewidth=1.5)
            ax.fill_between(x_vals, err_vals, 0, color='#800080', alpha=0.1)

            # 记录全局最大误差点
            idx = np.argmax(np.abs(err_vals))
            if np.abs(err_vals[idx]) > global_max_err:
                global_max_err = np.abs(err_vals[idx])
                max_err_x = x_vals[idx]
                max_err_y = err_vals[idx]

        # 放大 Y 轴留出文本空间，防止遮挡
        ax.set_ylim(-global_max_err * 1.8, global_max_err * 1.8)

        # 标出全局最大误差点
        ax.scatter([max_err_x], [max_err_y], color='red', s=40, zorder=5)

        # 动态调节文本框位置
        y_offset = 20 if max_err_y > 0 else -20
        va = 'bottom' if max_err_y > 0 else 'top'

        ax.annotate(f'Max Error:\n{global_max_err:.2e}',
                    xy=(max_err_x, max_err_y),
                    xytext=(0, y_offset), textcoords='offset points',
                    color='red', fontsize=10, fontweight='bold', ha='center', va=va,
                    bbox=dict(boxstyle='round,pad=0.3', fc='white', ec='red', alpha=0.9))

        # 子图排版优化
        ax.set_title(f'{name} Error (N={n})', fontsize=13, fontweight='bold')
        if j == 0:
            ax.set_ylabel('Absolute Error', fontsize=11)
        if i == 2:
            ax.set_xlabel('Input Value (x)', fontsize=11)

        ax.grid(True, linestyle='--', alpha=0.5)
        ax.axhline(0, color='black', linewidth=0.8)

plt.tight_layout()
plt.savefig('npla_9_error_plots.png', dpi=300, bbox_inches='tight')
plt.show()
print("Successfully generated 'npla_9_error_plots.png'")