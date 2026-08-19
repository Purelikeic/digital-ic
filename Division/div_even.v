// 参数化偶分频，50% 占空比。N 必须为偶数且 >= 2。
// 原理：每 N/2 个上升沿翻转一次。N=2/4 时分别退化为 div2 / div4。
module div_even #(
  parameter integer N = 4
)(
  input i_clk,
  input i_rstn,
  output o_clkout
);

  localparam integer HALF  = N / 2;
  localparam integer CNT_W = (HALF <= 1) ? 1 : $clog2(HALF);
  localparam integer HALF_LAST_INT = HALF - 1;
  localparam [CNT_W-1:0] HALF_LAST = HALF_LAST_INT[CNT_W-1:0];

  reg [CNT_W-1:0] cnt;
  reg clk_out;

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      cnt <= 0;
    end else if (cnt == HALF_LAST) begin
      cnt <= 0;
    end else begin
      cnt <= cnt + 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      clk_out <= 1'b0;
    end else if (cnt == HALF_LAST) begin
      clk_out <= ~clk_out;
    end
  end

  assign o_clkout = clk_out;

endmodule
