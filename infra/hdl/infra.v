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

   reg [3:0]			  ctr = 0;
   reg [9:0] 		  rx_tmp = 10'b1010001110;
   wire 		  tmp_rx_bit;
   
   
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
	  .T(`UART_CLK_RX_PERIOD * `UART_RX_SAMPLE_RATE)
	  )clk_uart_rx_gen(
			.clk_i (clk_i),
			.clk_o (clk_uart_rx)
			);
   
   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(`UART_CLK_TX_PERIOD)
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
		       .rst_i(rst_i),
		       .rx_i (tmp_rx_bit),
		       //.rx_i (rs232_rx_i),
		       .tx_o (rs232_tx_o)
		       );
    
   
   assign tmp_rx_bit = rx_tmp[ctr];
   
   always @ (posedge clk_uart_tx)
     begin
	if (ctr[3:0] == 9 | rst_i)
	  begin
	     ctr <= 0;
	  end
	else
	  begin
	     ctr <= ctr + 1;
	  end
     end

   reg rst_led;
   
   always @ (negedge rst_i)
     begin
	rst_led <= 1;
     end // always @ clk_i
   
   
   assign led_o[0] = clk_led; // Heartbeat
   assign led_o[1] = rst_i; // Resetting
   assign led_o[2] = rst_led; // Finished Reset
   
   assign led_o[7:4] = 0;
   
endmodule // infra

