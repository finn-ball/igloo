module top_tb;

   reg clk_i;
   wire [7:0] led_o;
   
   top tb (
	   .ice_clk_i (clk_i),
	   .led_o (led_o)
	   );
   
   always #10 clk_i = ~clk_i;

   initial begin
      clk_i = 0;
   end
      
endmodule // top

   
   
   
    
