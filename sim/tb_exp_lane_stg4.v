`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/28 15:44:12
// Design Name: 
// Module Name: tb_exp_lane_stg4
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


module tb_exp_lane_stg4;
    reg i_clk, i_ena, uf_in;
    reg signed [31:0] mult_res;
    reg signed [15:0] b_in;
    wire [15:0] y_out;

    exp_lane_stg4 uut (
        .i_clk(i_clk), .i_ena(i_ena), .mult_res(mult_res), .b_in(b_in), .uf_in(uf_in),
        .y_out(y_out)
    );

    initial i_clk = 0;
    always #1.25 i_clk = ~i_clk;

    initial begin
        i_ena = 1; uf_in = 0; mult_res = 0; b_in = 0;
        #10;
        $display("--- Stage 4 Unit Test Start ---");
        
        // Case 1: 正常加法与截断
        @(negedge i_clk); mult_res = 32'sh0040_0000; b_in = 16'h0000; // Q6.26 中 0.0625
        
        // Case 2: 舍入临界点 (刚好需要进位)
        // 目标保留 15 位小数，第 16 位是 sum[10]。我们加 1024(2^10) 看进位
        @(negedge i_clk); mult_res = 32'h0000_03FF; b_in = 16'h0000; // 差一点进位
        @(negedge i_clk); mult_res = 32'h0000_0400; b_in = 16'h0000; // 刚好进位 (0.5 LSB)

        // Case 3: 正向饱和 (结果 > 1.0)
        @(negedge i_clk); mult_res = 32'sh0400_0000; b_in = 16'h4000; // 1.0 + 0.5
        
        // Case 4: 负向饱和 (结果 < 0)
        @(negedge i_clk); mult_res = -32'sh0080_0000; b_in = 16'h0000; 

        // Case 5: Underflow 标志测试
        @(negedge i_clk); mult_res = 32'sh0020_0000; b_in = 16'h1000; uf_in = 1;

        #50;
        $display("--- Stage 4 Unit Test End ---");
        $finish;
    end

    always @(posedge i_clk) begin
        $display("Time:%t | Mult:%h B:%h UF:%b | Y_Out:%h (Float:%f)", 
                 $time, mult_res, b_in, uf_in, y_out, y_out/32768.0);
    end
endmodule
