module mul_cell #(
  parameter M = 4,
  parameter N = 4
)(
  input i_clk,
  input i_rstn,
  input i_mul_en,
  input [M+N-1:0] i_mul1,
  input [N-1:0] i_mul2,
  input [M+N-1:0] i_mul1_acc,
  output reg [M+N-1:0] o_mul1_shift,
  output reg [N-1:0] o_mul2_shift,
  output reg [M+N-1:0] o_mul1_acc,
  output reg o_mul_valid
);

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      o_mul1_shift <= 0;
      o_mul2_shift <= 0;
      o_mul1_acc <= 0;
      o_mul_valid <= 0;
    end else if (i_mul_en) begin
      o_mul_valid <= 1'b1;
      o_mul2_shift <= i_mul2 >> 1;
      o_mul1_shift <= i_mul1 << 1;
      if (i_mul2[0]) begin
        // 乘数对应位为1, 累加被乘数
        o_mul1_acc <= i_mul1_acc + i_mul1;
      end else begin
        o_mul1_acc <= i_mul1_acc;
      end
    end else begin
      o_mul_valid <= 1'b0;
      o_mul1_shift <= 0;
      o_mul2_shift <= 0;
      o_mul1_acc <= 0;
    end
  end

endmodule