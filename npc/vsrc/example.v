module example (
    input  a,
    input  b,
    output f
);
  assign f = a ^ b;
  initial begin
    $dumpfile("test.vcd");
  end
endmodule
