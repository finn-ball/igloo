`include "uart.vh"

module uart_ctrl(
		 input 				  clk_i,
		 input [`UART_DATA_WIDTH - 1 : 0] rx,
		 input 				  rx_v, 
		 output 			  tx,
		 output 			  tx_v
		 );
   
   localparam ST_IDLE  = 3'd0;
   localparam ST_START = 3'd1;
   localparam ST_DATA  = 3'd2;
   localparam ST_DONE  = 3'd3;
   
   reg [2:0] 					   state = ST_IDLE;
   reg [2:0] 					   tx_ctr = 0;

   reg [`UART_DATA_WIDTH - 1 : 0] 		   s_rx = 0;
   
   always @ (posedge clk_i)
     begin
	case (state)
	  
	  ST_IDLE :
	    if (rx_v)
	      begin
		 state <= ST_START;
	      end
	  
	  ST_START :
	    state <= ST_DATA;
	  
	  ST_DATA :
	    if (tx_ctr == 7)
	      begin
		 state <= ST_DONE;
	      end
	  
	  ST_DONE :
	    state <= ST_IDLE;
	  
	endcase
     end // always @ (posedge clk_i)

   always @ (posedge clk_i)
     begin
	if (state == ST_DATA)
	  begin
	     tx_ctr <= tx_ctr + 1;
	  end
	else
	  begin
	     tx_ctr <= 0;
	  end
     end // always @ (posedge state)

   always @ (posedge clk_i)
     begin
	if (state == ST_START)
	  begin
	     s_rx <= rx;
	  end
	else if (state == ST_DATA)
	  begin
	     s_rx <= s_rx >> 1;
	  end
     end

   assign tx_v = (state == ST_DATA) ? 1 : 0;
   assign tx = s_rx[0];
   
endmodule // uart_ctrl
