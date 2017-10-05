module fifo(
	    input 			w_clk,
	    input 			r_clk,
	    input 			we,
	    input [DATA_WIDTH - 1 : 0] 	d,
	    input 			re,
	    output [DATA_WIDTH - 1 : 0] q,
	    output 			empty,
	    output 			full
	    );


   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 9;

   reg [ADDR_WIDTH - 1 : 0] 		waddr =0, raddr = 0, ctr = 0;

   assign empty = (ctr == 0) ? 1 : 0;
   assign full = (& ctr) ? 1 : 0;
   
   always @(w_clk)
     begin
	if (we)
	  begin
	     waddr <= waddr + 1;
	  end
     end

   always @(r_clk)
     begin
	if (re)
	  begin
	     raddr <= raddr + 1;
	  end
     end

   always @(we | re)
     begin
	if (we & ~re & ~full)
	  begin
	     ctr <= ctr + 1;
	  end
	else if (~we & re & ~full)
	  begin
	     ctr <= ctr - 1;
	  end;	
     end
  
   
   SB_RAM40_4K #(
		 .WRITE_MODE(1'b1),
		 .READ_MODE(1'b1)
		 ) bram (
			 .RDATA(q),
			 .RADDR(raddr),
			 .RCLK(r_clk),
			 .RCLKE(1'b1),
			 .RE(re),
			 .WADDR(waddr),
			 .WCLK(w_clk),
			 .WCLKE(1'b1),
			 .WDATA(d),
			 .WE(1'b1)
			 );
   
endmodule // fifo
