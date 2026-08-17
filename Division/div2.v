// 二分频电路
module div2(
  input i_clk,
  input i_rstn,
  output reg o_clk
);

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      o_clk <= 1'b0;
    end else begin
      o_clk <= ~o_clk;
    end
  end

endmodule
