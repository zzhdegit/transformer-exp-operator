`timescale 1ns / 1ps

module exp_sfu_top (
    input  wire         i_clk,
    input  wire         i_rst_n,
    
    // 输入接口 (Valid-Ready 握手)
    input  wire         i_valid,
    output wire         o_ready,
    input  wire [255:0] i_data_bus, // 16路 x 16-bit Q4.12
    
    // 输出接口 (Valid-Ready 握手)
    output wire         o_valid,
    input  wire         i_ready,
    output wire [255:0] o_data_bus  // 16路 x 16-bit UQ1.15
);

    // =========================================================================
    // 1. 内部信号声明 (16路向量化)
    // =========================================================================
    
    // Stage 1 -> 2
    wire [15:0] w_stg1_x   [0:15];
    wire [4:0]  w_stg1_idx [0:15];
    wire        w_stg1_uf  [0:15];
    reg  [15:0] r_stg1_x   [0:15];
    reg  [4:0]  r_stg1_idx [0:15];
    reg         r_stg1_uf  [0:15];

    // Stage 2 -> 3
    wire [15:0] w_stg2_x   [0:15];
    wire [15:0] w_stg2_a   [0:15];
    wire [15:0] w_stg2_b   [0:15];
    wire        w_stg2_uf  [0:15];
    reg  [15:0] r_stg2_x   [0:15];
    reg  [15:0] r_stg2_a   [0:15];
    reg  [15:0] r_stg2_b   [0:15];
    reg         r_stg2_uf  [0:15];

    // Stage 3 -> 4 (乘法输出)
    wire [31:0] w_stg3_mult [0:15];
    wire [15:0] w_stg3_b    [0:15];
    wire        w_stg3_uf   [0:15];

    // =========================================================================
    // 2. 弹性流水线控制逻辑 (Brain)
    // =========================================================================
    
    reg vld_stg1, vld_stg2, vld_stg3, vld_stg4;

    // 反压传导链：从后向前
    wire allow_in_stg4 = !vld_stg4 || i_ready;
    wire allow_in_stg3 = !vld_stg3 || allow_in_stg4;
    wire allow_in_stg2 = !vld_stg2 || allow_in_stg3;
    wire allow_in_stg1 = !vld_stg1 || allow_in_stg2;

    assign o_ready = allow_in_stg1;
    assign o_valid = vld_stg4;

    // 逐级使能信号
    wire ena_stg1 = i_valid  && allow_in_stg1;
    wire ena_stg2 = vld_stg1 && allow_in_stg2;
    wire ena_stg3 = vld_stg2 && allow_in_stg3;
    wire ena_stg4 = vld_stg3 && allow_in_stg4;

    // Valid 状态位移
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            {vld_stg1, vld_stg2, vld_stg3, vld_stg4} <= 4'b0000;
        end else begin
            if (allow_in_stg1) vld_stg1 <= i_valid;
            if (allow_in_stg2) vld_stg2 <= vld_stg1;
            if (allow_in_stg3) vld_stg3 <= vld_stg2;
            if (allow_in_stg4) vld_stg4 <= vld_stg3;
        end
    end

    // =========================================================================
    // 3. 16路并行 Lane 生成
    // =========================================================================
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : LANE
            
            // --- Stage 1: 比较器树 (组合逻辑) ---
            exp_lane_stg1 u_stg1 (
                .x_in           (i_data_bus[i*16 +: 16]),
                .x_out          (w_stg1_x[i]),
                .idx_out         (w_stg1_idx[i]),
                .underflow_flag (w_stg1_uf[i])
            );

            // Reg 1
            always @(posedge i_clk) begin
                if (ena_stg1) begin
                    r_stg1_x[i]   <= w_stg1_x[i];
                    r_stg1_idx[i] <= w_stg1_idx[i];
                    r_stg1_uf[i]  <= w_stg1_uf[i];
                end
            end

            // --- Stage 2: LUT查找 (组合逻辑) ---
            exp_lane_stg2 u_stg2 (
                .x_in               (r_stg1_x[i]),
                .idx_in             (r_stg1_idx[i]),
                .underflow_flag_in  (r_stg1_uf[i]),
                .x_out              (w_stg2_x[i]),
                .a_out              (w_stg2_a[i]),
                .b_out              (w_stg2_b[i]),
                .underflow_flag_out (w_stg2_uf[i])
            );

            // Reg 2
            always @(posedge i_clk) begin
                if (ena_stg2) begin
                    r_stg2_x[i]  <= w_stg2_x[i];
                    r_stg2_a[i]  <= w_stg2_a[i];
                    r_stg2_b[i]  <= w_stg2_b[i];
                    r_stg2_uf[i] <= w_stg2_uf[i];
                end
            end

            // --- Stage 3: 高速乘法 (时序逻辑，内部带Reg以利用DSP48 MREG) ---
            exp_lane_stg3 u_stg3 (
                .i_clk      (i_clk),
                .i_ena      (ena_stg3),
                .x_in       (r_stg2_x[i]),
                .a_in       (r_stg2_a[i]),
                .b_in       (r_stg2_b[i]),
                .uf_in      (r_stg2_uf[i]),
                .mult_res   (w_stg3_mult[i]), // 这一级输出已经是寄存器打过的了
                .b_pipe     (w_stg3_b[i]),
                .uf_pipe    (w_stg3_uf[i])
            );

            // --- Stage 4: 累加与饱和 (时序逻辑，内部带Reg以利用DSP48 PREG) ---
            exp_lane_stg4 u_stg4 (
                .i_clk      (i_clk),
                .i_ena      (ena_stg4),
                .mult_res   (w_stg3_mult[i]),
                .b_in       (w_stg3_b[i]),
                .uf_in      (w_stg3_uf[i]),
                .y_out      (o_data_bus[i*16 +: 16]) // 最终结果输出
            );

        end
    endgenerate

endmodule