module mul #(
  parameter M = 4,
  parameter N = 4
)(
  input i_clk,
  input i_rstn,
  input i_mul_en,
  input [M-1:0] i_mul1, // 被乘数
  input [N-1:0] i_mul2, // 乘数
  output o_mul_valid,
  output [M+N-1:0] o_mul_res
);

  // 移多少位
  reg [$clog2(N):0] shift_count;
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      shift_count <= 0;
    end else if (i_mul_en && shift_count == 0) begin
      shift_count <= shift_count + 1'b1;
    end else if (shift_count != 0) begin
      shift_count <= (shift_count == N) ? 0 : shift_count + 1'b1;
    end else begin
      shift_count <= 0;
    end
  end

  // 乘法
  reg [N-1:0] mul2_shift; // 右移乘数
  reg [M+N-1:0] mul1_shift; // 左移被乘数
  reg [M+N-1:0] mul1_acc;
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      mul2_shift <= 0;
      mul1_shift <= 0;
      mul1_acc <= 0;
    end else if (i_mul_en && shift_count == 0) begin // 初始化
      // 将mul1位宽由M位补充到M+N位,并将mul1乘以2得到mul1_shift
      // 将mul2除以2得到mul2_shift
      mul1_shift <= {{N{1'b0}}, i_mul1} << 1;
      mul2_shift <= i_mul2 >> 1;
      // 末尾为1, 则相当于1乘mul1=mul1
      // 末尾为0, 则相当于0乘mul1=0
      mul1_acc <= i_mul2[0] ? {{N{1'b0}}, i_mul1} : 0;
    end else if (shift_count != 0 && shift_count != N) begin
      mul1_shift <= mul1_shift << 1; // 被乘数乘以2
      mul2_shift <= mul2_shift >> 1; // 乘数右移
      // 判断乘数对应位是否为1, 为1则累加
      mul1_acc <= mul2_shift[0] ? mul1_acc + mul1_shift : mul1_acc;
    end else begin
      mul2_shift <= 0;
      mul1_shift <= 0;
      mul1_acc <= 0;
    end
  end

  // 结果
  reg [M+N-1:0] mul_res_r;
  reg mul_valid_r;
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      mul_res_r <= 0;
      mul_valid_r <= 0;
    end else if (shift_count == N) begin
      mul_res_r <= mul1_acc;
      mul_valid_r <= 1'b1;
    end else begin
      mul_res_r <= 0;
      mul_valid_r <= 1'b0;
    end
  end

  assign o_mul_res = mul_res_r;
  assign o_mul_valid = mul_valid_r;

endmodule
