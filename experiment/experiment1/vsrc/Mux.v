module Mux (
    input [1:0] X0,
    input [1:0] X1,
    input [1:0] X2,
    input [1:0] X3,
    input [1:0] Y,
    output reg [1:0] F
);

  assign F = Y[1] ? (Y[0] ? X3 : X2) : (Y[0] ? X1 : X0);

endmodule
