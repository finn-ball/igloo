`include "chip8.vh"

module top(
	   input 	ice_clk_i,
	   input 	rstn_i,
	   input 	rs232_rx_i,
	   output [7:0] led_o,
	   output 	rs232_tx_o
	   );

   localparam ADDR_WIDTH = 12;
   localparam DATA_WIDTH = 8;

   wire 		we, re;
   wire [DATA_WIDTH - 1 : 0] d, q;
   wire [ADDR_WIDTH - 1 : 0] waddr, raddr;
   
   mem#(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH),
	.INIT(1),
	.SPRITE_FILE_NAME("projects/chip8/cfg/sprite.hex"),
	.SPRITE_FILE_WIDTH(80),
	.PROGRAM_FILE_NAME("projects/chip8/cfg/pong.hex"),
	.PROGRAM_FILE_WIDTH(256)
	) mem (
	       .clk(ice_clk_i),
	       .we(we),
	       .waddr(waddr),
	       .d(d),
	       .re(1'b1),
	       .raddr(raddr),
	       .q(q)
	       );

   interpreter interpreter(
			   .clk(ice_clk_i),
			   .d(q),
			   .raddr(raddr)
			   );

endmodule // top
