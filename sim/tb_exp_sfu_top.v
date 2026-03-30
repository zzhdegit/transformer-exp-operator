`timescale 1ns / 1ps

module tb_exp_sfu_top;

    // =========================================================================
    // 1. 信号声明与参数
    // =========================================================================
    reg          i_clk;
    reg          i_rst_n;
    reg          i_valid;
    wire         o_ready;
    reg  [255:0] i_data_bus;
    wire         o_valid;
    reg          i_ready;
    wire [255:0] o_data_bus;

    // 400MHz 时钟生成 (2.5ns)
    initial begin
        i_clk = 1'b0;
        forever #1.25 i_clk = ~i_clk; 
    end

    // =========================================================================
    // 2. 待测模块例化
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
    // 3. 测试 Task：精准注入
    // =========================================================================
    task send_one_word;
        input [15:0] val;
        integer j;
        begin
            @(negedge i_clk);
            i_valid = 1'b1;
            for (j = 0; j < 16; j = j + 1) i_data_bus[j*16 +: 16] = val;
            @(posedge i_clk);
            while (!o_ready) @(posedge i_clk);
            i_valid = 1'b0;
        end
    endtask

    // =========================================================================
    // 4. 压力测试逻辑
    // =========================================================================
    integer i;
    initial begin
        // 初始化
        i_rst_n = 1'b0;
        i_valid = 1'b0;
        i_ready = 1'b0; // 初始状态下游不就绪
        i_data_bus = 0;

        #12.5 i_rst_n = 1'b1; // 复位释放
        repeat(5) @(posedge i_clk);

        // -----------------------------------------------------------------
        // 阶段 1：边界数值陷阱 (Corner Case)
        // 验证：x=0(最大), x=-8(最小), 下溢出边界
        // -----------------------------------------------------------------
        $display("[%0t] === Phase 1: Corner Case Injection ===", $time);
        i_ready = 1'b1;
        send_one_word(16'sh0000); // e^0 = 1.0 (Output should be 0x8000)
        send_one_word(16'sh8000); // e^-8 = 0.0 (Underflow)
        send_one_word(16'shF000); // 负微小值
        repeat(5) @(posedge i_clk);

        // -----------------------------------------------------------------
        // 阶段 2：握手信号"绞肉机" (The Meat Grinder)
        // 验证：i_valid 和 i_ready 同时随机跳变，测试流水线是否会丢数或死锁
        // -----------------------------------------------------------------
        $display("[%0t] === Phase 2: Random Handshake Stress Test ===", $time);
        fork
            // 线程1: 尝试灌入 50 个数据
            begin
                for (i = 0; i < 50; i = i + 1) begin
                    @(negedge i_clk);
                    i_valid = ($random % 100 < 70); // 70% 概率有数
                    if (i_valid) i_data_bus = {16{16'shC000 + i}}; 
                    @(posedge i_clk);
                    while (i_valid && !o_ready) @(posedge i_clk);
                end
                i_valid = 0;
            end
            // 线程2: 下游随机反压
            begin
                repeat(100) begin
                    @(negedge i_clk);
                    i_ready = ($random % 100 < 50); // 50% 概率反压
                end
                i_ready = 1'b1;
            end
        join

        // -----------------------------------------------------------------
        // 阶段 3：运行时复位测试 (Reset Mid-Stream)
        // 验证：在数据传输过程中突然复位，模块是否能清空状态并重新开始
        // -----------------------------------------------------------------
        $display("[%0t] === Phase 3: Mid-Stream Reset Recovery ===", $time);
        i_valid = 1'b1;
        i_ready = 1'b1;
        repeat(5) @(posedge i_clk);
        i_rst_n = 1'b0; // 突然复位
        repeat(2) @(posedge i_clk);
        i_rst_n = 1'b1;
        repeat(5) @(posedge i_clk);
        send_one_word(16'shD000); // 检查复位后首个数据是否正常

        $display("[%0t] === All Stress Tests Complete ===", $time);
        #100 $finish;
    end

    // =========================================================================
    // 5. 增强监控 (4级流水线版)
    // =========================================================================
    real in_f, out_f;
    initial begin
        $display("-------------------------------------------------------------------------------------------------------------");
        $display(" Time | In_Vld Rdy | Lane0_In (Float) | V1 V2 V3 V4 | Out_Vld Rdy | Lane0_Out (Float) | Status");
        $display("-------------------------------------------------------------------------------------------------------------");
    end

    always @(posedge i_clk) begin
        if (i_rst_n) begin
            in_f  = $signed(i_data_bus[15:0]) / 4096.0;
            out_f = o_data_bus[15:0] / 32768.0;
            
            if (i_valid || o_valid || uut.vld_stg1 || uut.vld_stg4) begin
                $display("%5t |    %b     %b  |   %h (%6.3f)  | %b  %b  %b  %b |    %b     %b  |    %h (%8.6f) | %s",
                    $time, i_valid, o_ready, i_data_bus[15:0], in_f,
                    uut.vld_stg1, uut.vld_stg2, uut.vld_stg3, uut.vld_stg4,
                    o_valid, i_ready, o_data_bus[15:0], out_f,
                    (!i_ready && o_valid) ? "STALLED" : (i_valid && o_ready ? "ACCEPTED" : "         ")
                );
            end
        end
    end

endmodule