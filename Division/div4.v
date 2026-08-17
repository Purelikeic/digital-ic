module div4(
  input i_clk,
  input i_rstn,
  output reg o_clkout
);

  reg [1:0] cnt;

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      cnt <= 2'b00;
    end else begin
      cnt <= cnt + 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      o_clkout <= 1'b0;
    end else if (cnt == 2'b01 || cnt == 2'b11) begin
      o_clkout <= ~o_clkout;
    end
  end
endmodule
