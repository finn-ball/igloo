module top(
	   input 	ice_clk_i,
	   output [7:0] led_o,
	   output 	rs232_tx_o
	   );
   
   infra infra (
		.clk_i (ice_clk_i),
		.led_o (led_o),
		.rs232_tx_o(rs232_tx_o)
		);

endmodule // top

   
   
   
    
