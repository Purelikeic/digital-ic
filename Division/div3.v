// 三分频电路实现
module div3(
  input i_clk,
  input i_rstn,
  output o_clkout
);

  reg [1:0] cnt;
  reg clk_p, clk_n;

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      cnt <= 2'b00;
    end else begin
      cnt <= (cnt == 2'b10) ? 2'b00 : cnt + 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      clk_p <= 1'b0;
    end else if (cnt == 2'b10 || cnt == 2'b01) begin
      clk_p <= ~clk_p;
    end
  end

  always @(negedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      clk_n <= 1'b0;
    end else if (cnt == 2'b10 || cnt == 2'b01) begin
      clk_n <= ~clk_n;
    end
  end

  assign o_clkout = clk_p | clk_n;
endmodule
