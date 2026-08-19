// 新思笔试题: 设计一个流水线乘法器代码
/*
  将被乘数和乘数进行相乘之后可以得到结果, 每个周期将被乘数左移乘2, 将乘数右移除2
  如果是 1101(13) * 101(5), 101 的低位为1,此时结果是 1101, 未移位, 累加得到 1101
  101 右移之后得到 10 的低位为0, 此时1101左移得到11010, 不累加
  10右移之后得到1的低位为1, 此时11010左移得到110100,累加得到110100+1101

  思路: 移位加法
*/

module pipe_mul #(
  parameter M = 4,
  parameter N = 4
)(
  input i_clk,
  input i_rstn,
  input i_mul_en,
  input [M-1:0] i_mul1,
  input [N-1:0] i_mul2,
  output o_mul_valid,
  output [M+N-1:0] o_mul_res
);

  wire [M+N-1:0] w_mul1_shift [N-1:0]; // 左移被乘数
  wire [N-1:0] w_mul2_shift [N-1:0];   // 右移乘数
  wire [M+N-1:0] w_mul1_acc [N-1:0];   // 累加值
  wire w_mul_valid [N-1:0];

  // 第一次实例化相当于初始化, 不能用 generate 语句
  mul_cell #(.M(M), .N(N)) u_mul_step0 (
    .i_clk        (i_clk),
    .i_rstn       (i_rstn),
    .i_mul_en     (i_mul_en),
    .i_mul1       ({{(N){1'b0}}, i_mul1}),
    .i_mul2       (i_mul2),
    .i_mul1_acc   ({(M+N){1'b0}}),
    .o_mul1_shift (w_mul1_shift[0]),
    .o_mul2_shift (w_mul2_shift[0]),
    .o_mul1_acc   (w_mul1_acc[0]),
    .o_mul_valid  (w_mul_valid[0])
  );

  // 多次实例化, 用 generate 语句
  genvar i;
  generate
    for (i = 1; i <= N - 1; i = i + 1) begin: mul_stepx
      mul_cell #(.M(M), .N(N)) u_mul_step (
        .i_clk        (i_clk),
        .i_rstn       (i_rstn),
        .i_mul_en     (w_mul_valid[i-1]),
        .i_mul1       (w_mul1_shift[i-1]),
        .i_mul2       (w_mul2_shift[i-1]),
        .i_mul1_acc   (w_mul1_acc[i-1]),
        .o_mul1_shift (w_mul1_shift[i]),
        .o_mul2_shift (w_mul2_shift[i]),
        .o_mul1_acc   (w_mul1_acc[i]),
        .o_mul_valid  (w_mul_valid[i])
      );
    end
  endgenerate

  assign o_mul_valid = w_mul_valid[N-1];
  assign o_mul_res = w_mul1_acc[N-1];

endmodule
