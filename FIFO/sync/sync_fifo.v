// 同步 FIFO，DATA_DEPTH 必须是 2 的幂
module sync_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DATA_DEPTH = 128
)(
  input wire i_clk,
  input wire i_rstn,
  input wire i_wr_en,
  input wire i_rd_en,
  input wire [DATA_WIDTH-1:0] i_wr_data,

  output reg [DATA_WIDTH-1:0] o_rd_data,
  output wire o_full,
  output wire o_empty
);

  reg [$clog2(DATA_DEPTH):0] fifo_cnt;
  reg [$clog2(DATA_DEPTH)-1:0] rd_ptr;
  reg [$clog2(DATA_DEPTH)-1:0] wr_ptr;

  reg [DATA_WIDTH-1:0] fifo_mem [0:DATA_DEPTH-1];

  // 实际生效的写操作和读操作
  wire write_enable;
  wire read_enable;

  // 计数器最高位为 1 时，FIFO 中的数据数量等于 DATA_DEPTH
  assign o_full  = fifo_cnt[$clog2(DATA_DEPTH)];
  assign o_empty = (fifo_cnt == 0);

  // FIFO 满时禁止写入，FIFO 空时禁止读取
  assign write_enable = i_wr_en && !o_full;
  assign read_enable  = i_rd_en && !o_empty;

  // 写数据并更新写指针
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      wr_ptr <= 0;
    end else if (write_enable) begin
      fifo_mem[wr_ptr] <= i_wr_data;
      wr_ptr <= wr_ptr + 1;
    end
  end

  // 读数据并更新读指针
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      rd_ptr   <= 0;
      o_rd_data <= 0;
    end else if (read_enable) begin
      o_rd_data <= fifo_mem[rd_ptr];
      rd_ptr <= rd_ptr + 1;
    end
  end

  // FIFO 数据计数器
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      fifo_cnt <= 0;
    end else begin
      case ({write_enable, read_enable})
        2'b10: fifo_cnt <= fifo_cnt + 1'b1;
        2'b01: fifo_cnt <= fifo_cnt - 1'b1;
        default: fifo_cnt <= fifo_cnt;
      endcase
    end
  end

endmodule
