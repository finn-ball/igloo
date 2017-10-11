`include "uart.vh"

module infra(
	     input 	  clk_i,
	     input 	  rst_i,
	     input 	  rs232_rx_i,
	     output [7:0] led_o,
	     output 	  rs232_tx_o
	     );
   
   wire 		  clk_96;
   wire 		  clk_led;
   wire 		  clk_uart_rx, clk_uart_tx;

   wire [`UART_DATA_LENGTH - 1 : 0] rx_o;
   wire 			    rx_o_v, tx_o_v;
   reg [`UART_DATA_LENGTH - 1 : 0]  tx_i;
   reg 				    tx_i_v = 0;   
   
   clks #(
	  .PLL_EN (1),
	  .GBUFF_EN(0)
	  ) clk_96_gen(
		       .clk_i (clk_i),
		       .clk_o (clk_96)
		       );
  
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
		       .rx_i (rs232_rx_i),
		       .rx_o (rx_o),
		       .rx_o_v(rx_o_v),
		       .tx_i(tx_i),
		       .tx_i_v(tx_i_v),
		       .tx_o (rs232_tx_o),
		       .tx_o_v (tx_o_v)
		       );

   reg 				    fifo_re, fifo_we = 0;
   reg [`UART_DATA_LENGTH - 1 : 0]  fifo_d;
   wire [`UART_DATA_LENGTH - 1 : 0] fifo_q;
   
   wire 			    fifo_empty;
   
   fifo#(
	 .DATA_WIDTH(`UART_DATA_LENGTH)
	 ) fifo(
		.w_clk(clk_uart_rx),
		.r_clk(clk_uart_tx),
		.we(fifo_we),
		.d(fifo_d),
		.re(fifo_re),
		.q(fifo_q),
		.empty(fifo_empty),
		.mask(16'b0)
		);   
   
   
   always @ (posedge clk_uart_rx)
     begin
	fifo_we <= rx_o_v;
	fifo_d <= rx_o;
     end
   
   always @ (posedge clk_uart_tx)
     begin
	fifo_re <= ~fifo_empty & ~tx_o_v & ~tx_i_v;
	tx_i <= fifo_q;
	tx_i_v <= fifo_re;
     end
   
   assign led_o[0] = clk_led; // Heartbeat
   assign led_o[1] = rst_i; // Resetting
   
   assign led_o[7:2] = 0;
   
endmodule // infra

