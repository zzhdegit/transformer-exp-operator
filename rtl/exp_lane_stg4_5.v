`timescale 1ns / 1ps

module exp_lane_stg4_5 (
    input  wire           i_clk,
    input  wire           i_ena_m1,  // 第一拍使能 (映射到 DSP 的 MREG)
    input  wire           i_ena_m2,  // 第二拍使能 (映射到 DSP 的 PREG)
    
    // 输入数据类型严格对齐 SFU：不在这里写 signed，依靠内部 $signed 转换
    input  wire [15:0]    a_reg,
    input  wire [15:0]    x_reg,
    input  wire [32:0]    b_ext_reg,
    input  wire           uf_in,
    
    output reg  [32:0]    sum_out,
    output reg            uf_out
);

    // 内部流水线寄存器 (Vivado 会自动将其映射到 DSP48 的 M-Register)
    reg signed [31:0] mult_mreg;
    reg signed [32:0] b_ext_delay;
    reg               uf_delay;

    // 第一拍：乘法阵列运算 -> 锁入 MREG
    always @(posedge i_clk) begin
        if (i_ena_m1) begin
            // 严格对齐 SFU：使用显式 $signed 转换，防止综合器乱推断
            mult_mreg   <= $signed(a_reg) * $signed(x_reg);
            b_ext_delay <= b_ext_reg; 
            uf_delay    <= uf_in;
        end
    end

    // 第二拍：加法器运算 -> 锁入 PREG (输出)
    always @(posedge i_clk) begin
        if (i_ena_m2) begin
            // 严格对齐 SFU：去除常数偏移，保持纯净的 2 操作数加法，确保吸收入 PREG
            sum_out <= mult_mreg + b_ext_delay;
            uf_out  <= uf_delay;
        end
    end

endmodule