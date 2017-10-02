module top(
	   input 	ice_clk_i,
	   output [7:0] led_o
	   );
   
   reg 			a,b;
   
   
   infra infra (
	     .clk_i (ice_clk_i),
	     .led_o (led_o) 
	     );

endmodule // top

   
   
   
    
