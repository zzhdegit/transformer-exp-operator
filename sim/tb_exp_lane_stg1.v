`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/28 11:53:33
// Design Name: 
// Module Name: tb_exp_lane_stg1
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


module tb_exp_lane_stg1;

    // =========================================================================
    // 信号声明
    // =========================================================================
    reg  signed [15:0] x_in;
    wire signed [15:0] x_out;
    wire        [4:0]  idx_out;
    wire               underflow_flag;

    // =========================================================================
    // 待测模块例化 (UUT)
    // =========================================================================
    exp_lane_stg1 uut (
        .x_in           (x_in),
        .x_out          (x_out),
        .idx_out        (idx_out),
        .underflow_flag (underflow_flag)
    );

    // =========================================================================
    // 测试激励发生器
    // =========================================================================
    initial begin
        // 初始化打印表头
        $display("=====================================================================");
        $display("                   exp_lane_stg1 Combinational Test                  ");
        $display("=====================================================================");
        $display(" Time | x_in(Hex) | x_in(Float Approx) | idx_out(Dec) | underflow_flag");
        $display("---------------------------------------------------------------------");

        // 1. 极端下界溢出场景（用户预期的 -8.5，实际在 Q4.12 中会溢出为 +7.5）
        // 验证：由于符号位翻转，Verilog 会认为它是正数，underflow_flag 预期为 0
        x_in = 16'sh7800; 
        #10;
        $display("%5t |   %h  |      +7.5 (Wrapped)  |      %2d      |       %b", $time, x_in, idx_out, underflow_flag);

        // 2. 真正的物理下界临界点：-8.0
        // 验证：触发真正的负向边界，underflow_flag 预期为 1
        x_in = 16'sh8000; 
        #10;
        $display("%5t |   %h  |      -8.0            |      %2d      |       %b", $time, x_in, idx_out, underflow_flag);

        // 3. 用户之前定义的阈值临界点：-4.0
        // 验证：之前 stg1 中代码阈值为 C000，如果以此为界，这里会被判定为边界
        x_in = 16'shC000; 
        #10;
        $display("%5t |   %h  |      -4.0            |      %2d      |       %b", $time, x_in, idx_out, underflow_flag);

        // 4. 区间中间值测试：例如 -6.0472 (BND_00 附近的值，用 -6.5 测试)
        x_in = 16'sh9800; // -6.5
        #10;
        $display("%5t |   %h  |      -6.5            |      %2d      |       %b", $time, x_in, idx_out, underflow_flag);

        // 5. 零点临界点：0.0
        x_in = 16'sh0000; 
        #10;
        $display("%5t |   %h  |       0.0            |      %2d      |       %b", $time, x_in, idx_out, underflow_flag);

        // 6. 略小于零的临界点：-0.000244 (补码全 1)
        x_in = 16'shFFFF; 
        #10;
        $display("%5t |   %h  |      -0.00024        |      %2d      |       %b", $time, x_in, idx_out, underflow_flag);

        $display("=====================================================================");
        $finish;
    end

endmodule
