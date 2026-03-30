`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/28 10:34:59
// Design Name: 
// Module Name: exp_lane_stg2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module exp_lane_stg2 (
    // 数据通路输入
    input  wire signed [15:0] x_in,               // 透传输入数据 Q4.12
    input  wire        [4:0]  idx_in,             // 区间索引 (0~31)
    input  wire               underflow_flag_in,  // 透传下溢出标志
    
    // 数据通路输出
    output wire signed [15:0] x_out,              // 透传输出数据 Q4.12
    output reg  signed [15:0] a_out,              // 查表输出斜率 a (Q2.14)
    output reg  signed [15:0] b_out,              // 查表输出截距 b (Q2.14)
    output wire               underflow_flag_out  // 透传下溢出标志
);

    // =========================================================================
    // 包含 NPLA 参数头文件 (定义了 COEF_A_xx 和 COEF_B_xx 的 localparam)
    // =========================================================================
    `include "exp_params.vh"

    // =========================================================================
    // 逻辑实现
    // =========================================================================
    
    // 1. 数据与控制信号透传
    assign x_out = x_in;
    assign underflow_flag_out = underflow_flag_in;

    // 2. 深度为 32 的 LUT 查找逻辑 (纯组合逻辑)
    // 根据 idx_in 提取对应的斜率 a 和 截距 b (Q2.14 格式)
    always @(*) begin
        case (idx_in)
            5'd0 : begin a_out = COEF_A_00; b_out = COEF_B_00; end
            5'd1 : begin a_out = COEF_A_01; b_out = COEF_B_01; end
            5'd2 : begin a_out = COEF_A_02; b_out = COEF_B_02; end
            5'd3 : begin a_out = COEF_A_03; b_out = COEF_B_03; end
            5'd4 : begin a_out = COEF_A_04; b_out = COEF_B_04; end
            5'd5 : begin a_out = COEF_A_05; b_out = COEF_B_05; end
            5'd6 : begin a_out = COEF_A_06; b_out = COEF_B_06; end
            5'd7 : begin a_out = COEF_A_07; b_out = COEF_B_07; end
            5'd8 : begin a_out = COEF_A_08; b_out = COEF_B_08; end
            5'd9 : begin a_out = COEF_A_09; b_out = COEF_B_09; end
            5'd10: begin a_out = COEF_A_10; b_out = COEF_B_10; end
            5'd11: begin a_out = COEF_A_11; b_out = COEF_B_11; end
            5'd12: begin a_out = COEF_A_12; b_out = COEF_B_12; end
            5'd13: begin a_out = COEF_A_13; b_out = COEF_B_13; end
            5'd14: begin a_out = COEF_A_14; b_out = COEF_B_14; end
            5'd15: begin a_out = COEF_A_15; b_out = COEF_B_15; end
            5'd16: begin a_out = COEF_A_16; b_out = COEF_B_16; end
            5'd17: begin a_out = COEF_A_17; b_out = COEF_B_17; end
            5'd18: begin a_out = COEF_A_18; b_out = COEF_B_18; end
            5'd19: begin a_out = COEF_A_19; b_out = COEF_B_19; end
            5'd20: begin a_out = COEF_A_20; b_out = COEF_B_20; end
            5'd21: begin a_out = COEF_A_21; b_out = COEF_B_21; end
            5'd22: begin a_out = COEF_A_22; b_out = COEF_B_22; end
            5'd23: begin a_out = COEF_A_23; b_out = COEF_B_23; end
            5'd24: begin a_out = COEF_A_24; b_out = COEF_B_24; end
            5'd25: begin a_out = COEF_A_25; b_out = COEF_B_25; end
            5'd26: begin a_out = COEF_A_26; b_out = COEF_B_26; end
            5'd27: begin a_out = COEF_A_27; b_out = COEF_B_27; end
            5'd28: begin a_out = COEF_A_28; b_out = COEF_B_28; end
            5'd29: begin a_out = COEF_A_29; b_out = COEF_B_29; end
            5'd30: begin a_out = COEF_A_30; b_out = COEF_B_30; end
            5'd31: begin a_out = COEF_A_31; b_out = COEF_B_31; end
            default: begin a_out = 16'sh0000; b_out = 16'sh0000; end
        endcase
    end

endmodule
