`include "uart.vh"

module infra(
	     input 	  clk_i,
	     output [7:0] led_o,
	     output 	  rs232_tx_o
	     );

   wire 		  clk_96;
   wire 		  clk_uart;
   wire 		  clk_led;

   clks #(
	  .PLL_EN (1),
	  .GBUFF_EN(1)
	  ) clk_96_gen(
		       .clk_i (clk_i),
		       .clk_o (clk_96)
		       );
   
   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(`UART_CLK_PERIOD)
	  )clk_uart_gen(
		   .clk_i (clk_i),
		   .clk_o (clk_uart)
		   );

   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(6000000)
	  )led_clk(
		   .clk_i (clk_i),
		   .clk_o (clk_led)
		   );
   
   uart_ctrl uart_ctrl(
		       .clk_i (clk_uart),
		       .rx (8'b01101001),
		       .rx_v (1'b1),
		       .tx (rs232_tx_o),
		       .tx_v (uart_tx_v)
		       );

   assign led_o[0] = clk_led; // Heartbeat
   assign led_o[7:1] = 0;
   
endmodule // infra

