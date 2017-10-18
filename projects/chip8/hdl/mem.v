module mem(
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

   parameter INIT = 0;
   parameter SPRITE_FILE_NAME = "";
   parameter SPRITE_FILE_WIDTH = 80;
   parameter PROGRAM_FILE_NAME = "";
   parameter PROGRAM_FILE_WIDTH = 256;
   
   localparam PROGRAM_FILE_START = 512;
   
   initial
     begin
	if (INIT)
	  begin
	     $readmemh(SPRITE_FILE_NAME, mem, 0, SPRITE_FILE_WIDTH - 1);
	     $readmemh(PROGRAM_FILE_NAME, mem,
		       PROGRAM_FILE_START, PROGRAM_FILE_START + PROGRAM_FILE_WIDTH - 1);
	  end
     end
   
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
