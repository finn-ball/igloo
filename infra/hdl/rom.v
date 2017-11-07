module rom(
	   input 		       clk,
	   input [ADDR_WIDTH - 1 : 0]  raddr,
	   output [DATA_WIDTH - 1 : 0] q
	   );
   
   parameter ADDR_WIDTH = 9;
   parameter DATA_WIDTH = 8;

   parameter INIT = 0;
   parameter FILE_NAME = "";
   parameter FILE_START = 0;
   parameter FILE_STOP = 512;
   
   localparam DEPTH = 1  << ADDR_WIDTH;
   
   reg [DATA_WIDTH - 1 : 0] 	       mem [DEPTH - 1 : 0];
   reg [DATA_WIDTH - 1 : 0] 	       _q = 0;
   
   initial
     begin
	if(INIT)
	  begin
	     $readmemh(FILE_NAME, mem, FILE_START, FILE_STOP - 1);
	  end
     end
   
   assign q = _q;
   
   always @ (posedge clk)
     begin
	_q <= mem[raddr];
     end // always @ (posedge clk)
   
endmodule // rom
