`include "uart.vh"

module uart_rx(
		 input 			      clk_i,
		 input 			      rx_i,
		 output [DATA_LENGTH - 1 : 0] tx_o,
		 output 		      tx_o_v
	       );

   localparam SAMPLE_RATE = `UART_RX_SAMPLE_RATE;
   localparam SAMPLE_UPPER = `UART_RX_SAMPLE_UPPER;
   localparam SAMPLE_MID = `UART_RX_SAMPLE_MID;
   localparam SAMPLE_LOWER = `UART_RX_SAMPLE_LOWER;

   localparam SAMPLE_WIDTH = $clog2(SAMPLE_RATE);
   
   localparam PACKET_LENGTH = `UART_PACKET_LENGTH;
   localparam PACKET_WIDTH = $clog2(PACKET_LENGTH);
   localparam DATA_LENGTH = `UART_DATA_LENGTH;
   localparam DATA_WIDTH = $clog2(DATA_LENGTH);
   
   localparam ST_IDLE   = 2'd0;
   localparam ST_START  = 2'd1;
   localparam ST_DATA   = 2'd2;
   localparam ST_STOP   = 2'd3;
   
   reg [2 : 0] 				      state = ST_IDLE;
   reg 					      rx_i_d = 0;
   
   reg [PACKET_WIDTH - 1 : 0] 		     ctr_bit = 0; 		     
   reg [SAMPLE_WIDTH - 1 : 0] 		     ctr_sample = 0;
   
   reg [SAMPLE_RATE - 1 : 0] 		     rx_i_shift = 0;
   reg 					     rx_vote = 0;
   reg [DATA_LENGTH - 1 : 0] 		     s_tx_o = 0;
   
   assign tx_o = s_tx_o;
   assign tx_o_v = state == ST_STOP & rx_vote & ctr_sample == SAMPLE_UPPER;

   always @ (posedge clk_i)
     begin
	if (ctr_sample == SAMPLE_RATE | state == ST_IDLE)
	  begin
	     ctr_sample <= 0;
	  end
	else
	  begin
	     ctr_sample <= ctr_sample + 1;
	  end
     end

   always @ (posedge clk_i)
     begin
	if (state == ST_IDLE)
	  begin
	     ctr_bit <= 0;
	  end
	else if (ctr_sample == SAMPLE_RATE - 1)
	  begin
	     ctr_bit <= ctr_bit + 1;
	  end
     end

   always @ (posedge clk_i)
     begin
	rx_i_shift <= { {rx_i_shift[SAMPLE_RATE - 2 : 0]} , {rx_i} };
     end
   
   always @ (posedge clk_i)
     begin
	rx_vote <= (rx_i_shift[SAMPLE_UPPER] & rx_i_shift[SAMPLE_MID])
	         | (rx_i_shift[SAMPLE_UPPER] & rx_i_shift[SAMPLE_LOWER])
	         | (rx_i_shift[SAMPLE_MID] & rx_i_shift[SAMPLE_LOWER]);
     end
      
   always @ (posedge clk_i)
     begin
	if (ctr_sample == SAMPLE_RATE - 1)
	  begin
	     s_tx_o <= { {rx_vote}, {s_tx_o[DATA_LENGTH - 1 : 1]} }; 
	  end
     end

   always @ (posedge clk_i)
     begin
	rx_i_d <= rx_i;
     end
   
   always @ (posedge clk_i)
     begin
	case (state)

	  ST_IDLE:
	    if (~rx_i & rx_i_d)
	      begin
		 state <= ST_START;
	      end
	  
	  ST_START:
	    if (ctr_sample == SAMPLE_RATE - 1)
	      begin
		 state <= ST_DATA;
	      end
	  
	  ST_DATA:
	    if (ctr_bit == DATA_LENGTH & ctr_sample == SAMPLE_RATE - 1 )
	      begin
		 state <= ST_STOP;
	      end
	  
	  ST_STOP:
	    if (ctr_bit == PACKET_LENGTH - 1 & ctr_sample == SAMPLE_UPPER)
	      begin
		 state <= ST_IDLE;
	      end
	  
	endcase // case (state)
     end // always @ (posedge clk_rx_i)
   
endmodule
