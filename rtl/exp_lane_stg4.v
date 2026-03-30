`timescale 1ns / 1ps
module exp_lane_stg4 (
    input  wire        i_clk,
    input  wire        i_ena,   // 必须接入顶层的 ena_stg4
    input  wire signed [31:0] mult_res,
    input  wire signed [15:0] b_in,
    input  wire               uf_in,
    
    output reg         [15:0] y_out
);

    wire signed [32:0] sum;
    wire signed [32:0] b_ext = {{5{b_in[15]}}, b_in, 12'd0};
    
    // 简单的"四舍五入"：加 0.5 LSB
    assign sum = mult_res + b_ext + 33'sd1024;

    always @(posedge i_clk) begin
        if (i_ena) begin // 关键：受顶层 ena_stg4 控制
            if (uf_in) begin
                y_out <= 16'h0000;
            end 
            else if (sum[32]) begin 
                y_out <= 16'h0000; 
            end
            else if (sum[26] || (|sum[31:27])) begin
                y_out <= 16'h8000; 
            end
            else begin
                y_out <= sum[26:11]; 
            end
        end
    end
endmodule