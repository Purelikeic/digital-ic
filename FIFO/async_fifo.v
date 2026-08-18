// 异步 FIFO
module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DATA_DEPTH = 128
)(
  input i_wr_clk,
  input i_wr_rstn,
  input i_wr_en,
  input [DATA_WIDTH-1:0] i_wr_data,
  output o_full,

  input i_rd_clk,
  input i_rd_rstn,
  input i_rd_en,
  output [DATA_WIDTH-1:0] o_rd_data,
  output o_empty
);

  localparam ADDR_W = $clog2(DATA_DEPTH); // DATA_DEPTH 必须为 2 的幂

  reg [ADDR_W:0] wr_ptr_bin;
  reg [ADDR_W:0] rd_ptr_bin;
  reg [ADDR_W:0] wr_ptr_gray;
  reg [ADDR_W:0] rd_ptr_gray;
  reg [ADDR_W:0] wr_ptr_gray_d1, wr_ptr_gray_d2;
  reg [ADDR_W:0] rd_ptr_gray_d1, rd_ptr_gray_d2;

  reg [DATA_DEPTH-1:0] ram [0:DATA_DEPTH-1];
  reg [DATA_WIDTH-1:0] rd_data_reg;

  wire [ADDR_W:0] wr_ptr_bin_next = wr_ptr_bin + 1'b1;
  wire [ADDR_W:0] rd_ptr_bin_next = rd_ptr_bin + 1'b1;

  wire [ADDR_W:0] wr_ptr_bin_sync;
  wire [ADDR_W:0] rd_ptr_bin_sync;

  wire [ADDR_W-1:0] wr_addr = wr_ptr_bin[ADDR_W-1:0];
  wire [ADDR_W-1:0] rd_addr = rd_ptr_bin[ADDR_W-1:0];

  wire wr_fire = i_wr_en && !o_full;
  wire rd_fire = i_rd_en && !o_empty;

  function [ADDR_W:0] bin2gray;
    input [ADDR_W:0] bin;
    begin
      bin2gray = (bin >> 1) ^ bin;
    end
  endfunction

  function [ADDR_W:0] gray2bin;
    input [ADDR_W:0] gray;
    integer i;
    begin
      gray2bin[ADDR_W] = gray[ADDR_W];
      for (i = ADDR_W - 1; i >= 0; i = i - 1) begin
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
      end
    end
  endfunction

  assign wr_ptr_bin_sync = gray2bin(wr_ptr_gray_d2);
  assign rd_ptr_bin_sync = gray2bin(rd_ptr_gray_d2);

  // 读域判空, 写域判满 (用同步后的对方指针)
  assign o_empty = (rd_ptr_bin == wr_ptr_bin_sync);
  assign o_full = (wr_ptr_bin[ADDR_W] != rd_ptr_bin_sync[ADDR_W]) && (wr_addr == rd_addr);

  // 写域: 二进制加减, 送出格雷码
  always @(posedge i_wr_clk or negedge i_wr_rstn) begin
    if (!i_wr_rstn) begin
      wr_ptr_bin <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_fire) begin
      wr_ptr_bin <= wr_ptr_bin_next;
      wr_ptr_gray <= bin2gray(wr_ptr_bin_next);
    end
  end

  always @(posedge i_wr_clk) begin
    if (wr_fire) begin
      ram[wr_addr] <= i_wr_data;
    end
  end

  // 读指针格雷码打进写域, 两拍
  always @(posedge i_wr_clk or negedge i_wr_rstn) begin
    if (!i_wr_rstn) begin
      rd_ptr_gray_d1 <= 0;
      rd_ptr_gray_d2 <= 0;
    end else begin
      rd_ptr_gray_d1 <= rd_ptr_gray;
      rd_ptr_gray_d2 <= rd_ptr_gray_d1;
    end
  end

  // 读域: 二进制加减, 送出格雷码
  always @(posedge i_rd_clk or negedge i_rd_rstn) begin
    if (!i_rd_rstn) begin
      rd_ptr_bin <= 0;
      rd_ptr_gray <= 0;
    end else if (rd_fire) begin
      rd_ptr_bin <= rd_ptr_bin_next;
      rd_ptr_gray <= bin2gray(rd_ptr_bin_next);
    end
  end

  always @(posedge i_rd_clk or negedge i_rd_rstn) begin
    if (!i_rd_rstn) begin
      rd_data_reg <= 0;
    end else if (rd_fire) begin
      rd_data_reg <= ram[rd_addr];
    end
  end

  assign o_rd_data = rd_data_reg;

  // 写指针格雷码打两拍进读域
  always @(posedge i_rd_clk or negedge i_rd_rstn) begin
    if (!i_rd_rstn) begin
      wr_ptr_gray_d1 <= 0;
      wr_ptr_gray_d2 <= 0;
    end else begin
      wr_ptr_gray_d1 <= wr_ptr_gray;
      wr_ptr_gray_d2 <= wr_ptr_gray_d1;
    end
  end

endmodule
