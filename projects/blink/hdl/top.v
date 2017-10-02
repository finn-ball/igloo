module top(
	   input 	ice_clk_i,
	   output [7:0] led_o
	   );
   
   reg [31:0] 		ctr;

   always @(posedge ice_clk_i)
     begin
	ctr <= ctr +1;
     end

   genvar i;
   generate
      for (i = 0; i<8; i = i + 1) begin
	 assign led_o[i] = ctr[i + 18];
      end
   endgenerate
   

endmodule // top

   
   
   
    
