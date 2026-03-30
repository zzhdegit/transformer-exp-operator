`timescale 1ns / 1ps

module tb_exp_lane_stg3;
    reg i_clk;
    reg i_ena;
    reg signed [15:0] x_in, a_in, b_in;
    reg uf_in;
    wire signed [31:0] mult_res;
    wire signed [15:0] b_pipe;
    wire uf_pipe;

    exp_lane_stg3 uut (
        .i_clk(i_clk), .i_ena(i_ena), .x_in(x_in), .a_in(a_in), .b_in(b_in), .uf_in(uf_in),
        .mult_res(mult_res), .b_pipe(b_pipe), .uf_pipe(uf_pipe)
    );

    initial i_clk = 0;
    always #1.25 i_clk = ~i_clk; // 400MHz

    initial begin
        i_ena = 1; x_in = 0; a_in = 0; b_in = 0; uf_in = 0;
        #10;
        
        $display("--- Stage 3 Unit Test Start ---");
        // Case 1: 常规正数乘法
        @(negedge i_clk); a_in = 16'sh2000; x_in = 16'sh1000; // 0.5 * 1.0 (Q2.14 * Q4.12)
        // Case 2: 负数乘法 (最严苛边界)
        @(negedge i_clk); a_in = 16'sh8000; x_in = 16'sh7FFF; // -2.0 * 7.999
        // Case 3: 零值测试
        @(negedge i_clk); a_in = 16'sh0000; x_in = 16'shFFFF;
        
        // Case 4: Enable 信号测试 (数据锁定检查)
        @(negedge i_clk); a_in = 16'sh1234; x_in = 16'sh5678; i_ena = 0; 
        repeat(3) @(posedge i_clk);
        // 在 i_ena=0 时更改输入，输出不应变化
        @(negedge i_clk); a_in = 16'shFFFF; x_in = 16'shFFFF; 
        repeat(2) @(posedge i_clk);
        i_ena = 1;
        
        #50;
        $display("--- Stage 3 Unit Test End ---");
        $finish;
    end

    always @(posedge i_clk) begin
        if (i_ena)
            $display("Time:%t | A:%h X:%h | Mult_Res:%h | Pipe_B:%h", $time, a_in, x_in, mult_res, b_pipe);
        else
            $display("Time:%t | [STALL] Mult_Res Fixed at:%h", $time, mult_res);
    end
endmodule