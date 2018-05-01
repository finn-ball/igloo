module mandlebrot_factory(
			  input clk,
			  input [ADDR_WIDTH - 1 : 0]raddr,
			  output [DATA_WIDTH - 1 : 0] q
			  );
   // Plot between
   // (-2, 2)Re, (1,-1)Im

   parameter DATA_WIDTH = 8;
   parameter ADDR_WIDTH = 9;
   parameter PIPE_WIDTH = 2 * DATA_WIDTH + 3;

   // localparam MAX_N_IT = 1 << DATA_WIDTH;
   localparam MAX_N_IT = 3; // remove to be max data width

   reg 						 we = 0;
   reg [DATA_WIDTH - 1 : 0] 			 iteration_pipe[PIPE_WIDTH - 1 : 0];
   reg [ADDR_WIDTH - 1 : 0] 			 ctr = 0;
   reg [ADDR_WIDTH - 1 : 0] 			 waddr_pipe[PIPE_WIDTH - 1 : 0];

   wire 					 escaped;
   wire 					 en;

   always @(posedge clk)
     begin
	if (~en)
	  begin
	     ctr <= ctr + 1;
	  end
	else if ( escaped || (iteration_pipe[PIPE_WIDTH - 1] > MAX_N_IT))
	  begin
	     ctr <= ctr + 1;
	  end
     end

   always @(posedge clk)
     begin
	if ( escaped || (iteration_pipe[PIPE_WIDTH - 1] > MAX_N_IT) )
	  begin
	     we <= 1;
	     iteration_pipe[0] <= 0;
	  end
	else
	  begin
	     we <= 0;
	     iteration_pipe[0] <= en ? iteration_pipe[PIPE_WIDTH - 1] : 0;
	  end
     end // always @ (posedge clk)

   always @(posedge clk)
     begin
	if (~en | we)
	  begin
	     waddr_pipe[0] <= ctr;
	  end
	else
	  begin
	     waddr_pipe[0] <= waddr_pipe[PIPE_WIDTH - 1];
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
		     if (escaped)
		       begin
			  iteration_pipe[i] <= iteration_pipe[i - 1];
		       end
		     else
		       begin
			  iteration_pipe[i] <= iteration_pipe[i - 1] + 1;
		       end
		  end // if (i == PIPE_WIDTH - 1)
		else
		  begin
		     iteration_pipe[i] <= iteration_pipe[i - 1];
		  end // else: !if(i == PIPE_WIDTH - 1)
	     end
	end
   endgenerate

   wire [DATA_WIDTH - 1 : 0] d;
   reg [ADDR_WIDTH - 1 : 0] waddr;
   assign d = iteration_pipe[PIPE_WIDTH - 1];

   always @(posedge clk)
     begin
	waddr <= waddr_pipe[PIPE_WIDTH - 1];
     end

   /*
   ram#(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH)
	) memory (
		  .clk(clk),
		  .we(we),
		  .waddr(waddr),
		  .d(d),
		  .re(1'b1),
		  .raddr(raddr),
		  .q(q)
		  );
    */

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

   wire [ADDR_WIDTH - 1 : 0] re_o;
   wire [ADDR_WIDTH - 1 : 0] im_o;

   mandlebrot#(
	       .WIDTH(ADDR_WIDTH)
	       ) mandle(
			.clk(clk),
			.re_i(ctr),
			.im_i(ctr),
			.re_o(re_o),
			.im_o(im_o),
			.escaped(escaped),
			.valid_i(1'b1),
			.valid_o(en)
			);

   integer 		     j;
   initial
     begin
	$dumpfile("./build/iverilog/mandlebrot.vcd");
	for (j = 0; j < PIPE_WIDTH; j = j + 1)
	  begin
	     $dumpvars(0, iteration_pipe[j]);
	     $dumpvars(0, waddr_pipe[j]);
	  end
     end


endmodule
