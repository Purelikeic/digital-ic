// 固定优先级的仲裁器
/*
  req[0] 优先级最高, req[0] 和 req[3] 同时请求时, 必定选择 req[0].
  比如 req = 4'b1110, 则 grant = 4'b0010
*/
module fparb #(
  parameter int N = 4
)(
  input [N-1:0] req,
  output [N-1:0] grant
);

  integer i;
  reg found;

  always @(*) begin
    grant = {N{1'b0}};
    found = 1'b0;

    // 从低编号向高编号扫描, 先遇到的有效请求胜出
    for (i = 0; i < N; i = i + 1) begin
      if (req[i] && !found) begin
        grant[i] = 1'b1;
        found = 1'b1;
      end
    end
  end
endmodule
