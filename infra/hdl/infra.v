module infra(
	     input 	  clk_i,
	     output [7:0] led_o
	     );
   
   reg [31:0] 		  cnt;
   wire 		  clk_96;
   
   always @ (posedge clk_96)
     begin
	cnt <= cnt + 1;
     end
   
   genvar i;
   generate
      for (i = 0; i<8; i = i + 1) begin
	 assign led_o[i] = cnt[i + 18];
      end
   endgenerate
   
   clks clks(
	     .clk_i (clk_i),
	     .clk_96_o (clk_96)
	     );
   
   
endmodule // infra

