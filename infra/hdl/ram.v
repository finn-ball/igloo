module ram(
	   input 		       clk,
	   input 		       we,
	   input [ADDR_WIDTH - 1 : 0]  waddr,
	   input [DATA_WIDTH - 1 : 0]  d,
	   input 		       re,
	   input [ADDR_WIDTH - 1 : 0]  raddr,
	   output [DATA_WIDTH - 1 : 0] q
	   );
   
   parameter ADDR_WIDTH = 8;
   parameter DATA_WIDTH = 16;
   
   localparam DEPTH = 1  << ADDR_WIDTH;
   
   reg [DATA_WIDTH - 1 : 0] 	       mem [DEPTH - 1 : 0];
   reg [DATA_WIDTH - 1 : 0] 	       _q = 0;
   
   assign q = _q;
   
   always @ (posedge clk)
     begin
	if (we)
	  begin
	     mem[waddr] <= d;
	  end

	if (re)
	  begin
	     _q <= mem[raddr];
	  end
     end // always @ (posedge clk)
   
endmodule // ram

module dram_256x16(
		   input 		       w_clk,
		   input 		       r_clk,
		   input 		       w_clk_en,
		   input 		       r_clk_en,
		   input 		       we,
		   input [ADDR_WIDTH - 1 : 0]  waddr,
		   input [DATA_WIDTH - 1 : 0]  d,
		   input 		       re,
		   input [DATA_WIDTH - 1 :0]   mask,
		   input [ADDR_WIDTH - 1 : 0]  raddr,
		   output [DATA_WIDTH - 1 : 0] q
	    );
   
   localparam DATA_WIDTH = 16;
   localparam ADDR_WIDTH = 8;

   localparam RAM_DATA_WIDTH = 16;
   localparam RAM_ADDR_WIDTH = 11;
   
   wire [RAM_DATA_WIDTH - 1 : 0] 	      _d, _q;
   wire [RAM_ADDR_WIDTH - 1 : 0] 	      _waddr, _raddr;			      
   
   assign _waddr = { {(RAM_ADDR_WIDTH - ADDR_WIDTH){1'b0}}, {waddr} };
   assign _raddr = { {(RAM_ADDR_WIDTH - ADDR_WIDTH){1'b0}}, {raddr} };

   assign _d = d;
   assign q = _q;
   
   dram_#(
	  .MODE(0)
	  ) dram(
		 .w_clk(w_clk),
		 .r_clk(r_clk),
		 .w_clk_en(w_clk_en),
		 .r_clk_en(r_clk_en),
		 .we(we),
		 .waddr(_waddr),
		 .d(_d),
		 .re(re),
		 .raddr(_raddr),
		 .q(_q),
		 .mask(16'b0)
		 );

   
endmodule // dram_256x16

module dram_512x8(
		  input 		      w_clk,
		  input 		      r_clk,
		  input 		      w_clk_en,
		  input 		      r_clk_en,
		  input 		      we,
		  input [ADDR_WIDTH - 1 : 0]  waddr,
		  input [DATA_WIDTH - 1 : 0]  d,
		  input 		      re,
		  input [ADDR_WIDTH - 1 : 0]  raddr,
		  output [DATA_WIDTH - 1 : 0] q
		  );
   
   localparam DATA_WIDTH = 8;
   localparam ADDR_WIDTH = 9;

   localparam RAM_DATA_WIDTH = 16;
   localparam RAM_ADDR_WIDTH = 11;
   
   wire [RAM_DATA_WIDTH - 1 : 0] 	      _d, _q;
   wire [RAM_ADDR_WIDTH - 1 : 0] 	      _waddr, _raddr;			      

   assign _waddr = { {(RAM_ADDR_WIDTH - ADDR_WIDTH){1'b0}}, {waddr} };
   assign _raddr = { {(RAM_ADDR_WIDTH - ADDR_WIDTH){1'b0}}, {raddr} };
   
   genvar 				      i;
   generate
      for (i = 0; i < 8; i=i+1)
	begin
	   assign _d[i * 2 + 1] = 1'b0;
	   assign _d[i * 2]     = d[i];
	   
	   assign q[i] = _q[i * 2];
	end   
   endgenerate
   
   dram_#(
	  .MODE(1)
	  ) dram(
			.w_clk(w_clk),
			.r_clk(r_clk),
			.w_clk_en(w_clk_en),
			.r_clk_en(r_clk_en),
			.we(we),
			.waddr(_waddr),
			.d(_d),
			.re(re),
			.raddr(_raddr),
			.q(_q),
			.mask(16'b0)
			);
   
endmodule // dram_256x16

module dram_1024x4(
		  input 		      w_clk,
		  input 		      r_clk,
		  input 		      w_clk_en,
		  input 		      r_clk_en,
		  input 		      we,
		  input [ADDR_WIDTH - 1 : 0]  waddr,
		  input [DATA_WIDTH - 1 : 0]  d,
		  input 		      re,
		  input [ADDR_WIDTH - 1 : 0]  raddr,
		  output [DATA_WIDTH - 1 : 0] q
		  );
   
   localparam DATA_WIDTH = 4;
   localparam ADDR_WIDTH = 10;

   localparam RAM_DATA_WIDTH = 16;
   localparam RAM_ADDR_WIDTH = 11;
   
   wire [RAM_DATA_WIDTH - 1 : 0] 	      _d, _q;
   wire [RAM_ADDR_WIDTH - 1 : 0] 	      _waddr, _raddr;			      

   assign _waddr = { {(RAM_ADDR_WIDTH - ADDR_WIDTH){1'b0}}, {waddr} };
   assign _raddr = { {(RAM_ADDR_WIDTH - ADDR_WIDTH){1'b0}}, {raddr} };

   genvar 				      i;
   generate
   for (i = 0; i < 4; i=i+1)
     begin
	assign _d[i * 4 + 0] = 1'b0;
	assign _d[i * 4 + 1] = d[i];
	assign _d[i * 4 + 2] = 1'b0;
	assign _d[i * 4 + 3] = 1'b0;
	
	assign q[i] = _q[i * 4 + 1];
	
     end
   endgenerate
   
   dram_#(
	  .MODE(2)
	  ) dram_(
			.w_clk(w_clk),
			.r_clk(r_clk),
			.w_clk_en(w_clk_en),
			.r_clk_en(r_clk_en),
			.we(we),
			.waddr(_waddr),
			.d(_d),
			.re(re),
			.raddr(_raddr),
			.q(_q),
			.mask(16'b0)
			);
   
endmodule // dram_1024x4

module dram_2048x2(
		  input 		      w_clk,
		  input 		      r_clk,
		  input 		      w_clk_en,
		  input 		      r_clk_en,
		  input 		      we,
		  input [ADDR_WIDTH - 1 : 0]  waddr,
		  input [DATA_WIDTH - 1 : 0]  d,
		  input 		      re,
		  input [ADDR_WIDTH - 1 : 0]  raddr,
		  output [DATA_WIDTH - 1 : 0] q
		  );
   
   localparam DATA_WIDTH = 2;
   localparam ADDR_WIDTH = 11;

   localparam RAM_DATA_WIDTH = 16;
   localparam RAM_ADDR_WIDTH = 11;
   
   wire [RAM_DATA_WIDTH - 1 : 0] 	      _d, _q;
   wire [RAM_ADDR_WIDTH - 1 : 0] 	      _waddr, _raddr;			      

   assign _waddr = waddr;
   assign _raddr = raddr;

   genvar 				      i;
   for (i = 0; i < 2; i=i+1)
     begin
	assign _d[i * 8 + 2 : i * 8]     = 0;
	assign _d[i * 8 + 3]             = d[i];
	assign _d[i * 8 + 7 : i * 8 + 4] = 0;
	
	assign q[i] = _q[i * 8 + 3];
     end   
   
   dram_#(
	  .MODE(3)
	  ) dram_(
			.w_clk(w_clk),
			.r_clk(r_clk),
			.w_clk_en(w_clk_en),
			.r_clk_en(r_clk_en),
			.we(we),
			.waddr(_waddr),
			.d(_d),
			.re(re),
			.raddr(_raddr),
			.q(_q),
			.mask(16'b0)
			);
   
endmodule // dram_2048x2

module dram_(
	    input 			    w_clk,
	    input 			    r_clk,
	    input 			    w_clk_en,
	    input 			    r_clk_en,
	    input 			    we,
	    input [RAM_ADDR_WIDTH - 1 : 0]  waddr,
	    input [RAM_DATA_WIDTH - 1 : 0]  d,
	    input 			    re,
	    input [RAM_DATA_WIDTH - 1 :0]   mask,
	    input [RAM_ADDR_WIDTH - 1 : 0]  raddr,
	    output [RAM_DATA_WIDTH - 1 : 0] q
	    );
   
   parameter MODE = -1;
   localparam RAM_DATA_WIDTH = 16;
   localparam RAM_ADDR_WIDTH = 11;
   
   SB_RAM40_4K #(
		 .WRITE_MODE(MODE),
		 .READ_MODE(MODE)
		 ) bram (
			 .RDATA(q),
			 .RADDR(raddr),
			 .RCLK(r_clk),
			 .RCLKE(r_clk_en),
			 .RE(re),
			 .WADDR(waddr),
			 .WCLK(w_clk),
			 .WCLKE(w_clk_en),
			 .WDATA(d),
			 .WE(we),
			 .MASK(mask)
			 );
   
endmodule // dram_
