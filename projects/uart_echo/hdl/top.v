`include "uart.vh"

module top(
	   input 	ice_clk_i,
	   input 	rstn_i,
	   input 	rs232_rx_i,
	   output [7:0] led_o,
	   output 	rs232_tx_o
	   );
   
   reg 			tx_i_v = 0, fifo_re = 0, fifo_re_d = 0, fifo_we = 0;   
   reg [`UART_DATA_LENGTH - 1 : 0] fifo_d = 0, tx_i = 0;
   
   wire 			   clk_uart_rx, clk_uart_tx;
   wire 			   fifo_empty, rx_o_v, tx_o_v;
   wire [`UART_DATA_LENGTH - 1 : 0] fifo_q, rx_o;
   
   infra infra (
		.clk_i (ice_clk_i),
		.clk_o_uart_rx(clk_uart_rx),
		.clk_o_uart_tx(clk_uart_tx),
		.rst_i(rstn_i),
		.led_o (led_o),
		.rx_i(rs232_rx_i),
		.rx_o(rx_o),
		.rx_o_v(rx_o_v),
		.tx_i(tx_i),
		.tx_i_v(tx_i_v),
		.tx_o(rs232_tx_o),
		.tx_o_v(tx_o_v)
		);
   
   fifo#(
	 .DATA_WIDTH(`UART_DATA_LENGTH),
	 .ASYNC(1)
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
	fifo_re <= ~fifo_empty & ~tx_o_v & ~tx_i_v & ~fifo_re & ~fifo_re_d;
	fifo_re_d <= fifo_re;
	tx_i <= fifo_q;
	tx_i_v <= fifo_re_d;
     end 
   
endmodule // top
   
    
