// 同步 FIFO
module sync_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DATA_DEPTH = 128
)(
  input i_clk,
  input i_rstn,
  input i_wr_en,
  input i_rd_en,
  input [DATA_WIDTH-1:0] i_wr_data,
  output [DATA_WIDTH-1:0] o_rd_data,
  output o_full,
  output o_empty
);

  localparam ADDR_W = $clog2(DATA_DEPTH); // DATA_DEPTH 必须为 2 的幂

  reg [ADDR_W:0] wr_ptr;
  reg [ADDR_W:0] rd_ptr;
  reg [DATA_WIDTH-1:0] ram [0:DATA_DEPTH-1];

  reg [DATA_WIDTH-1:0] rd_data_reg;

  wire [ADDR_W-1:0] wr_addr = wr_ptr[ADDR_W-1:0];
  wire [ADDR_W-1:0] rd_addr = rd_ptr[ADDR_W-1:0];

  wire wr_fire = i_wr_en && !o_full;
  wire rd_fire = i_rd_en && !o_empty;

  // 全等 -> 空; 低位相等, 绕圈位不同 -> 满
  assign o_empty = (wr_ptr == rd_ptr);
  assign o_full = (wr_ptr[ADDR_W] != rd_ptr[ADDR_W]) && (wr_addr == rd_addr);

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      wr_ptr <= 0;
    end else if (wr_fire) begin
      wr_ptr <= wr_ptr + 1'b1;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      rd_ptr <= 0;
    end else if (rd_fire) begin
      rd_ptr <= rd_ptr + 1'b1;
    end
  end

  always @(posedge i_clk) begin
    if (wr_fire) begin
      ram[wr_addr] <= i_wr_data;
    end
  end

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      rd_data_reg <= 0;
    end else if (rd_fire) begin
      rd_data_reg <= ram[rd_addr];
    end
  end

  assign o_rd_data = rd_data_reg;

endmodule
