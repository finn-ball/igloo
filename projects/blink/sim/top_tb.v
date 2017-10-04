module top_tb;

   reg clk_i = 0;
   wire [7:0] led_o;
   
   initial
     begin
	
	$dumpfile("./build/iverilog/blink.vcd");
	$dumpvars(0,top_tb);
	
	# 500 $finish;
	
     end

   
   always #1 clk_i = ~clk_i;
   
   
   top tb (
	   .ice_clk_i (clk_i),
	   .led_o (led_o)
	   );
    

endmodule // top

   
   
   
    
