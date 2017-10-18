`include "chip8.vh"

module interpreter(
		   input 		       clk,
		   input [DATA_WIDTH - 1 : 0]  d,
		   output [ADDR_WIDTH - 1 : 0] raddr
		   );

   localparam ADDR_WIDTH = 12;
   localparam DATA_WIDTH = 8;
   
   localparam ST_IDLE        = 0;
   localparam ST_OP          = 1;
   localparam ST_RD          = 2;
   
   localparam OP_CLS             = 0;
   localparam OP_RET             = 1;
   localparam OP_SYS_ADDR        = 2;
   localparam OP_JP_ADDR         = 3;
   localparam OP_CALL_ADDR       = 4;
   localparam OP_SE_VX_BYTE      = 5;
   localparam OP_SNE_VX_BYTE     = 6;
   localparam OP_SE_VX_VY        = 7;
   localparam OP_LD_VX_BYTE      = 8;
   localparam OP_ADD_VX_BYTE     = 9;
   localparam OP_LD_VX_VY        = 10;
   localparam OP_OR_VX_VY        = 11;
   localparam OP_AND_VX_VY       = 12;
   localparam OP_XOR_VX_VY       = 13;
   localparam OP_ADD_VX_VY       = 14;
   localparam OP_SUB_VX_VY       = 15;
   localparam OP_SHR_VX_VY       = 16;
   localparam OP_SUBN_VX_VY      = 17;
   localparam OP_SHL_VX_VY       = 18;
   localparam OP_SNE_VX_VY       = 19;
   localparam OP_LD_I_ADDR       = 20;
   localparam OP_JP_V0_ADDR      = 21;   
   localparam OP_RND_VX_BYTE     = 22;
   localparam OP_DRW_VX_VY_NIB   = 23;
   localparam OP_SKP_VX          = 24;
   localparam OP_SKNP_VX         = 25;
   localparam OP_LD_VX_DT        = 26;
   localparam OP_LD_VX_K         = 27;
   localparam OP_LD_DT_VX        = 28;
   localparam OP_LD_ST_VX        = 29;
   localparam OP_ADD_I_VX        = 30;
   localparam OP_LD_F_VX         = 31;
   localparam OP_LD_B_VX         = 32;
   localparam OP_LD_I_VX         = 33;
   localparam OP_LD_VX_I         = 34;
   
   reg [10 : 0] 			       state = ST_IDLE;
   reg [5 : 0] 				       opcode = OP_CLS;

   reg [ADDR_WIDTH - 1 : 0] 		       _raddr = 512;
   reg [7 : 0] 				       q;
   reg [15 : 0] 			       word;
   
   wire [7 : 0] 			       word_u, word_l;
   
   assign raddr = _raddr;
   assign word_u = word[15 : 8];
   assign word_l = word[7 : 0];
   
   always @ (posedge clk)
     begin
	if (state == ST_OP)
	  begin
	     word[15 : 8] <= d;
	  end
	if (state == ST_RD)
	  begin
	     word[7 : 0] <= d;
	  end
     end
   
   always @ (posedge clk)
     begin
	case (state)
	  ST_IDLE:
	    begin
	       state <= ST_OP;
	    end
	  
	  ST_OP:
	    begin
	       state <= ST_RD;
	    end
	  
	  ST_RD:
	    begin
	       state <= ST_IDLE;
	    end
	endcase
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if (state == ST_OP)
	  begin
	     _raddr <= _raddr + 1;
	  end
     end
   
   
   always @ (posedge clk)
     begin
	
	if (word == `C8_CLS)
	  begin
	     opcode <= OP_CLS;
	  end
	
     end    
endmodule // interpreter
