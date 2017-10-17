`include "uart.vh"
`include "chip8.vh"

module top(
	   input 	ice_clk_i,
	   input 	rstn_i,
	   input 	rs232_rx_i,
	   output [7:0] led_o,
	   output 	rs232_tx_o
	   );

   localparam ADDR_WIDTH = 2;
   localparam DATA_WIDTH = 2;
   
   wire [DATA_WIDTH - 1 : 0] 	d, q;
   wire [ADDR_WIDTH - 1 : 0] waddr, raddr;

   assign raddr = 0;
   assign waddr = 0;
   
   ram#(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
	 ) ram(
	       .clk(ice_clk_i),
	       .we(1'b0),
	       .waddr(waddr),
	       .d(d),
	       .re(1'b1),
	       .raddr(raddr),
	       .q(q)
	       );


   
endmodule // top
