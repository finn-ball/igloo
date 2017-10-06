`include "uart.vh"

module uart_rx(
		 input 				   clk_i,
		 input 				   rst_i,
		 input 				   rx_i,
		 output [`UART_DATA_WIDTH - 1 : 0] tx_o,
		 output 			   tx_o_v
	       );

   localparam CTR_WIDTH = $clog2(`UART_RX_SAMPLE_RATE);
   
   localparam ST_IDLE   = 2'd0;
   localparam ST_INIT   = 2'd1;
   localparam ST_DATA   = 2'd2;
   
   wire 					   rx_i_v;
   
   reg [1 : 0] 					   state = ST_IDLE, state_sample = ST_IDLE;
   reg [`UART_DATA_WIDTH - 1 : 0] 		   rx_byte;
   reg [ (CTR_WIDTH/2) - 1 : 0] 		   ctr_init = 0;		   
   reg [CTR_WIDTH - 1 : 0] 			   ctr_bit = 0, ctr_sample = 0;
   
   reg [`UART_DATA_WIDTH - 1 : 0] 		   s_tx_o;

   assign tx_o = s_tx_o;

   always @ (posedge clk_i)
     begin
	if (&ctr_init | state == ST_DATA)
	  begin
	     ctr_sample <= ctr_sample + 1;
	  end
     end   
   /*always @ (posedge clk_i)
     begin
	if (&ctr_sample)
	  begin
	     s_tx_o <= { {s_tx_o[`UART_DATA_WIDTH - 2 : 0]} , {rx_i} }; 
	  end
     end
   */
   always @ (posedge clk_i)
     begin
	case (state)
	  ST_IDLE:
	    if (~rx_i)
	      begin
		 state <= ST_INIT;
	      end

	  ST_INIT:
	    if (&ctr_sample[ (CTR_WIDTH / 2) - 1 : 0])
	      begin
		 state <= ST_DATA;
	      end
	  
	  ST_DATA:
	    if (&ctr_bit)
	      begin
		 state <= ST_IDLE;
	      end
	endcase // case (state)
     end // always @ (posedge clk_rx_i)
   
endmodule
