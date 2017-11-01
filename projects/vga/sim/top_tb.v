`include "top.vh"

module top_tb;
   
   reg clk_i = 0;
   wire [7:0] led_o;

   wire       vs_o, hs_o;
   wire [3 : 0] green_o, red_o, blue_o;
      
   initial
     begin
	
	$dumpfile("./build/iverilog/vga.vcd");
	$dumpvars(0,top_tb);
	
	# 100000 $finish;
	
     end
   
   always #1 clk_i = ~clk_i;
   
   top tb (
	   .ice_clk_i (clk_i),
	   .led_o (led_o),
	   .vs_o(vs_o),
	   .hs_o(hs_o),
	   .red_o(red_o),
	   .blue_o(blue_o),
	   .green_o(green_o)
	   );
   
endmodule // top

   
   
   
    
