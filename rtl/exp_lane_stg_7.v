`timescale 1ns / 1ps

module exp_lane_stg7 (
    input  wire               i_clk,
    input  wire               i_ena,
    
    // 来自 Stage 5 的控制标志与数据
    input  wire               force_0000,
    input  wire               force_8000,
    input  wire [15:0]        normal_val,
    
    // 输出至 Stage 7 (顶层总线聚合寄存器)
    output reg  [15:0]        y_out
);

    // =========================================================================
    // 严禁综合器提取控制集 (Control Sets)。
    // 强制这些条件判断走最快的局部数据连线 (D-pin)，防止控制逻辑拥塞
    // =========================================================================
    (* extract_reset = "no", extract_set = "no" *)
    always @(posedge i_clk) begin
        if (i_ena) begin
            if      (force_0000) y_out <= 16'h0000;
            else if (force_8000) y_out <= 16'h8000;
            else                 y_out <= normal_val;
        end
    end

endmodule