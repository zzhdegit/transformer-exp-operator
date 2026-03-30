module exp_lane_stg3 (
    input  wire        i_clk,
    input  wire        i_ena,   // 必须接入顶层的 ena_stg3
    input  wire signed [15:0] x_in,
    input  wire signed [15:0] a_in,
    input  wire signed [15:0] b_in,
    input  wire        uf_in,
    
    output reg  signed [31:0] mult_res,
    output reg  signed [15:0] b_pipe,
    output reg                uf_pipe
);

    (* use_dsp = "yes" *)
    always @(posedge i_clk) begin
        if (i_ena) begin // 只有当前级允许输入且有数时，才更新寄存器
            mult_res <= a_in * x_in;
            b_pipe   <= b_in;
            uf_pipe  <= uf_in;
        end
    end
endmodule