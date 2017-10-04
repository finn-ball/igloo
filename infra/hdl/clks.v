module clks(
	    input  clk_i,
	    output clk_o
	    );

   // Settings below default to clk_o = (clk_i / 8)
   
   parameter DIVR = 4'b0000;
   parameter DIVF = 7'b0111111;
   parameter DIVQ = 3'b011;
  
   wire 	   s_clk_o;  
   
   SB_GB gb (
	     .USER_SIGNAL_TO_GLOBAL_BUFFER(s_clk_o),
	     .GLOBAL_BUFFER_OUTPUT (clk_o)
	     );
   
   SB_PLL40_CORE #(
		   .FEEDBACK_PATH("SIMPLE"),
		   .PLLOUT_SELECT("GENCLK"),
		   .DIVR(DIVR),
		   .DIVF(DIVF),
		   .DIVQ(DIVQ),  
		   .FILTER_RANGE(3'b001)
		   ) uut (
			  .REFERENCECLK(clk_i),
			  .PLLOUTCORE(s_clk_o),
			  .RESETB(1'b1),
			  .BYPASS(1'b0),
			  .EXTFEEDBACK(1'b0),
			  .DYNAMICDELAY(8'b00000000),
			  .LATCHINPUTVALUE(1'b0),
			  .SDI(1'b0),
			  .SCLK(1'b0)
			  );
   
endmodule // clks
