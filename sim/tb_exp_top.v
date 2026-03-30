`timescale 1ns / 1ps

module tb_exp_top();

    // 1. 参数与时钟定义
    parameter CLK_PERIOD = 2.857; // 350MHz (1/350MHz ≈ 2.857ns)
    reg i_clk;
    reg i_rst_n;

    // 接口信号
    reg          i_valid;
    wire         o_ready;
    reg  [255:0] i_data_bus;
    wire         o_valid;
    reg          i_ready;
    wire [255:0] o_data_bus;

    // 性能统计与校验信号
    integer sent_count = 0;
    integer recv_count = 0;
    reg [255:0] data_queue [0:1023]; // 模拟简单的 FIFO 存储发送数据
    integer head = 0, tail = 0;

    // 2. 实例化 DUT (Latest Top) [cite: 327, 362]
    exp_top dut (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_valid    (i_valid),
        .o_ready    (o_ready),
        .i_data_bus (i_data_bus),
        .o_valid    (o_valid),
        .i_ready    (i_ready),
        .o_data_bus (o_data_bus)
    );

    // 3. 时钟生成 (350MHz)
    initial i_clk = 0;
    always #(CLK_PERIOD/2.0) i_clk = ~i_clk;

    // 4. 发送端驱动逻辑 (压力测试的核心)
    initial begin
        // 初始化
        i_rst_n = 0;
        i_valid = 0;
        i_data_bus = 0;
        #(CLK_PERIOD * 10);
        i_rst_n = 1;
        #(CLK_PERIOD * 5);

        // --- 场景 A: 全速 Burst 写入 ---
        repeat(100) begin
            wait(o_ready);
            @(posedge i_clk);
            i_valid <= 1;
            // 填充 16 路不同的数据
            for(integer j=0; j<16; j=j+1) 
                i_data_bus[j*16 +: 16] <= $random;
            data_queue[tail] <= i_data_bus; 
            tail <= (tail + 1) % 1024;
            sent_count <= sent_count + 1;
        end

        // --- 场景 B: 极随机输入压力测试 ---
        repeat(500) begin
            @(posedge i_clk);
            i_valid <= ($random % 100) < 40; // 40% 的概率随机给输入
            if (i_valid && o_ready) begin
                for(integer j=0; j<16; j=j+1) 
                    i_data_bus[j*16 +: 16] <= $random;
                data_queue[tail] <= i_data_bus;
                tail <= (tail + 1) % 1024;
                sent_count <= sent_count + 1;
            end
        end

        // 等待数据全部排空
        wait(sent_count == recv_count);
        $display("Stress Test Passed! Total Packets: %d", recv_count);
        $finish;
    end

    // 5. 接收端驱动逻辑 (模拟下游随机反压)
    initial begin
        i_ready = 0;
        wait(i_rst_n);
        forever begin
            @(posedge i_clk);
            // 场景 C: 极具挑战性的随机反压 (50% 概率突然拉低 i_ready)
            // 这会测试你的 allow_in 传导链是否能瞬间锁住 7 级流水线 [cite: 331]
            i_ready <= ($random % 100) < 50; 
        end
    end

    // 6. 自动监控与丢数检查
    always @(posedge i_clk) begin
        if (o_valid && i_ready) begin
            recv_count <= recv_count + 1;
            // 如果你有特定的精度模型，可以在此处加入 $sqrt/$exp 算术比较
        end
    end

    // 7. 超时监控 (防止状态机死锁)
    initial begin
        #(CLK_PERIOD * 20000);
        $display("Testbench Timeout! Possible Deadlock in Handshake Logic.");
        $finish;
    end

endmodule