module clks(
	    input  clk_i,
	    output clk_o
	    );

   parameter PLL_EN = 0;
   parameter GBUFF_EN = 0;

   // PLL params
   // Settings below default to clk_o = (clk_i / 8)
   
   parameter DIVR = 4'b0000;
   parameter DIVF = 7'b0111111;
   parameter DIVQ = 3'b011;

   // Non-PLL params

   parameter T = 1;

   // Parameters
   
   reg 		   s_clk_o = 0;
   wire 	   pll_clk_o;
   reg [31:0] 	   ctr = 0;
   
   generate
      if (GBUFF_EN == 1)
	begin: GB
	   SB_GB gb (
		     .USER_SIGNAL_TO_GLOBAL_BUFFER(s_clk_o),
		     .GLOBAL_BUFFER_OUTPUT (clk_o)
		     );
	end
      else
	begin: NO_GB
	   assign clk_o = s_clk_o;
	end
   endgenerate
   
   generate
      if (PLL_EN == 1)
      	begin: PLL
	   SB_PLL40_CORE #(
			   .FEEDBACK_PATH("SIMPLE"),
			   .PLLOUT_SELECT("GENCLK"),
			   .DIVR(DIVR),
			   .DIVF(DIVF),
			   .DIVQ(DIVQ),  
			   .FILTER_RANGE(3'b001)
			   ) uut (
				  .REFERENCECLK(clk_i),
				  .PLLOUTCORE(pll_clk_o),
				  .RESETB(1'b1),
				  .BYPASS(1'b0),
				  .EXTFEEDBACK(1'b0),
				  .DYNAMICDELAY(8'b00000000),
				  .LATCHINPUTVALUE(1'b0),
				  .SDI(1'b0),
				  .SCLK(1'b0)
			     );
	   always @ (pll_clk_o)
	     begin
		s_clk_o <= pll_clk_o;
	     end
	   
	end // block: PLL
      else
	begin: CTR
	   always @ (posedge clk_i)
	     begin
		if (ctr == (T - 1))
		  begin
		     s_clk_o <= ~s_clk_o;
		     ctr <= 0;
		  end
		else
		  begin
		     ctr <= ctr + 1;
		  end
	     end // always @ (posedge clk_i)
	end // block: CTR
   endgenerate
   
endmodule // clks
