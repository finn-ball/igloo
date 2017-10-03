module infra(
	     input 	  clk_i,
	     output [7:0] led_o
	     );
   
   reg [31:0] 		  cnt;
   wire 		  clk_96;
   reg 			  tmp;
   
   always @ (posedge clk_96)
     begin
	cnt <= cnt + 1;
     end

   assign led_o = cnt[25:18];
 
   clks #(.CLK_DIV(8)) 
   clk(
	.clk_i (clk_i),
	.clk_o (clk_96)
	);
   
   uart_ctrl uart_ctrl(
		       .clk_i (clk_i)
		       );
   
endmodule // infra

