// 参数化偶分频，50% 占空比。N 必须为偶数且 >= 2。
// 原理：每 N/2 个上升沿翻转一次。N=2/4 时分别退化为 div2 / div4。
module div_even #(
  parameter integer N = 4
)(
  input i_clk,
  input i_rstn,
  output reg o_clkout
);

  localparam integer HALF  = N / 2;
  localparam integer CNT_W = (HALF <= 1) ? 1 : $clog2(HALF);

  reg [CNT_W-1:0] cnt;

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      cnt <= {CNT_W{1'b0}};
      o_clkout <= 1'b0;
    end else if (cnt == CNT_W'(HALF - 1)) begin
      cnt <= {CNT_W{1'b0}};
      o_clkout <= ~o_clkout;
    end else begin
      cnt <= cnt + 1'b1;
    end
  end

endmodule
