module ps2_keyboard (
    clk,
    clrn,
    ps2_clk,
    ps2_data,
    data,
    data1,
    data2,
    ready,
    overflow,
    off
);
  input clk, clrn, ps2_clk, ps2_data;
  output reg [7:0] data, data1, data2;
  output reg ready;
  output reg overflow;  // fifo overflow
  output reg off;  //lignt off
  // internal signal, for test
  reg [9:0] buffer;  // ps2_data bits
  reg [7:0] fifo                     [7:0];  // data fifo
  reg [2:0] w_ptr, r_ptr;  // fifo write and read pointers
  reg [3:0] count;  // count ps2_data bits
  // detect falling edge of ps2_clk
  reg [2:0] ps2_clk_sync;

  always @(posedge clk) begin
    ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
  end

  wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

  always @(posedge clk) begin
    if (clrn == 0) begin  // reset
      count <= 0;
      w_ptr <= 0;
      r_ptr <= 0;
      overflow <= 0;
      ready <= 0;
    end else begin
      if (ready) begin  // read to output next data
        begin
          r_ptr <= r_ptr + 3'b1;
          if (w_ptr == (r_ptr + 1'b1))  //empty
            ready <= 1'b0;
        end

        if (fifo[r_ptr] == 8'hF0) begin
          data2 = data2 + 1;
        end

        data = fifo[r_ptr];

        if (data != 8'hF0) begin
          case (data)
            8'h1C:   data1 = 97;
            8'h32:   data1 = 98;
            8'h21:   data1 = 99;
            8'h23:   data1 = 100;
            8'h24:   data1 = 101;
            8'h2B:   data1 = 102;
            8'h34:   data1 = 103;
            8'h33:   data1 = 104;
            8'h43:   data1 = 105;
            8'h3B:   data1 = 106;
            8'h42:   data1 = 107;
            8'h4B:   data1 = 108;
            8'h3A:   data1 = 109;
            8'h31:   data1 = 110;
            8'h44:   data1 = 111;
            8'h4D:   data1 = 112;
            8'h15:   data1 = 113;
            8'h2D:   data1 = 114;
            8'h1B:   data1 = 115;
            8'h2C:   data1 = 116;
            8'h3C:   data1 = 117;
            8'h2A:   data1 = 118;
            8'h1D:   data1 = 119;
            8'h22:   data1 = 120;
            8'h35:   data1 = 121;
            8'h1A:   data1 = 122;
            default: data1 = 0;
          endcase
        end

        if (fifo[r_ptr-1] == 8'hF0) begin
          off = 1;
        end else begin
          off = 0;
        end
      end
      if (sampling) begin
        if (count == 4'd10) begin
          if ((buffer[0] == 0) &&  // start bit
              (ps2_data) &&  // stop bit
              (^buffer[9:1])) begin  // odd  parity
            fifo[w_ptr] <= buffer[8:1];  // kbd scan code
            w_ptr <= w_ptr + 3'b1;
            ready <= 1'b1;
            overflow <= overflow | (r_ptr == (w_ptr + 3'b1));
          end
          count <= 0;  // for next
        end else begin
          buffer[count] <= ps2_data;  // store ps2_data
          count <= count + 3'b1;
        end
      end
    end
  end

  // assign data = fifo[r_ptr]; //always set output data

endmodule

module Keyboard (
    clk,
    rst,
    hex0,
    hex1,
    hex2,
    hex3,
    hex4,
    hex5,
    ps2_clk,
    ps2_data
);
  input clk, rst, ps2_clk, ps2_data;
  output reg [7:0] hex0, hex1, hex2, hex3, hex4, hex5;

  reg [7:0] data, data1, data2;
  reg ready;
  reg overflow;
  reg off;
  ps2_keyboard key_board (
      clk,
      rst,
      ps2_clk,
      ps2_data,
      data,
      data1,
      data2,
      ready,
      overflow,
      off
  );

  bcd7seg i0 (
      data[3:0],
      hex0
  );
  bcd7seg i1 (
      data[7:4],
      hex1
  );
  bcd7seg i2 (
      data1[3:0],
      hex2
  );
  bcd7seg i3 (
      data1[7:4],
      hex3
  );
  bcd7seg i4 (
      data2[3:0],
      hex4
  );
  bcd7seg i5 (
      data2[7:4],
      hex5
  );
endmodule

