`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/28 11:53:59
// Design Name: 
// Module Name: tb_exp_lane_stg2
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



module tb_exp_lane_stg2;

    // =========================================================================
    // 信号声明
    // =========================================================================
    reg  signed [15:0] x_in;
    reg         [4:0]  idx_in;
    reg                underflow_flag_in;
    
    wire signed [15:0] x_out;
    wire signed [15:0] a_out;
    wire signed [15:0] b_out;
    wire               underflow_flag_out;

    // 循环变量
    integer i;

    // =========================================================================
    // 待测模块例化 (UUT)
    // =========================================================================
    exp_lane_stg2 uut (
        .x_in               (x_in),
        .idx_in             (idx_in),
        .underflow_flag_in  (underflow_flag_in),
        .x_out              (x_out),
        .a_out              (a_out),
        .b_out              (b_out),
        .underflow_flag_out (underflow_flag_out)
    );

    // =========================================================================
    // 包含参数头文件 (仅用于在仿真器波形中方便核对，可选)
    // =========================================================================
    `include "exp_params.vh"

    // =========================================================================
    // 测试激励发生器
    // =========================================================================
    initial begin
        // 初始化信号
        x_in              = 16'sh0000;
        idx_in            = 5'd0;
        underflow_flag_in = 1'b0;

        // 等待全局复位/稳定
        #10;

        // 初始化打印表头
        $display("=========================================================================================");
        $display("                           exp_lane_stg2 LUT & Passthrough Test                          ");
        $display("=========================================================================================");
        $display(" Time | idx_in | uf_in | uf_out |  x_in  |  x_out |  a_out(Hex)  |  b_out(Hex) ");
        $display("-----------------------------------------------------------------------------------------");

        // 遍历所有 32 个区间索引
        for (i = 0; i < 32; i = i + 1) begin
            
            // 1. 赋值 idx_in
            idx_in = i;

            // 2. 前半段设为 0 (0~15)，后半段设为 1 (16~31)
            if (i < 16) begin
                underflow_flag_in = 1'b0;
            end else begin
                underflow_flag_in = 1'b1;
            end

            // 3. 构造一个变化的 x_in 验证透传逻辑 (例如 16'hA5A5 异或 i)
            x_in = 16'shA5A5 ^ i;

            // 延迟 10ns 让组合逻辑稳定
            #10;

            // 4. 打印当前状态
            $display("%5t |   %2d   |   %b   |   %b    |  %h  |  %h  |     %h     |     %h    ", 
                     $time, idx_in, underflow_flag_in, underflow_flag_out, 
                     x_in, x_out, a_out, b_out);
            
            // 可选的自检逻辑：检查透传是否成功
            if (x_in !== x_out) begin
                $display("ERROR at time %0t: x_out mismatch! expected %h, got %h", $time, x_in, x_out);
            end
            if (underflow_flag_in !== underflow_flag_out) begin
                $display("ERROR at time %0t: underflow_flag mismatch!", $time);
            end
        end

        $display("=========================================================================================");
        $display("Test Completed!");
        $finish;
    end

endmodule