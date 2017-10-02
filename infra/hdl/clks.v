module clks(
	    input  clk_i,
	    output clk_96_o
	    );
   
   wire 	   s_clk_96;
   
   SB_GB gb (
	     .USER_SIGNAL_TO_GLOBAL_BUFFER(s_clk_96),
	     .GLOBAL_BUFFER_OUTPUT (clk_96_o)
	     );
   
   SB_PLL40_CORE #(
		   .FEEDBACK_PATH("SIMPLE"),
                   .PLLOUT_SELECT("GENCLK"),
                   .DIVR(4'b0000),
                   .DIVF(7'b0111111),
                   .DIVQ(3'b011),  
		   
                   .FILTER_RANGE(3'b001)
                   ) uut (
			  .REFERENCECLK(clk_i),
			  .EXTFEEDBACK(null),
			  //.DYNAMICDELAY(null),
			  .LATCHINPUTVALUE(null),
			  .PLLOUTCORE(s_clk_96),
			  .RESETB(1'b1),
			  .BYPASS(1'b0)
			  );

endmodule // clks
