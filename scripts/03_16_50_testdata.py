import numpy as np

NUM_SAMPLES = 800  # 16路 * 50拍 = 800
Q4_12_SCALE = 4096.0

np.random.seed(2026) # 固定种子
test_inputs = np.random.uniform(-8.0, 0.0, NUM_SAMPLES)

with open("stimulus_800.txt", "w") as f:
    for val in test_inputs:
        q_val = int(np.round(val * Q4_12_SCALE))
        if q_val < 0:
            q_val = (1 << 16) + q_val
        f.write(f"{q_val & 0xFFFF:04X}\n")

print(f"成功生成 {NUM_SAMPLES} 个测试向量到 stimulus_800.txt")