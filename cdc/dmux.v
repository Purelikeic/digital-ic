// dmux 原理
// 1. 使用 dmux 必须满足启动传输的数据保持时间大于等于至少三个接收时钟周期
// 2. 必须是快时钟到慢时钟
// 3. i_valid 与 i_data 必须同拍给出(电平), 并共同保持至少 3 个接收时钟周期
module dmux(
  input i_clk_fast,
  input i_rstn_fast,
  input i_clk_slow,
  input i_rstn_slow,
  input i_valid,
  input [7:0] i_data,
  output [7:0] o_data,
  output o_valid
);

  // 快时钟域: 锁存数据并寄存 valid, 两者保持对齐
  reg [7:0] data_reg;
  reg valid_reg;

  always @(posedge i_clk_fast or negedge i_rstn_fast) begin
    if (!i_rstn_fast) begin
      data_reg <= 0;
      valid_reg <= 0;
    end else begin
      valid_reg <= i_valid;
      if (i_valid) begin
        data_reg <= i_data;
      end
    end
  end

  // 慢时钟域: valid 两级同步 + 一拍做上升沿检测
  reg valid_d1, valid_d2, valid_d3;

  always @(posedge i_clk_slow or negedge i_rstn_slow) begin
    if (!i_rstn_slow) begin
      valid_d1 <= 0;
      valid_d2 <= 0;
      valid_d3 <= 0;
    end else begin
      valid_d1 <= valid_reg;
      valid_d2 <= valid_d1;
      valid_d3 <= valid_d2;
    end
  end

  reg [7:0] o_data_reg;
  reg o_valid_reg;

  // valid_d2 上升沿采样数据, o_valid 与 o_data 同拍输出
  always @(posedge i_clk_slow or negedge i_rstn_slow) begin
    if (!i_rstn_slow) begin
      o_data_reg  <= 0;
      o_valid_reg <= 0;
    end else if (valid_d2 && !valid_d3) begin
      o_data_reg  <= data_reg;
      o_valid_reg <= 1'b1;
    end else begin
      o_valid_reg <= 1'b0;
    end
  end

  assign o_data  = o_data_reg;
  assign o_valid = o_valid_reg;

endmodule
