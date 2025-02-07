// // define this macro to enable fast behavior simulation
// // for flash by skipping SPI transfers
// //`define FAST_FLASH

// module spi_top_apb #(
//     parameter flash_addr_start = 32'h30000000,
//     parameter flash_addr_end   = 32'h3fffffff,
//     parameter spi_ss_num       = 8
// ) (
//     input             clock,
//     input             reset,
//     input      [31:0] in_paddr,
//     input             in_psel,
//     input             in_penable,
//     input      [ 2:0] in_pprot,
//     input             in_pwrite,
//     input      [31:0] in_pwdata,
//     input      [ 3:0] in_pstrb,
//     output reg        in_pready,
//     output reg [31:0] in_prdata,
//     output            in_pslverr,

//     output                  spi_sck,
//     output [spi_ss_num-1:0] spi_ss,
//     output                  spi_mosi,
//     input                   spi_miso,
//     output                  spi_irq_out
// );

// `ifdef FAST_FLASH

//   wire [31:0] data;
//   parameter invalid_cmd = 8'h0;
//   flash_cmd flash_cmd_i (
//       .clock(clock),
//       .valid(in_psel && !in_penable),
//       .cmd  (in_pwrite ? invalid_cmd : 8'h03),
//       .addr ({8'b0, in_paddr[23:2], 2'b0}),
//       .data (data)
//   );
//   assign spi_sck     = 1'b0;
//   assign spi_ss      = 8'b0;
//   assign spi_mosi    = 1'b1;
//   assign spi_irq_out = 1'b0;
//   assign in_pslverr  = 1'b0;
//   assign in_pready   = in_penable && in_psel && !in_pwrite;
//   assign in_prdata   = data[31:0];

// `else

//   parameter NORMAL = 0;
//   parameter XIP = 1;

//   parameter XIP_CMD = 0;
//   parameter XIP_DIVIED = 1;
//   parameter XIP_SS_RESET = 2;
//   parameter XIP_SS = 3;
//   parameter XIP_CTRL = 4;
//   parameter XIP_CHECK = 5;
//   parameter XIP_READ = 6;

//   reg state;
//   reg [2:0] xip_state;

//   reg [4:0] wb_adr_i;
//   reg [31:0] wb_dat_i;
//   reg [3:0] wb_sel_i;
//   reg wb_we_i;
//   wire wb_ack_o;

//   always @(posedge clock or reset) begin
//     if (reset) begin
//       state <= NORMAL;
//       xip_state <= XIP_CMD;
//       wb_adr_i <= 0;
//       wb_we_i <= 0;
//     end else begin
//       if (state == NORMAL) begin
//         if (in_paddr[31:28] == 4'h3) begin
//           wb_adr_i  <= 4;
//           wb_dat_i  <= {8'h03, in_paddr[23:0]};
//           wb_sel_i  <= 4'b1111;
//           wb_we_i   <= 1;
//           in_pready <= 0;
//           if (in_penable) begin
//             state <= XIP;
//             xip_state <= XIP_CMD;
//           end
//         end else begin
//           if (wb_ack_o) begin
//             wb_we_i   <= 0;
//             in_pready <= 1;
//           end else begin
//             wb_adr_i  <= in_paddr[4:0];
//             wb_dat_i  <= in_pwdata;
//             wb_sel_i  <= in_pstrb;
//             wb_we_i   <= in_pwrite;
//             in_pready <= 0;
//           end
//         end
//       end else begin
//         if (xip_state == XIP_CMD) begin
//           if (wb_ack_o) begin
//             wb_adr_i  <= 20;
//             wb_dat_i  <= 12;
//             wb_sel_i  <= 1;
//             wb_we_i   <= 1;
//             xip_state <= XIP_DIVIED;
//           end
//         end else if (xip_state == XIP_DIVIED) begin
//           if (wb_ack_o) begin
//             wb_adr_i  <= 24;
//             wb_dat_i  <= 0;
//             wb_sel_i  <= 1;
//             wb_we_i   <= 1;
//             xip_state <= XIP_SS_RESET;
//           end
//         end else if (xip_state == XIP_SS_RESET) begin
//           if (wb_ack_o) begin
//             wb_adr_i  <= 24;
//             wb_dat_i  <= 1;
//             wb_sel_i  <= 1;
//             wb_we_i   <= 1;
//             xip_state <= XIP_SS;
//           end
//         end else if (xip_state == XIP_SS) begin
//           if (wb_ack_o) begin
//             wb_adr_i  <= 16;
//             wb_dat_i  <= 32'h140;
//             wb_sel_i  <= 4'b1111;
//             wb_we_i   <= 1;
//             xip_state <= XIP_CTRL;
//           end
//         end else if (xip_state == XIP_CTRL) begin
//           if (wb_ack_o) begin
//             wb_adr_i  <= 16;
//             wb_we_i   <= 0;
//             xip_state <= XIP_CHECK;
//           end
//         end else if (xip_state == XIP_CHECK) begin
//           if (wb_ack_o) begin
//             if ((in_prdata & 32'h100) == 0) begin
//               wb_adr_i  <= 0;
//               xip_state <= XIP_READ;
//             end
//           end
//         end else begin
//           if (wb_ack_o) in_pready <= 1;
//           else begin
//             // when in_penable is false, the inst have completed
//             if (~in_penable) begin
//               state <= NORMAL;
//             end
//           end
//         end
//       end
//     end
//   end

//   spi_top u0_spi_top (
//       .wb_clk_i(clock),
//       .wb_rst_i(reset),
//       .wb_adr_i(wb_adr_i),
//       .wb_dat_i(wb_dat_i),
//       .wb_dat_o(in_prdata),
//       .wb_sel_i(wb_sel_i),
//       .wb_we_i (wb_we_i),
//       .wb_stb_i(in_psel),
//       .wb_cyc_i(in_penable),
//       .wb_ack_o(wb_ack_o),
//       .wb_err_o(in_pslverr),
//       .wb_int_o(spi_irq_out),

//       .ss_pad_o  (spi_ss),
//       .sclk_pad_o(spi_sck),
//       .mosi_pad_o(spi_mosi),
//       .miso_pad_i(spi_miso)
//   );

// `endif  // FAST_FLASH

// endmodule
