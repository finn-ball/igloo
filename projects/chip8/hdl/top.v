`include "top.vh"
`include "chip8.vh"
`include "uart.vh"

module top(
	   input 	  ice_clk_i,
	   input 	  rstn_i,
	   input 	  rs232_rx_i,
	   output [7:0]   led_o,
	   output 	  vs_o,
	   output 	  hs_o,
	   output [3 : 0] red_o,
	   output [3 : 0] blue_o,
	   output [3 : 0] green_o
	   );
   
   wire 		  clk_uart_rx, clk_led, clk_25;
   
   reg [7 : 0] 		  rx_i = 0;
   reg 			  rx_i_v = 0, rx_i_v_d = 0, tx_o_v_d = 0;
   
   wire [7 : 0] 	  tx_o;
   wire 		  tx_o_v;
   
   wire [7 : 0] 	  _rx_i;
   wire 		  _rx_i_v;
   
   assign led_o[0] = 1;
   assign led_o[1] = clk_led;
   
   assign _rx_i = rx_i;
   assign _rx_i_v = rx_i_v;
   
   always @ (posedge ice_clk_i)
     begin
	rx_i_v <= tx_o_v & ~rx_i_v_d;
	rx_i_v_d <= tx_o_v;
	rx_i <= tx_o;
     end

   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(6000000)
	  )led_clk(
		   .clk_i (ice_clk_i),
		   .clk_o (clk_led)
		   );
   
   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(`UART_CLK_RX_FREQ / `UART_RX_SAMPLE_RATE / 2)
	  ) clk_uart_rx_gen(
			    .clk_i (ice_clk_i),
			    .clk_o (clk_uart_rx)
			    );   
   clks#(
	 .PLL_EN(1),
	 .GBUFF_EN(1),
	 .DIVR(4'b0000),
	 .DIVF(7'b1010011),
	 .DIVQ(3'b101)
	 //.DIVR(4'b0000),
	 //.DIVF(7'b1000010),
	 //.DIVQ(3'b101)
	 ) clks(
		.clk_i(ice_clk_i),
		.clk_o(clk_25)
		);
   
   uart_rx uart_rx(
		   .clk_i(clk_uart_rx),
		   .rx_i(rs232_rx_i),
		   .tx_o(tx_o),
		   .tx_o_v(tx_o_v)
		   );
   
   interpreter interpreter(
			   .clk(clk_25),
			   .rx_i(rx_i),
			   .rx_i_v(rx_i_v),
			   .hs(hs_o),
			   .vs(vs_o),
			   .red(red_o),
			   .blue(blue_o),
			   .green(green_o)
			   );
   
endmodule // top
