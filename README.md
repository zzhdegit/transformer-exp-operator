# 16-Lane Pipelined Exponential Operator

## 项目简介
本项目实现了一个基于 **非均匀分段线性逼近 (NPLA)** 算法的指数函数 (e^x) 硬件加速算子。该设计专为 Transformer 模型中的 Softmax 模块优化，支持 16 路数据并行处理，并采用了深达 7 级的全弹性流水线架构，以在不同 FPGA 平台上压榨出极限主频。

## 核心特性
* **7级全弹性流水线**：采用分布式 FSM 控制逻辑，支持 Valid-Ready 握手协议与反压（Backpressure）机制。

## 性能评估

| 评估维度 | xc7z020clg400-2 (Zynq) | xcvu13p-flga2577-1-i (VU+) | 详细说明 |
| :--- | :--- | :--- | :--- |
| **最高频率 (F_max)** | **380 MHz** | **800 MHz** | |
| **单拍吞吐量** | 16 Data / Cycle | 16 Data / Cycle | 16 路并行 Data Path，支持背靠背满载运行。 |
| **流水线延迟** | 7 Cycles | 7 Cycles | 通过增加 3 拍延迟大幅打散组合逻辑，提升主频上限。 |
| **计算精度** | 3.71 *10^-4  | 3.71 *10^-4 |  800 组样本 |

## 数据格式定义
模块采用定点数进行运算，建议上游在输入前完成量化：
* **输入 (Input)**：`16-bit signed (Q4.12)`，范围 [-8.0, 0]。
* **输出 (Output)**：`16-bit unsigned (UQ1.15)`，范围 [0, 1.0]，带自动饱和截断。

## 模块接口 (I/O)
| 信号名称 | 方向 | 位宽 | 功能说明 |
| :--- | :--- | :--- | :--- |
| `i_clk` | Input | 1 | 系统主时钟。 |
| `i_rst_n` | Input | 1 | 异步复位，低电平有效。 |
| `i_valid` | Input | 1 | 输入有效握手信号。 |
| `o_ready` | Output | 1 | 模块就绪信号。 |
| `i_data_bus` | Input | 256 | 16 路并行输入 (16 $\times$ 16-bit Q4.12)。 |
| `o_valid` | Output | 1 | 输出有效握手信号。 |
| `i_ready` | Input | 1 | 下游就绪信号（支持反压）。 |
| `o_data_bus` | Output | 256 | 16 路并行输出 (16 $\times$ 16-bit UQ1.15)。 |
