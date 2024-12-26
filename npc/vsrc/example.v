module example (
    input  a,
    input  b,
    output f
);
  assign f = a ^ b;
  $dumpfile("out.vcd");
endmodule
