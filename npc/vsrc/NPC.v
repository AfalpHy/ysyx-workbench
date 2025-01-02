module NPC (
    input  clk,
    input  reset
);

    reg c;
    always @(clk) begin
        c = ~clk;
    end
endmodule
