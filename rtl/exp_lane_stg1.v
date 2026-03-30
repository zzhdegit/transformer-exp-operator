`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/28 10:09:10
// Design Name: 
// Module Name: exp_lane_stg1
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


module exp_lane_stg1 (
    input  wire signed [15:0] x_in,           // 输入数据 Q4.12
    output wire signed [15:0] x_out,          // 透传输出数据
    output reg         [4:0]  idx_out,        // 区间索引 (0~31)
    output wire               underflow_flag  // 下溢出标志 (x < -8.0)
);
    `include "exp_params.vh"
    // =========================================================================
    // 逻辑实现
    // =========================================================================
    
    // 1. 数据透传
    assign x_out = x_in;

    // 2. 下溢出检查: 比较下界 16'shC000 (-8.0 in Q4.12)
    // 采用有符号比较确保逻辑正确性
    assign underflow_flag = (x_in < 16'sh8000);

    // 3. 比较器树逻辑生成 5-bit 区间索引
    always @(*) begin
        if      (x_in < BND_00) idx_out = 5'd0;
        else if (x_in < BND_01) idx_out = 5'd1;
        else if (x_in < BND_02) idx_out = 5'd2;
        else if (x_in < BND_03) idx_out = 5'd3;
        else if (x_in < BND_04) idx_out = 5'd4;
        else if (x_in < BND_05) idx_out = 5'd5;
        else if (x_in < BND_06) idx_out = 5'd6;
        else if (x_in < BND_07) idx_out = 5'd7;
        else if (x_in < BND_08) idx_out = 5'd8;
        else if (x_in < BND_09) idx_out = 5'd9;
        else if (x_in < BND_10) idx_out = 5'd10;
        else if (x_in < BND_11) idx_out = 5'd11;
        else if (x_in < BND_12) idx_out = 5'd12;
        else if (x_in < BND_13) idx_out = 5'd13;
        else if (x_in < BND_14) idx_out = 5'd14;
        else if (x_in < BND_15) idx_out = 5'd15;
        else if (x_in < BND_16) idx_out = 5'd16;
        else if (x_in < BND_17) idx_out = 5'd17;
        else if (x_in < BND_18) idx_out = 5'd18;
        else if (x_in < BND_19) idx_out = 5'd19;
        else if (x_in < BND_20) idx_out = 5'd20;
        else if (x_in < BND_21) idx_out = 5'd21;
        else if (x_in < BND_22) idx_out = 5'd22;
        else if (x_in < BND_23) idx_out = 5'd23;
        else if (x_in < BND_24) idx_out = 5'd24;
        else if (x_in < BND_25) idx_out = 5'd25;
        else if (x_in < BND_26) idx_out = 5'd26;
        else if (x_in < BND_27) idx_out = 5'd27;
        else if (x_in < BND_28) idx_out = 5'd28;
        else if (x_in < BND_29) idx_out = 5'd29;
        else if (x_in < BND_30) idx_out = 5'd30;
        else                    idx_out = 5'd31;
    end

endmodule