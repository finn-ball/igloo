module clks(
	    input  clk_i,
	    output clk_o
	    );

   parameter CLK_DIV = 8;

   wire 	   s_clk_o;   
   
   generate
      if (CLK_DIV == 8)
	begin
	   
	   SB_GB gb (
		     .USER_SIGNAL_TO_GLOBAL_BUFFER(s_clk_o),
		     .GLOBAL_BUFFER_OUTPUT (clk_o)
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
				  .PLLOUTCORE(s_clk_o),
				  .RESETB(1'b1),
				  .BYPASS(1'b0)
				  );
	   
	end // if (CLK_SPEED == 8)
      else
	assign clk_o = clk_i;
      
   endgenerate
   
   


   
endmodule // clks
