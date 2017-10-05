`include "uart.vh"

module infra(
	     input 	  clk_i,
	     input 	  rs232_rx_i,
	     output [7:0] led_o,
	     output 	  rs232_tx_o
	     );

   wire 		  clk_96;
   wire 		  clk_led;
   wire 		  clk_rx_i, clk_tx_i;
   
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
	  .T(`UART_CLK_PERIOD * 8)
	  )clk_uart_rx_gen(
			.clk_i (clk_i),
			.clk_o (clk_rx_i)
			);
   
   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(`UART_CLK_PERIOD)
	  )clk_uart_tx_gen(
			.clk_i (clk_i),
			.clk_o (clk_tx_i)
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
		       .clk_rx_i (clk_rx_i),
		       .clk_tx_i (clk_tx_i),
		       .rx_i (rs232_rx_i),
		       .tx_o (rs232_tx_o)
		       );

   assign led_o[0] = clk_led; // Heartbeat
   assign led_o[7:1] = 0;
   
endmodule // infra

