`timescale 1ns / 1ps

module tb_exp_batch_16lane;

    // =========================================================================
    // 1. 信号声明
    // =========================================================================
    reg          i_clk;
    reg          i_rst_n;
    reg          i_valid;
    wire         o_ready;
    reg  [255:0] i_data_bus;
    wire         o_valid;
    reg          i_ready;
    wire [255:0] o_data_bus;

    // =========================================================================
    // 2. 时钟与复位 (适配 400MHz: 周期 2.5ns -> 半周期 1.25ns)
    // =========================================================================
    initial begin
        i_clk = 0;
        forever #1.25 i_clk = ~i_clk; 
    end

    initial begin
        i_rst_n = 0;
        #23.5 i_rst_n = 1; // 异步复位释放
    end

    // =========================================================================
    // 3. 顶层例化 (UUT)
    // =========================================================================
    exp_sfu_top uut (
        .i_clk      (i_clk), 
        .i_rst_n    (i_rst_n), 
        .i_valid    (i_valid), 
        .o_ready    (o_ready),
        .i_data_bus (i_data_bus), 
        .o_valid    (o_valid), 
        .i_ready    (i_ready), 
        .o_data_bus (o_data_bus)
    );

    // =========================================================================
    // 4. 批量读写逻辑
    // =========================================================================
    reg [15:0] stim_mem [0:799]; // 存储 800 个 16-bit 样本
    integer fd_out;
    integer i, j, k;
    integer total_count = 0;

    initial begin
        // 初始状态
        i_valid    = 0;
        i_data_bus = 0;
        i_ready    = 1; // 默认下游畅通，进行纯精度测试

        // 【！！！请务必确认这里的路径与你的 Python 脚本一致！！！】
        $readmemh("C:/fpga_code/py_sfu/stimulus_800.txt", stim_mem);
        fd_out = $fopen("C:/fpga_code/py_sfu/rtl_output_800.txt", "w");
        
        if (fd_out == 0) begin
            $display("错误：无法创建输出文件！请检查路径。");
            $finish;
        end

        @(posedge i_rst_n);
        repeat(10) @(posedge i_clk);

        $display(" [BATCH TEST] 启动 16 路全并行精度验证...");
        $display("? [CONFIG] 时钟频率: 400MHz | 目标样本数: 800");

        // 每次喂入 1 拍 (16个数据)，共 50 拍
        for (i = 0; i < 50; i = i + 1) begin
            @(negedge i_clk);
            i_valid = 1;
            
            // 拼接 256-bit 总线
            for (j = 0; j < 16; j = j + 1) begin
                i_data_bus[j*16 +: 16] = stim_mem[i*16 + j];
            end
            
            @(posedge i_clk);
            // 等待握手成功 (如果被反压，i_valid 保持)
            while (!o_ready) @(posedge i_clk);
        end
        
        // 50 拍发完，撤销有效信号
        @(negedge i_clk);
        i_valid = 0;
        i_data_bus = 0;

        // 等待流水线完全排空 (4级管线，至少等 10-20 拍确保 o_valid 清零)
        $display("数据灌入完毕，等待流水线排空...");
        repeat(20) @(posedge i_clk);
        
        $fclose(fd_out);
        $display("[SUCCESS] 批量验证完成！结果已写入 rtl_output_800.txt");
        $display(" 共计处理 Lane 样本: %d 个", total_count);
        $finish;
    end

    // =========================================================================
    // 5. 自动解包写入线程 (基于 o_valid 触发)
    // =========================================================================
    always @(posedge i_clk) begin
        // 当输出端握手成功时 (Valid & Ready)，才写文件
        if (i_rst_n && o_valid && i_ready) begin
            for (k = 0; k < 16; k = k + 1) begin
                $fdisplay(fd_out, "%04X", o_data_bus[k*16 +: 16]);
                total_count = total_count + 1;
            end
        end
    end

endmodule