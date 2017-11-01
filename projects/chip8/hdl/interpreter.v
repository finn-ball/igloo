`include "chip8.vh"

module interpreter(
		   input 	  clk,
		   input [7 : 0]  rx_i,
		   input 	  rx_i_v,
		   output 	  vs,
		   output 	  hs,
		   output [3 : 0] blue,
		   output [3 : 0] red,
		   output [3 : 0] green
		   );
   
   localparam ST_IDLE        = 0;
   localparam ST_RD_L        = 1;
   localparam ST_RD_U        = 2;
   localparam ST_DRAW        = 3;
   localparam ST_OP          = 4;
   
   localparam OP_SYS            = 0;
   localparam OP_JP_ADDR        = 1;
   localparam OP_CALL_ADDR      = 2;
   localparam OP_SE_VX_BYTE     = 3;
   localparam OP_SNE_VX_BYTE    = 4;
   localparam OP_SE_VX_VY       = 5;
   localparam OP_LD_VX_BYTE     = 6;
   localparam OP_ADD_VX_BYTE    = 7;
   localparam OP_VX_VY          = 8;
   localparam OP_SNE_VX_VY      = 9;
   localparam OP_LD_I_ADDR      = 10;
   localparam OP_JP_V0_ADDR     = 11;
   localparam OP_RND_VX_BYTE    = 12;
   localparam OP_DRW_VX_VY_NIB  = 13;
   localparam OP_SKP_VX         = 14;
   localparam OP_LD_VX          = 15;
   
   localparam DATA_WIDTH = 8;
   localparam ADDR_WIDTH = 12;
   
   reg [3 : 0] 			  state = ST_IDLE;
   reg [3 : 0] 			  opcode = OP_SYS;
   
   reg [15 : 0] 		  I = 0;
   
   wire [DATA_WIDTH - 1 : 0] 	  d, mem_q;
   wire [ADDR_WIDTH - 1 : 0] 	  waddr, raddr;
   wire 			  we, re;
   reg [ADDR_WIDTH - 1 : 0] 	  _raddr = 512;
   
   localparam PIPE_LENGTH = 5;
   
   reg [DATA_WIDTH - 1 : 0] 	  mem_q_pipe [PIPE_LENGTH - 1 : 0];
   reg [10 : 0] 		  state_pipe [PIPE_LENGTH - 1 : 0];
   reg [10 : 0] 		  opcode_pipe [PIPE_LENGTH - 1 : 0];
   reg [V_DATA_WIDTH - 1 : 0] 	  v_q_pipe [PIPE_LENGTH - 1 : 0];
   reg [15 : 0] 		  I_pipe [PIPE_LENGTH - 1 : 0];
   
   localparam V_ADDR_WIDTH = 4;
   localparam V_DATA_WIDTH = 8;
   
   reg 				  v_we = 0, v_re = 0;
   reg [V_ADDR_WIDTH - 1 : 0] 	  v_waddr = 0, v_raddr = 0;
   reg [V_DATA_WIDTH - 1 : 0] 	  v_d = 0, v_q = 0;
   
   wire 			  _v_we, _v_re;
   wire [V_ADDR_WIDTH - 1 : 0] 	  _v_waddr, _v_raddr;
   wire [V_DATA_WIDTH - 1 : 0] 	  _v_d, _v_q;
   
   wire 			  vs_valid, hs_valid;

   wire [11 : 0] mem_raddr;
   
   wire 	 draw_busy;
   wire [10 : 0] vram_start_pix;
   wire [3 : 0]  vram_nibbles;
   reg 		 draw_en = 0;
   wire 	 draw_col;

   reg [15 : 0]  pc = 0;
   reg [7 : 0] 	 sp = 0;
   reg [7 : 0] 	 dt = 0;
   
   assign raddr = state == ST_DRAW ? mem_raddr :  _raddr;

   assign red = hs_valid & vs_valid ? 4'b1111 : 0 ;
   assign blue = hs_valid & vs_valid ? 4'b1111 : 0 ;
   assign green = hs_valid & vs_valid ? 4'b1111 : 0;

   always @(mem_q, state, opcode, v_q, I)
     begin
	mem_q_pipe[0] <= mem_q;
	state_pipe[0] <= state;
	opcode_pipe[0] <= opcode;
	v_q_pipe[0] <= v_q;
	I_pipe[0] <= I;
     end
   
   genvar 				       i;
   generate
      for (i = 1; i < PIPE_LENGTH; i = i + 1)
	begin
	   always @ (posedge clk)
	     begin
		mem_q_pipe[i] <= mem_q_pipe[i - 1];
		state_pipe[i] <= state_pipe[i - 1];
		opcode_pipe[i] <= opcode_pipe[i - 1];
		v_q_pipe[i] <= v_q_pipe[i - 1];
		I_pipe[i] <= I_pipe[i - 1];
	     end
	end      
   endgenerate
   
   always @ (posedge clk)
     begin
	case (state)
	  ST_IDLE:
	    begin
	       state <= ST_RD_L;
	    end
	  
	  ST_RD_L:
	    begin
	       state <= ST_RD_U;
	    end
	  
	  ST_RD_U:
	    begin
	       if (opcode_pipe[0] == OP_DRW_VX_VY_NIB)
		 begin
		    state <= ST_DRAW;
		 end
	       else
		 begin
		    state <= ST_RD_L;
		 end
	    end // case: ST_RD_U

	  ST_OP:
	    begin
	       state <= ST_RD_L;
	    end
	  
	  ST_DRAW:
	    begin
	       if (~draw_busy & (mem_q_pipe[1][7 : 4] != 4'hD) & (mem_q_pipe[2][7 : 4] != 4'hD ))
		 begin
		    state <= ST_RD_L;
		 end
	    end
	endcase // case (state)
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if ( state == ST_RD_L || (state == ST_RD_U) )
	  begin
	     _raddr <= _raddr + 1;
	  end
     end
   
   assign _v_we = v_we;

   always @ (state_pipe[1], mem_q_pipe[0])
     begin
	if (state_pipe[1] == ST_RD_L)
	  begin
	     
	     case(mem_q_pipe[0][7 : 4])

	       4'h0:
		 begin
		    opcode <= OP_SYS;
		 end

	       4'h1:
		 begin
		    opcode <= OP_JP_ADDR;
		 end
	       
	       4'h2:
		 begin
		    opcode <= OP_CALL_ADDR;
		 end

	       4'h3:
		 begin
		    opcode <= OP_SE_VX_BYTE;
		 end

	       4'h4:
		 begin
		    opcode <= OP_SNE_VX_BYTE;
		 end

	       4'h5:
		 begin
		    opcode <= OP_SE_VX_VY;
		 end
	       
	       4'h6:
		 begin
		    opcode <= OP_LD_VX_BYTE;
		 end

	       4'h7:
		 begin
		    opcode <= OP_ADD_VX_BYTE;
		 end

	       4'h8:
		 begin
		    opcode <= OP_VX_VY;
		 end

	       4'h9:
		 begin
		    opcode <= OP_SNE_VX_VY;
		 end
	     
	       4'hA:
		 begin
		    opcode <= OP_LD_I_ADDR;
		 end

	       4'hB:
		 begin
		    opcode <= OP_JP_V0_ADDR;
		 end

	       4'hC:
		 begin
		    opcode <= OP_RND_VX_BYTE;
		 end
	       
	       4'hD:
		 begin
		    opcode <= OP_DRW_VX_VY_NIB;
		 end
	       
	       4'hE:
		 begin
		    opcode <= OP_SKP_VX;
		 end
	       
	       4'hF:
		 begin
		    opcode <= OP_LD_VX;
		 end
	       
	     endcase // case (mem_q_pipe[0][7 : 4])
	     
	  end
     end
   
   always @ (posedge clk)
     begin
	
	if (state_pipe[1] == ST_RD_L)
	  begin

	     case(opcode_pipe[0])
	       OP_CALL_ADDR:
		 begin
		    pc[11 : 8] <= mem_q_pipe[0][3 : 0];
		    sp <= sp + 1;
		 end
	       
	       OP_SE_VX_BYTE:
		 begin
		    v_raddr <= mem_q_pipe[0][3 : 0];
		 end

	       OP_SNE_VX_BYTE:
		 begin
		    v_raddr <= mem_q_pipe[0][3 : 0];
		 end
	       
	       OP_SE_VX_VY:
		 begin
		    v_raddr <= mem_q_pipe[0][3 : 0];
		 end
	       
	       OP_LD_VX_BYTE:
		 begin
		    v_waddr <= mem_q_pipe[0][3 : 0];
		 end
	       	       
	       OP_LD_I_ADDR:
		 begin
		    
		 end
	       
	       OP_DRW_VX_VY_NIB:
		 begin
		    v_raddr <= mem_q_pipe[0][3 : 0];
		 end
	       
	       OP_LD_VX:
		 begin
		    v_raddr <= mem_q_pipe[0][3 : 0];
		 end
	     endcase // case (mem_q_pipe[0][7 : 4])
	     
	  end // if (state_pipe[1] == ST_RD_L)
	
	else if (state_pipe[1] == ST_RD_U)
	  begin
	     case (opcode_pipe[1])
		  
	       OP_CALL_ADDR:
		 begin
		    pc[7 : 0] <= mem_q_pipe[0][7 : 4];
		 end

	       OP_SE_VX_BYTE:
		 begin
		    if (v_q == mem_q_pipe[0][7 : 0])
		      begin
			 pc <= pc + 2;
		      end
		 end

	       OP_SNE_VX_BYTE:
		 begin
		    if (v_q != mem_q_pipe[0][7 : 0])
		      begin
			 pc <= pc + 2;
		      end
		 end
	       
	       OP_LD_VX_BYTE:
		 begin
		    v_d <= mem_q_pipe[0];
		 end
	       
	       OP_SE_VX_VY:
		 begin
		    v_raddr <= mem_q_pipe[0][3 : 0];//
		 end

	       OP_LD_I_ADDR:
		 begin
		    I[11 : 0] <= { {mem_q_pipe[1][3 : 0]}, mem_q_pipe[0][7 : 0] };
		 end
	       
	       OP_DRW_VX_VY_NIB:
		 begin
		    v_raddr <= mem_q_pipe[0][7  : 4];
		 end

	       OP_LD_VX:
		 begin
		    if (mem_q_pipe[0] == 8'h07)
		      begin
			 v_d <= dt;
			 v_waddr <= mem_q_pipe[1][3 : 0];
		      end
		    if (mem_q_pipe[0] == 8'h15)
		      begin
			 dt <= v_q;
		      end
		 end 
	     
	     endcase // case (opcode_pipe[0])
	     
	  end // if (state_pipe[1] == ST_RD_U)

	else if (state_pipe[1] == ST_DRAW)
	  begin
	     v_waddr <= 4'hF;
	     v_d <= draw_col;
	  end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if (state_pipe[1] == ST_RD_U)
	  begin
	     if (opcode_pipe[1] == OP_LD_VX_BYTE)
	       begin
		  v_we <= 1;
	       end
	     if (opcode_pipe[1] == OP_LD_VX)
	       begin
		  v_we <= mem_q_pipe[0] == 8'h07;
	       end
	  end // if (state_pipe[1] == ST_RD_U)

	if (state_pipe[1] == ST_RD_L)
	  begin
	     if (opcode_pipe[1] == OP_SE_VX_VY)
	       begin
		  if (v_q_pipe[0] == v_q_pipe[1])
		    begin
		       pc <= pc + 2;
		    end
	       end
	  end
	
	
	if (state_pipe[1] == ST_DRAW)
	  begin
	     v_we <= 1;
	  end
	
	else
	  begin
	     v_we <= 0;
	  end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if  (dt > 0)
	  begin
	     dt <= dt - 1; // make 60Hz
	  end
     end

   always @ (posedge clk)
     begin
	draw_en <= state_pipe[2] == ST_RD_U & opcode_pipe[2] == OP_DRW_VX_VY_NIB;
     end

   assign vram_start_pix[5 : 0] = v_q_pipe[1][5 : 0]; 
   assign vram_start_pix[10 : 6] = v_q_pipe[0][4 : 0];
   assign vram_nibbles[3 : 0] = mem_q_pipe[2][3 : 0]; 
   
   mem#(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH),
	.INIT(1),
	.SPRITE_FILE_NAME("projects/chip8/cfg/sprite.hex"),
	.SPRITE_FILE_WIDTH(80),
	.PROGRAM_FILE_NAME("projects/chip8/cfg/pong.hex"),
	.PROGRAM_FILE_WIDTH(256)
	) mem (
	       .clk(clk),
	       .we(we),
	       .waddr(waddr),
	       .d(d),
	       .re(1'b1),
	       .raddr(raddr),
	       .q(mem_q)
	       );
   
   ram#(
	.ADDR_WIDTH(V_ADDR_WIDTH),
	.DATA_WIDTH(V_DATA_WIDTH)
	) vx (
	      .clk(clk),
	      .we(_v_we),
	      .waddr(v_waddr),
	      .d(v_d),
	      .re(1'b1),
	      .raddr(v_raddr),
	      .q(_v_q)
	      );
   
   always @ (_v_q)
     begin
	v_q <= _v_q;
     end
   
   draw draw(
	     .clk(clk),
	     .en(draw_en),
	     .I(I),
	     .start_pix(vram_start_pix),
	     .start_nibbles(vram_nibbles),
	     .mem_raddr(mem_raddr),
	     .mem_d(mem_q),
	     .busy(draw_busy),
	     .col(draw_col),
	     .hs(hs),
	     .hs_valid(hs_valid),
	     .vs(vs),
	     .vs_valid(vs_valid)
	     );
   
endmodule // interpreter
