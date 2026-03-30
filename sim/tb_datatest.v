`timescale 1ns / 1ps

module tb_datatest();

    // 信号声明
    reg i_clk, i_rst_n, i_valid, i_ready;
    reg [255:0] i_data_bus;
    wire o_ready, o_valid;
    wire [255:0] o_data_bus;

    // 循环变量声明 (修复 VRFC 10-2019 的关键)
    integer i, j, k; 
    integer fd_out, total_recv_count;
    reg [15:0] stim_mem [0:799];

    // 实例化顶层
    exp_top uut (
        .i_clk(i_clk), .i_rst_n(i_rst_n), .i_valid(i_valid), .o_ready(o_ready),
        .i_data_bus(i_data_bus), .o_valid(o_valid), .i_ready(i_ready), .o_data_bus(o_data_bus)
    );

    // 时钟生成 (350MHz)
    initial begin i_clk = 0; forever #1.428 i_clk = ~i_clk; end

    initial begin
        i_rst_n = 0; i_valid = 0; i_data_bus = 0; i_ready = 1;
        total_recv_count = 0;
        
        // 请确保路径正确
        $readmemh("C:/fpga_code/py_sfu/stimulus_800.txt", stim_mem);
        fd_out = $fopen("C:/fpga_code/py_sfu/rtl_output_800.txt", "w");
        
        #20 i_rst_n = 1;
        #10;

        // 灌入 800 个数据 (50 拍 * 16 Lane)
        for (i = 0; i < 50; i = i + 1) begin
            @(negedge i_clk);
            i_valid = 1;
            for (j = 0; j < 16; j = j + 1) begin
                i_data_bus[j*16 +: 16] = stim_mem[i*16 + j];
            end
            @(posedge i_clk);
            while (!o_ready) @(posedge i_clk); // 弹性握手
        end
        
        @(negedge i_clk); i_valid = 0;
        wait(total_recv_count >= 800);
        #50;
        $fclose(fd_out);
        $display("Done! Total received: %d", total_recv_count);
        $finish;
    end

    // 结果写入逻辑
    always @(posedge i_clk) begin
        if (i_rst_n && o_valid && i_ready) begin
            for (k = 0; k < 16; k = k + 1) begin
                $fdisplay(fd_out, "%04X", o_data_bus[k*16 +: 16]);
                total_recv_count = total_recv_count + 1;
            end
        end
    end

endmodule