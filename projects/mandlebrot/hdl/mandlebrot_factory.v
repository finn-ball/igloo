module mandlebrot_factory(
			  input clk,
			  input [ADDR_WIDTH - 1 : 0]raddr,
			  output [DATA_WIDTH - 1 : 0] q
			  );
   // Plot between
   // (-2, 2)Re, (1,-1)Im

   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 9;
   // parameter PIPE_WIDTH = 2 * DATA_WIDTH + 5;
   // parameter PIPE_WIDTH = 2 * DATA_WIDTH + 3;
   parameter PIPE_WIDTH = 2 * DATA_WIDTH + 7;

   // localparam MAX_N_IT = 1 << DATA_WIDTH;
   localparam MAX_N_IT = 5; // remove to be max data width

   reg 						 we = 0;
   reg [DATA_WIDTH - 1 : 0] 			 iteration_pipe[PIPE_WIDTH - 1 : 0];
   reg [ADDR_WIDTH - 1 : 0] 			 ctr = 0;
   reg [ADDR_WIDTH - 1 : 0] 			 waddr_pipe[PIPE_WIDTH - 1 : 0];

   wire 					 escaped;
   wire 					 en;

   always @(posedge clk)
     begin
	if ( ~en || escaped || (iteration_pipe[PIPE_WIDTH - 1] > MAX_N_IT) )
	  begin
	     ctr <= ctr + 1;
	  end
     end

   always @(posedge clk)
     begin
	if ( escaped || (iteration_pipe[PIPE_WIDTH - 2] > (MAX_N_IT - 1)) )
	  begin
	     we <= 1;
	     iteration_pipe[0] <= 0;
	  end
	else
	  begin
	     we <= 0;
	     iteration_pipe[0] <= en ? iteration_pipe[PIPE_WIDTH - 2] + 1 : 0;
	  end
     end // always @ (posedge clk)

   always @(posedge clk)
     begin
	if ( ~en || escaped || (iteration_pipe[PIPE_WIDTH - 2] > MAX_N_IT - 1) )
	  begin
	     waddr_pipe[0] <= ctr;
	  end
	else
	  begin
	     waddr_pipe[0] <= waddr_pipe[PIPE_WIDTH - 2];
	  end
     end

   genvar i;
   generate
      for (i = 1; i < PIPE_WIDTH; i = i + 1)
	begin
	   always @(posedge clk)
	     begin
		waddr_pipe[i] <= waddr_pipe[i - 1];

		if (i == PIPE_WIDTH - 1)
		  begin
		     iteration_pipe[i] <= escaped ? iteration_pipe[i - 1] : iteration_pipe[i - 1] + 1;
		  end
		else
		  begin
		     iteration_pipe[i] <= iteration_pipe[i - 1];
		  end
	     end
	end
   endgenerate

   wire [DATA_WIDTH - 1 : 0] d;
   wire [ADDR_WIDTH - 1 : 0] waddr;

   assign d = iteration_pipe[PIPE_WIDTH - 1];
   assign waddr = waddr_pipe[PIPE_WIDTH - 1];

   dram_512x8#(
	) memory (
		  .w_clk(clk),
		  .r_clk(clk),
		  .we(we),
		  .waddr(waddr),
		  .d(d),
		  .re(1'b1),
		  .raddr(raddr),
		  .q(q)
		  );

   reg [ADDR_WIDTH - 1 : 0] re_i, re_c;
   wire [ADDR_WIDTH - 1 : 0] re_o;
   reg [ADDR_WIDTH - 1 : 0]  im_i, im_c;
   wire [ADDR_WIDTH - 1 : 0] im_o;

   reg 			     valid_i;

   always @(*)
     begin
	if (~en ||~escaped)
	  begin
	     re_i <= 0;
	     im_i <= 0;
	     re_c <= waddr_pipe[0];
	     im_c <= waddr_pipe[0];
	  end
	else
	  begin
	     re_i <= re_o;
	     im_i <= im_o;
	     re_c <= waddr_pipe[0];
	     im_c <= waddr_pipe[0];
	  end
     end // always @ (*)

   always @(posedge clk)
     begin
	valid_i <= 1'b1;
     end

   mandlebrot#(
	       .WIDTH(ADDR_WIDTH)
	       ) mandle(
			.clk(clk),
			.re_i(re_i),
			.im_i(im_i),
			.re_c(re_c),
			.im_c(im_c),
			.re_o(re_o),
			.im_o(im_o),
			.escaped(escaped),
			.valid_i(valid_i),
			.valid_o(en)
			);

   integer 		     k;
   initial
     begin
	$dumpfile("./build/iverilog/mandlebrot.vcd");
	for (k = 0; k < PIPE_WIDTH; k = k + 1)
	  begin
	     $dumpvars(0, iteration_pipe[k]);
	     $dumpvars(0, waddr_pipe[k]);
	  end
     end


endmodule
