`include "uart.vh"

module uart_ctrl(
		 input 	clk_rx_i,
		 input 	clk_tx_i,
		 input 	rst_i,
		 input 	rx_i,
		 output tx_o
		 );

   wire [7:0] 					  q;
   wire 					  full,empty;

   wire 					  tx_busy;
   wire 					  tx_v;

   wire [`UART_DATA_WIDTH - 1 : 0] 		  rx_o;
   wire 					  rx_o_v;

   uart_rx uart_rx(
		   .clk_i(clk_rx_i),
		   .rst_i(rst_i),
		   .rx_i(rx_i),
		   .tx_o(rx_o),
		   .tx_o_v(rx_o_v)
		   );
   
   uart_tx uart_tx(
		   .clk_i (clk_tx_i),
		   .rx_i (rx_o),
		   .rx_i_v (rx_o_v),
		   .tx_o (tx_o),
		   .tx_o_v (tx_busy)
		   );

   /*   fifo#(
    .DATA_WIDTH(8)
    ) fifo(
    .w_clk(clk_rx_i),
    .r_clk(clk_tx_i),
    .we(wen),
    .d(rx_byte),
    .re(re),
    .q(tx_o),
    .mask(16'b0)
    );
    */ 

   
endmodule // uart_ctrl
