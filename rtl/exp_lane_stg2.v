`timescale 1ns / 1ps

module exp_lane_stg2 (
    input  wire signed [15:0] x_in,              
    input  wire        [4:0]  idx_in,             
    input  wire               underflow_flag_in,  
    
    output wire signed [15:0] x_out,              
    output reg  signed [15:0] a_out,            
    output reg  signed [15:0] b_out,             
    output wire               underflow_flag_out  
);
    // 包含 NPLA 参数头文件 (必须定义 COEF_A_EXP_xx 和 COEF_B_EXP_xx)
    `include "exp_params.vh"

    // =========================================================================
    // 1. 数据与控制信号透传
    // =========================================================================
    assign x_out = x_in;
    assign underflow_flag_out = underflow_flag_in;

    // =========================================================================
    // 2. 深度为 32 的 LUT 查找逻辑 (纯组合逻辑)
    // =========================================================================
    always @(*) begin
        case (idx_in)
            5'd0 : begin a_out = COEF_A_EXP_00; b_out = COEF_B_EXP_00; end
            5'd1 : begin a_out = COEF_A_EXP_01; b_out = COEF_B_EXP_01; end
            5'd2 : begin a_out = COEF_A_EXP_02; b_out = COEF_B_EXP_02; end
            5'd3 : begin a_out = COEF_A_EXP_03; b_out = COEF_B_EXP_03; end
            5'd4 : begin a_out = COEF_A_EXP_04; b_out = COEF_B_EXP_04; end
            5'd5 : begin a_out = COEF_A_EXP_05; b_out = COEF_B_EXP_05; end
            5'd6 : begin a_out = COEF_A_EXP_06; b_out = COEF_B_EXP_06; end
            5'd7 : begin a_out = COEF_A_EXP_07; b_out = COEF_B_EXP_07; end
            5'd8 : begin a_out = COEF_A_EXP_08; b_out = COEF_B_EXP_08; end
            5'd9 : begin a_out = COEF_A_EXP_09; b_out = COEF_B_EXP_09; end
            5'd10: begin a_out = COEF_A_EXP_10; b_out = COEF_B_EXP_10; end
            5'd11: begin a_out = COEF_A_EXP_11; b_out = COEF_B_EXP_11; end
            5'd12: begin a_out = COEF_A_EXP_12; b_out = COEF_B_EXP_12; end
            5'd13: begin a_out = COEF_A_EXP_13; b_out = COEF_B_EXP_13; end
            5'd14: begin a_out = COEF_A_EXP_14; b_out = COEF_B_EXP_14; end
            5'd15: begin a_out = COEF_A_EXP_15; b_out = COEF_B_EXP_15; end
            5'd16: begin a_out = COEF_A_EXP_16; b_out = COEF_B_EXP_16; end
            5'd17: begin a_out = COEF_A_EXP_17; b_out = COEF_B_EXP_17; end
            5'd18: begin a_out = COEF_A_EXP_18; b_out = COEF_B_EXP_18; end
            5'd19: begin a_out = COEF_A_EXP_19; b_out = COEF_B_EXP_19; end
            5'd20: begin a_out = COEF_A_EXP_20; b_out = COEF_B_EXP_20; end
            5'd21: begin a_out = COEF_A_EXP_21; b_out = COEF_B_EXP_21; end
            5'd22: begin a_out = COEF_A_EXP_22; b_out = COEF_B_EXP_22; end
            5'd23: begin a_out = COEF_A_EXP_23; b_out = COEF_B_EXP_23; end
            5'd24: begin a_out = COEF_A_EXP_24; b_out = COEF_B_EXP_24; end
            5'd25: begin a_out = COEF_A_EXP_25; b_out = COEF_B_EXP_25; end
            5'd26: begin a_out = COEF_A_EXP_26; b_out = COEF_B_EXP_26; end
            5'd27: begin a_out = COEF_A_EXP_27; b_out = COEF_B_EXP_27; end
            5'd28: begin a_out = COEF_A_EXP_28; b_out = COEF_B_EXP_28; end
            5'd29: begin a_out = COEF_A_EXP_29; b_out = COEF_B_EXP_29; end
            5'd30: begin a_out = COEF_A_EXP_30; b_out = COEF_B_EXP_30; end
            5'd31: begin a_out = COEF_A_EXP_31; b_out = COEF_B_EXP_31; end
            default: begin a_out = 16'sh0000;   b_out = 16'sh0000; end
        endcase
    end

endmodule