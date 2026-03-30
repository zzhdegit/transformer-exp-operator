`timescale 1ns / 1ps

module exp_lane_stg1 (
    input  wire signed [15:0] x_in,           // 输入数据 Q4.12
    output wire signed [15:0] x_out,          // 透传输出数据
    output reg  [4:0]         idx_out,        // 区间索引 (0~31)
    output wire               underflow_flag  // 下溢出标志
);
    // 包含 NPLA 参数头文件 (必须定义 BND_EXP_00 ~ BND_EXP_30 以及 BND_EXP_MIN)
    `include "exp_params.vh"

    // =========================================================================
    // 1. 数据透传
    // =========================================================================
    assign x_out = x_in;

    // =========================================================================
    // 2. 越界处理 (下溢出)
    // =========================================================================
    // 小于真实的 e^x 拟合起点，判定为下溢出，后续强制清零
    assign underflow_flag = (x_in < BND_EXP_MIN);

    // =========================================================================
    // 3. 400MHz 友好型比较器树 (完整展开的二叉搜索树)
    // =========================================================================
    always @(*) begin
        if (x_in < BND_EXP_15) begin
            if (x_in < BND_EXP_07) begin
                if (x_in < BND_EXP_03) begin
                    if (x_in < BND_EXP_01) begin
                        if (x_in < BND_EXP_00) idx_out = 5'd0;
                        else                   idx_out = 5'd1;
                    end else begin
                        if (x_in < BND_EXP_02) idx_out = 5'd2;
                        else                   idx_out = 5'd3;
                    end
                end else begin
                    if (x_in < BND_EXP_05) begin
                        if (x_in < BND_EXP_04) idx_out = 5'd4;
                        else                   idx_out = 5'd5;
                    end else begin
                        if (x_in < BND_EXP_06) idx_out = 5'd6;
                        else                   idx_out = 5'd7;
                    end
                end
            end else begin
                if (x_in < BND_EXP_11) begin
                    if (x_in < BND_EXP_09) begin
                        if (x_in < BND_EXP_08) idx_out = 5'd8;
                        else                   idx_out = 5'd9;
                    end else begin
                        if (x_in < BND_EXP_10) idx_out = 5'd10;
                        else                   idx_out = 5'd11;
                    end
                end else begin
                    if (x_in < BND_EXP_13) begin
                        if (x_in < BND_EXP_12) idx_out = 5'd12;
                        else                   idx_out = 5'd13;
                    end else begin
                        if (x_in < BND_EXP_14) idx_out = 5'd14;
                        else                   idx_out = 5'd15;
                    end
                end
            end
        end else begin
            // x_in >= BND_EXP_15
            if (x_in < BND_EXP_23) begin
                if (x_in < BND_EXP_19) begin
                    if (x_in < BND_EXP_17) begin
                        if (x_in < BND_EXP_16) idx_out = 5'd16;
                        else                   idx_out = 5'd17;
                    end else begin
                        if (x_in < BND_EXP_18) idx_out = 5'd18;
                        else                   idx_out = 5'd19;
                    end
                end else begin
                    if (x_in < BND_EXP_21) begin
                        if (x_in < BND_EXP_20) idx_out = 5'd20;
                        else                   idx_out = 5'd21;
                    end else begin
                        if (x_in < BND_EXP_22) idx_out = 5'd22;
                        else                   idx_out = 5'd23;
                    end
                end
            end else begin
                if (x_in < BND_EXP_27) begin
                    if (x_in < BND_EXP_25) begin
                        if (x_in < BND_EXP_24) idx_out = 5'd24;
                        else                   idx_out = 5'd25;
                    end else begin
                        if (x_in < BND_EXP_26) idx_out = 5'd26;
                        else                   idx_out = 5'd27;
                    end
                end else begin
                    if (x_in < BND_EXP_29) begin
                        if (x_in < BND_EXP_28) idx_out = 5'd28;
                        else                   idx_out = 5'd29;
                    end else begin
                        if (x_in < BND_EXP_30) idx_out = 5'd30;
                        else                   idx_out = 5'd31;
                    end
                end
            end
        end
    end

endmodule