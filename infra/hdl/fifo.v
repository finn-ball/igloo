module fifo(
	    input 			w_clk,
	    input 			r_clk,
	    input 			we,
	    input [DATA_WIDTH - 1 : 0] 	d,
	    input 			re,
	    input [15 :0] 		mask,
	    output [DATA_WIDTH - 1 : 0] q,
	    output 			empty,
	    output 			full
	    );
   
   
   parameter DATA_WIDTH = 1;

   wire [15:0] 				_d, _q;

   assign _d = { {(16 - DATA_WIDTH){1'b0}}, {d} };
   assign q =  _q[DATA_WIDTH - 1 : 0];
   
   generate
      
      if (DATA_WIDTH <= 16 & DATA_WIDTH > 8)
	begin
	   	   
	   fifo_#(
		  .MODE(0),
		  .ADDR_WIDTH(8)
		  ) fifo_256x16_(
				 .w_clk(w_clk),
				 .r_clk(r_clk),
				 .we(we),
				 .d(_d),
				 .re(re),
				 .q(_q),
				 .empty(empty),
				 .full(full),
				 .mask(mask) // only masked option
				 );
	   
	end // if (16 >= DATA_WIDTH > 8)
      
      else if ( DATA_WIDTH <= 8 & DATA_WIDTH > 4)
	begin
	   
	   fifo_#(
		  .MODE(1),
		  .ADDR_WIDTH(9)
		  ) fifo_512x8(
			       .w_clk(w_clk),
			       .r_clk(r_clk),
			       .we(we),
			       .d(_d),
			       .re(re),
			       .q(_q),
			       .empty(empty),
			       .full(full),
			       .mask(16'b0)
			       );
	   
	end // if ( 8 >= DATA_WIDTH > 4)
      
      else if ( DATA_WIDTH <= 4 & DATA_WIDTH > 2)
	begin
	   
	   fifo_#(
		  .MODE(2),
		  .ADDR_WIDTH(10)
		  ) fifo_1024x4(
				.w_clk(w_clk),
				.r_clk(r_clk),
				.we(we),
				.d(_d),
				.re(re),
				.q(_q),
				.empty(empty),
				.full(full),
				.mask(16'b0)
				);

	end // if ( 4 >= DATA_WIDTH > 2)
      
      else if ( DATA_WIDTH <= 2 & DATA_WIDTH > 0)
	begin
	   
	   fifo_#(
		  .MODE(3),
		  .ADDR_WIDTH(11)
		  ) fifo_2048x2(
				.w_clk(w_clk),
				.r_clk(r_clk),
				.we(we),
				.d(_d),
				.re(re),
				.q(_q),
				.empty(empty),
				.full(full),
				.mask(16'b0)
				);

	end // if ( 2 >= DATA_WIDTH > 0)
      
   endgenerate
   
endmodule // fifo

module fifo_(
	     input 			 w_clk,
	     input 			 r_clk,
	     input 			 we,
	     input [DATA_WIDTH - 1 : 0]  d,
	     input 			 re,
	     input [DATA_WIDTH - 1 :0] 	 mask,
	     output [DATA_WIDTH - 1 : 0] q,
	     output 			 empty,
	     output 			 full
	    );
   
   parameter MODE = 0;
   parameter ADDR_WIDTH = 0;
   
   localparam DATA_WIDTH = 16;
   localparam DEPTH = 1 << (ADDR_WIDTH);
   
   reg [ADDR_WIDTH - 1 : 0] 		 waddr = 0, raddr = 0, ctr = 0;
   wire [10 : 0] 			 _waddr, _raddr;

   assign _waddr = { {(11 - ADDR_WIDTH){1'b0}}, {waddr} };
   assign _raddr = { {(11 - ADDR_WIDTH){1'b0}}, {raddr} };
   
   assign empty = (~|ctr);
   assign full = (&ctr);
   
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
		 .WRITE_MODE(MODE),
		 .READ_MODE(MODE)
		 ) bram (
			 .RDATA(q),
			 .RADDR(_raddr),
			 .RCLK(r_clk),
			 .RCLKE(1'b1),
			 .RE(re),
			 .WADDR(_waddr),
			 .WCLK(w_clk),
			 .WCLKE(1'b1),
			 .WDATA(d),
			 .WE(1'b1),
			 .MASK(mask)
			 );
   
endmodule // fifo_

