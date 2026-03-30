`timescale 1ns / 1ps

module exp_lane_stg3 (
    input  wire               i_clk,
    input  wire               i_ena,
    input  wire signed [15:0] x_in,
    input  wire signed [15:0] a_in,
    input  wire signed [15:0] b_in,
    input  wire               uf_in,
    
    output reg  signed [15:0] a_reg,     // 传给 DSP A 端口
    output reg  signed [15:0] x_reg,     // 传给 DSP B 端口
    output reg  signed [32:0] b_ext_reg, // 传给 DSP C 端口
    output reg                uf_pipe
);
    // =========================================================================
    // 仅做符号扩展对齐 (Q2.14 -> 匹配 DSP 输出的 Q6.26)
    // 扩展高 5 位符号位，低位补 12 个 0
    // =========================================================================
    wire signed [32:0] b_ext = {{5{b_in[15]}}, b_in, 12'd0};

    // =========================================================================
    // 将数据打入寄存器，映射到 DSP 的 AREG / BREG / CREG (如果工具支持跨层级优化)
    // =========================================================================
    always @(posedge i_clk) begin
        if (i_ena) begin
            a_reg     <= a_in;
            x_reg     <= x_in;
            b_ext_reg <= b_ext;
            uf_pipe   <= uf_in;
        end
    end

endmodule