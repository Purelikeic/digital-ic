// Round-Robin 仲裁器
/*
  RR 维护 last_grant, 每次从上次 winner 的下一路开始查找. 只有真正握手成功时才更新指针.
  `fire = valid && ready;`
*/

module rr_arb #(
  parameter N = 4,
  parameter PTR_W = 2
)(
  input clk,
  input rstn,
  input [N-1:0] req,
  input ready,
  output valid,
  output reg [N-1:0] grant,
  output reg [PTR_W-1:0] chosen
);

  reg [PTR_W-1:0] last_grant;
  reg found;

  integer offset;
  integer index;

  assign valid = |req;

  always @(*) begin
    grant = {N{1'b0}};
    chosen = {PTR_W{1'b0}};
    found = 1'b0;

    // 从 last_grant + 1 开始, 循环扫描 N 路
    for (offset = 1; offset <= N; offset = offset + 1) begin
      index = last_grant + offset;

      // index 最大为 2*N-1, 因此最多减一次 N 即可回到
      if (index >= N) begin
        index = index - N;
      end

      if (req[index] && !found) begin
        grant[index] = 1'b1;
        chosen = index;
        found = 1'b1;
      end
    end
  end

  // 仅在完成一次传输时移动 RR 指针
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      last_grant <= N - 1; // 复位后第一次从 0 开始选择
    end else if (valid && ready) begin
      last_grant <= chosen;
    end
  end

endmodule
