`include "uart.vh"

module uart_ctrl(
		 input 				    clk_rx_i,
		 input 				    clk_tx_i,
		 input 				    rx_i,
		 output [`UART_DATA_LENGTH - 1 : 0] rx_o,
		 output 			    rx_o_v,
		 input [`UART_DATA_LENGTH - 1 : 0]  tx_i,
		 input 				    tx_i_v,
		 output 			    tx_o,
		 output 			    tx_o_v 			    
		 );

   uart_rx uart_rx(
		   .clk_i(clk_rx_i),
		   .rx_i(rx_i),
		   .tx_o(rx_o),
		   .tx_o_v(rx_o_v)
		   );
   
   uart_tx uart_tx(
		   .clk_i (clk_tx_i),
		   .rx_i (tx_i),
		   .rx_i_v (tx_i_v),
		   .tx_o (tx_o),
		   .tx_o_v (tx_o_v)
		   );
   
endmodule // uart_ctrl
