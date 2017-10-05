`include "uart.vh"

module uart_rx(
		 input 				   clk_rx_i,
		 input 				   rx_i,
		 input 				   clk_tx_i, 
		 output [`UART_DATA_WIDTH - 1 : 0] tx_o,
		 output 			   tx_o_v
		 );
   
   localparam ST_IDLE   = 3'd0;
   localparam ST_START  = 3'd1;
   localparam ST_DATA   = 3'd2;
   localparam ST_STOP   = 3'd3;
   
   reg [2:0] 					   state = ST_IDLE;
   
   /*
   always @ (posedge clk_rx_i)
     begin
	case (state)
	  

	endcase // case (state)
     end // always @ (posedge clk_rx_i)
   
	      

   fifo fifo(
	     .w_clk(clk_rx_i),
	     .r_clk(clk_tx_i),
	     .we(rx_v),
	     .d(rx),
	     .re(re),
	     .q(q)
	     );
*/	
endmodule
