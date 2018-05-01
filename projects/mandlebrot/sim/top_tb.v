`include "top.vh"

module top_tb;

   reg clk_i = 0;

   wire [7:0] led_o;
   wire       vs;
   wire       hs;
   wire [3 : 0] red;
   wire [3 : 0] blue;
   wire [3 : 0] green;
   integer	j = 0;

   initial
     begin

	$dumpfile("./build/iverilog/mandlebrot.vcd");
	$dumpvars(0,top_tb);

	# 1000 $finish;

     end // initial begin

   always #1 clk_i = ~clk_i;

   top tb (
	   .ice_clk_i (clk_i),
	   .led_o (led_o),
	   .vs_o(vs),
	   .hs_o(hs),
	   .red_o(red),
	   .blue_o(blue),
	   .green_o(green)
	   );

endmodule // top
