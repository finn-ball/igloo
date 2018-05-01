module top(
	   input	  ice_clk_i,
	   output [7:0]   led_o,
	   output	  vs_o,
	   output	  hs_o,
	   output [3 : 0] red_o,
	   output [3 : 0] blue_o,
	   output [3 : 0] green_o
	   );

   parameter WIDTH = 8;

   wire			clk_25;
   reg [8 : 0]		ctr = 3;
   wire			vs_valid;
   wire			hs_valid;

   assign red_o = hs_valid & vs_valid ? pix[7 : 4] : 0;
   assign blue_o = hs_valid & vs_valid ? pix[3 : 0] : 0;
   assign green_o = hs_valid & vs_valid? 4'b1111 : 0;

   always @(posedge clk_25)
     begin
	ctr <= ctr + 1;
     end

   genvar i;
   generate
      for (i = 0; i < 8; i = i + 1)
	begin
	   //assign led_o[i] = ctr[i + 18];
	end
   endgenerate

   clks#(
	 .PLL_EN(1),
	 .GBUFF_EN(1),
	 .DIVR(4'b0000),
	 .DIVF(7'b1000010),
	 .DIVQ(3'b101)
	 ) clks(
		.clk_i(ice_clk_i),
		.clk_o(clk_25)
		);

   vga vga(
	   .clk(clk_25),
	   .vs_o(vs_o),
	   .vs_valid(vs_valid),
	   .hs_o(hs_o),
	   .hs_valid(hs_valid)
	   );

   wire [7 : 0] pix;

   mandlebrot_factory mandle(
			     .clk(clk_25),
			     .raddr(ctr),
			     .q(pix)
			     );

endmodule // top
