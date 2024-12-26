module example (
    input  a,
    input  b,
    output f
);
  assign f = a ^ b;
  initial begin
    #10 $finish();
  $dumpfile("out.vcd");
  end
endmodule
