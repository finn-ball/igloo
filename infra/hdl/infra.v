`include "uart.vh"

module infra(
	     input 				clk_i,
	     output 				clk_o_uart_rx,
	     output 				clk_o_uart_tx,
	     input 				rst_i,
	     output [7:0] 			led_o,
	     input 				rx_i,
	     output [`UART_DATA_LENGTH - 1 : 0] rx_o,
	     output 				rx_o_v,
	     input [`UART_DATA_LENGTH - 1 : 0] 	tx_i,
	     input 				tx_i_v,
	     output 				tx_o,
	     output 				tx_o_v
	     );
   
   wire 					clk_led;
   wire 					clk_uart_rx, clk_uart_tx;

   assign clk_o_uart_rx = clk_uart_rx;
   assign clk_o_uart_tx = clk_uart_tx;
   
   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(1),
	  .T(`UART_CLK_RX_FREQ / `UART_RX_SAMPLE_RATE / 2)
	  )clk_uart_rx_gen(
			.clk_i (clk_i),
			.clk_o (clk_uart_rx)
			);
   
   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(1),
	  .T(`UART_CLK_TX_FREQ / 2)
	  )clk_uart_tx_gen(
			.clk_i (clk_i),
			.clk_o (clk_uart_tx)
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
		       .clk_rx_i (clk_uart_rx),
		       .clk_tx_i (clk_uart_tx),
		       .rx_i (rx_i),
		       .rx_o (rx_o),
		       .rx_o_v(rx_o_v),
		       .tx_i(tx_i),
		       .tx_i_v(tx_i_v),
		       .tx_o (tx_o),
		       .tx_o_v (tx_o_v)
		       );
   
   assign led_o[0] = clk_led; // Heartbeat
   assign led_o[1] = rst_i; // Resetting
   
   assign led_o[7:2] = 0;
   
endmodule // infra

