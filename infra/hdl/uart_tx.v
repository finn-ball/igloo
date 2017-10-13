`include "uart.vh"

module uart_tx(
	       input 				 clk_i,
	       input [`UART_DATA_LENGTH - 1 : 0] rx_i,
	       input 				 rx_i_v, 
	       output 				 tx_o,
	       output 				 tx_o_v
	       );

   localparam ST_IDLE   = 3'd0;
   localparam ST_START  = 3'd1;
   localparam ST_DATA   = 3'd2;
   localparam ST_STOP   = 3'd3;
   
   reg [2:0] 					  state = ST_IDLE;
   reg [2:0] 					  tx_ctr = 0;
   
   reg [`UART_DATA_LENGTH - 1 : 0] 		  s_rx = 0;
   reg 						  s_tx = 1;
   
   
   always @ (posedge clk_i)
     begin
	case (state)
	  
	  ST_IDLE :
	    if (rx_i_v)
	      begin
		 state <= ST_START;
	      end
	  
	  ST_START :
	    state <= ST_DATA;
	  
	  ST_DATA :
	    if (tx_ctr == 7)
	      begin
		 state <= ST_STOP;
	      end

	  ST_STOP :
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
	     s_rx <= rx_i;
	  end
	else if (state == ST_DATA)
	  begin
	     s_rx <= s_rx >> 1;
	  end
     end

   assign tx_o_v = (state == ST_IDLE) ? 0 : 1;

   always @ *
     begin
	if (state == ST_START)
	  begin
	     s_tx = 0;
	  end
	else if (state == ST_DATA)
	  begin
	     s_tx = s_rx[0];
	  end
	else if (state == ST_STOP)
	  begin
	     s_tx = 1;
	  end
     end // always @ *
   
   assign tx_o = s_tx;

   
endmodule // uart_tx
