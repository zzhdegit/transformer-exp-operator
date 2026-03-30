`timescale 1ns / 1ps

module exp_top (
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
    // 1. 数据链路线网声明
    // =========================================================================
    wire [15:0] w_stg1_x   [0:15];
    wire [4:0]  w_stg1_idx [0:15];
    wire        w_stg1_uf  [0:15];
    reg  [15:0] r_stg1_x   [0:15];
    reg  [4:0]  r_stg1_idx [0:15];
    reg         r_stg1_uf  [0:15];

    wire [15:0] w_stg2_x   [0:15];
    wire [15:0] w_stg2_a   [0:15];
    wire [15:0] w_stg2_b   [0:15];
    wire        w_stg2_uf  [0:15];
    reg  [15:0] r_stg2_x   [0:15];
    reg  [15:0] r_stg2_a   [0:15];
    reg  [15:0] r_stg2_b   [0:15];
    reg         r_stg2_uf  [0:15];

    wire [15:0] w_stg3_a_reg [0:15];
    wire [15:0] w_stg3_x_reg [0:15];
    wire [32:0] w_stg3_b_ext [0:15];
    wire        w_stg3_uf    [0:15];

    wire [32:0] w_stg5_sum   [0:15];
    wire        w_stg5_uf    [0:15];

    wire        w_stg6_f0000 [0:15];
    wire        w_stg6_f8000 [0:15];
    wire [15:0] w_stg6_norm  [0:15];

    // =========================================================================
    // 2. 全局握手信号提取 (利用 Lane 0 的状态代表全局)
    // =========================================================================
    assign o_ready = LANE[0].allow_in_stg1;
    assign o_valid = LANE[0].vld_stg7;

    // =========================================================================
    // 3. 16 路并行 Lane 实例化 (分布式控制状态机)
    // =========================================================================
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : LANE
            
            // -----------------------------------------------------------------
            // 7 级流水线局部控制流 (分布到每个 Lane 内部)
            // -----------------------------------------------------------------
            // 在这里施加 max_fanout，让工具在单个 Lane 内部如果遇到高扇出也能继续复制
            (* max_fanout = "16" *) reg vld_stg1, vld_stg2, vld_stg3, vld_stg4, vld_stg5, vld_stg6, vld_stg7;
            
            wire allow_in_stg7 = !vld_stg7 || i_ready;
            wire allow_in_stg6 = !vld_stg6 || allow_in_stg7;
            wire allow_in_stg5 = !vld_stg5 || allow_in_stg6;
            wire allow_in_stg4 = !vld_stg4 || allow_in_stg5;
            wire allow_in_stg3 = !vld_stg3 || allow_in_stg4;
            wire allow_in_stg2 = !vld_stg2 || allow_in_stg3;
            wire allow_in_stg1 = !vld_stg1 || allow_in_stg2;

            wire ena_stg1 = i_valid  && allow_in_stg1;
            wire ena_stg2 = vld_stg1 && allow_in_stg2;
            wire ena_stg3 = vld_stg2 && allow_in_stg3;
            wire ena_stg4 = vld_stg3 && allow_in_stg4;
            wire ena_stg5 = vld_stg4 && allow_in_stg5;
            wire ena_stg6 = vld_stg5 && allow_in_stg6;
            wire ena_stg7 = vld_stg6 && allow_in_stg7;

            always @(posedge i_clk or negedge i_rst_n) begin
                if (!i_rst_n) begin
                    {vld_stg1, vld_stg2, vld_stg3, vld_stg4, vld_stg5, vld_stg6, vld_stg7} <= 7'b0;
                end else begin
                    if (allow_in_stg1) vld_stg1 <= i_valid;
                    if (allow_in_stg2) vld_stg2 <= vld_stg1;
                    if (allow_in_stg3) vld_stg3 <= vld_stg2;
                    if (allow_in_stg4) vld_stg4 <= vld_stg3;
                    if (allow_in_stg5) vld_stg5 <= vld_stg4;
                    if (allow_in_stg6) vld_stg6 <= vld_stg5;
                    if (allow_in_stg7) vld_stg7 <= vld_stg6;
                end
            end

            // -----------------------------------------------------------------
            // 物理级联
            // -----------------------------------------------------------------
            exp_lane_stg1 u_stg1 (
                .x_in           (i_data_bus[i*16 +: 16]),
                .x_out          (w_stg1_x[i]),
                .idx_out        (w_stg1_idx[i]),
                .underflow_flag (w_stg1_uf[i])
            );
            
            always @(posedge i_clk) begin
                if (ena_stg1) begin
                    r_stg1_x[i]   <= w_stg1_x[i];
                    r_stg1_idx[i] <= w_stg1_idx[i];
                    r_stg1_uf[i]  <= w_stg1_uf[i];
                end
            end

            exp_lane_stg2 u_stg2 (
                .x_in               (r_stg1_x[i]),
                .idx_in             (r_stg1_idx[i]),
                .underflow_flag_in  (r_stg1_uf[i]),
                .x_out              (w_stg2_x[i]),
                .a_out              (w_stg2_a[i]),
                .b_out              (w_stg2_b[i]),
                .underflow_flag_out (w_stg2_uf[i])
            );
            
            always @(posedge i_clk) begin
                if (ena_stg2) begin
                    r_stg2_x[i]  <= w_stg2_x[i];
                    r_stg2_a[i]  <= w_stg2_a[i];
                    r_stg2_b[i]  <= w_stg2_b[i];
                    r_stg2_uf[i] <= w_stg2_uf[i];
                end
            end

            exp_lane_stg3 u_stg3 (
                .i_clk       (i_clk),
                .i_ena       (ena_stg3),
                .x_in        (r_stg2_x[i]),
                .a_in        (r_stg2_a[i]),
                .b_in        (r_stg2_b[i]),
                .uf_in       (r_stg2_uf[i]),
                
                .a_reg       (w_stg3_a_reg[i]),
                .x_reg       (w_stg3_x_reg[i]),
                .b_ext_reg   (w_stg3_b_ext[i]),
                .uf_pipe     (w_stg3_uf[i])
            );

            exp_lane_stg4_5 u_stg4_5 (
                .i_clk       (i_clk),
                .i_ena_m1    (ena_stg4),  
                .i_ena_m2    (ena_stg5),  
                .a_reg       (w_stg3_a_reg[i]),
                .x_reg       (w_stg3_x_reg[i]),
                .b_ext_reg   (w_stg3_b_ext[i]),
                .uf_in       (w_stg3_uf[i]),
                
                .sum_out     (w_stg5_sum[i]),
                .uf_out      (w_stg5_uf[i])
            );

            exp_lane_stg6 u_stg6 (
                .i_clk       (i_clk),
                .i_ena       (ena_stg6),
                .sum_in      (w_stg5_sum[i]),
                .uf_in       (w_stg5_uf[i]),
                
                .force_0000  (w_stg6_f0000[i]),
                .force_8000  (w_stg6_f8000[i]),
                .normal_val  (w_stg6_norm[i])
            );

            exp_lane_stg7 u_stg7 (
                .i_clk       (i_clk),
                .i_ena       (ena_stg7),
                .force_0000  (w_stg6_f0000[i]),
                .force_8000  (w_stg6_f8000[i]),
                .normal_val  (w_stg6_norm[i]),
                
                .y_out       (o_data_bus[i*16 +: 16]) 
            );

        end
    endgenerate

endmodule