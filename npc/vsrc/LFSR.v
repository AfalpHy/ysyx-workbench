module ysyx_25010008_LFSR (
    input clk,
    input rst,
    output reg [7:0] dout
);

  always @(posedge clk) begin
    if (rst) dout <= 1;
    else dout <= {dout[4] ^ dout[3] ^ dout[2] ^ dout[0], dout[7:1]};
  end

endmodule
