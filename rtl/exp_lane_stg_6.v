`timescale 1ns / 1ps

module exp_lane_stg6 (
    input  wire               i_clk,
    input  wire               i_ena,
    
    // 来自 Stage 4 的 DSP PREG 输出
    input  wire signed [32:0] sum_in,
    input  wire               uf_in,
    
    // 输出至 Stage 6
    output reg                force_0000, // 强制下溢清零标志
    output reg                force_8000, // 强制正向饱和标志
    output reg  [15:0]        normal_val  // 正常截取值
);

    // =========================================================================
    // 组合逻辑判定区 (结果将在下一拍打入触发器)
    // =========================================================================
    
    // 提取符号位 (1 为负数)
    wire sign_bit = sum_in[32];
    
    // 正向溢出判定：
    // 目标格式为 UQ1.15，最高只能表达接近 1.0 的值。
    // 如果 sum_in[26] (即 2^0 位) 为 1，或者更高的整数位有任何为 1 的情况，即判定溢出。
    wire exp_pos_ovf = sum_in[26] || (|sum_in[31:27]);

    // =========================================================================
    // 标志位生成与数据截断
    // =========================================================================
    always @(posedge i_clk) begin
        if (i_ena) begin
            // 优先级 1: e^x 绝对下溢出 (x < 起点) 或 计算结果意外出现负数，强制清零
            force_0000 <= uf_in || sign_bit;
            
            // 优先级 2: e^x 结果为正数但发生溢出，强制饱和到 UQ1.15 的最大值 16'h8000
            force_8000 <= !sign_bit && exp_pos_ovf;
            
            // 优先级 3: 正常截断，提取 Q6.26 中对应 Q1.15 的 [26:11] 位
            normal_val <= sum_in[26:11];
        end
    end

endmodule