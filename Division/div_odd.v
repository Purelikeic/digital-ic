// 参数化奇分频，50% 占空比。N 必须为奇数且 >= 3。
// 原理：把 div3 的双沿翻转推广到任意奇数。
//   正沿生成占空比 (N-1)/(2N) 的时钟，负沿再错开半拍，或起来后高低各 N/2 拍。
module div_odd #(
  parameter integer N = 3
)(
  input i_clk,
  input i_rstn,
  output o_clkout
);

  localparam integer CNT_W = $clog2(N);
  localparam integer MID   = (N - 1) / 2;
  localparam integer LAST  = N - 1;

  reg [CNT_W-1:0] cnt;
  reg clk_p;
  reg clk_n;

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      cnt <= {CNT_W{1'b0}};
    end else begin
      cnt <= (cnt == CNT_W'(LAST)) ? {CNT_W{1'b0}} : cnt + 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      clk_p <= 1'b0;
    end else if (cnt == CNT_W'(MID) || cnt == CNT_W'(LAST)) begin
      clk_p <= ~clk_p;
    end
  end

  always @(negedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      clk_n <= 1'b0;
    end else if (cnt == CNT_W'(MID) || cnt == CNT_W'(LAST)) begin
      clk_n <= ~clk_n;
    end
  end

  assign o_clkout = clk_p | clk_n;

endmodule
