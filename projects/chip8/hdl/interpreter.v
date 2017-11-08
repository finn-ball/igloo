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
   localparam ST_OP          = 3;
   localparam ST_DRAW        = 4;

   localparam ST_OP_IDLE      = 0;
   localparam ST_OP_LD_B_VX   = 1;
   localparam ST_OP_LD_VX_I   = 2;
   localparam ST_OP_LD_F_VX   = 3;
   
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
   reg [3 : 0] 			  state_op = ST_OP_IDLE;
   
   reg [15 : 0] 		  I = 0;
   
   wire [DATA_WIDTH - 1 : 0] 	  mem_q;
   reg [DATA_WIDTH - 1 : 0] 	  mem_d = 0;
   
   reg [ADDR_WIDTH - 1 : 0] 	  mem_raddr;
   reg [ADDR_WIDTH - 1 : 0] 	  waddr = 0;
   wire 			  re;
   reg 				  we = 0;
   reg [ADDR_WIDTH - 1 : 0] 	  pc = 512;
   
   localparam PIPE_LENGTH = 5;
   
   reg [DATA_WIDTH - 1 : 0] 	  mem_q_pipe [PIPE_LENGTH - 1 : 0];
   reg [10 : 0] 		  state_pipe [PIPE_LENGTH - 1 : 0];
   reg [10 : 0] 		  opcode_pipe [PIPE_LENGTH - 1 : 0];
   reg [V_DATA_WIDTH - 1 : 0] 	  v_q_pipe [PIPE_LENGTH - 1 : 0];
   reg [15 : 0] 		  I_pipe [PIPE_LENGTH - 1 : 0];
   reg [15 : 0] 		  dec_to_bcd_q_pipe [PIPE_LENGTH - 1 : 0];
   
   localparam V_ADDR_WIDTH = 4;
   localparam V_DATA_WIDTH = 8;
   
   reg 				  v_we = 0, v_re = 0;
   reg [V_ADDR_WIDTH - 1 : 0] 	  v_waddr = 0, v_raddr = 0;
   reg [V_DATA_WIDTH - 1 : 0] 	  v_d = 0, v_q = 0;
   
   wire 			  _v_we, _v_re;
   wire [V_ADDR_WIDTH - 1 : 0] 	  _v_waddr, _v_raddr;
   wire [V_DATA_WIDTH - 1 : 0] 	  _v_d, _v_q;
   
   wire [ADDR_WIDTH - 1 : 0] 	  draw_raddr;
   
   wire 	 draw_busy;
   wire [10 : 0] vram_start_pix;
   wire [3 : 0]  vram_nibbles;
   reg 		 draw_en = 0;
   wire 	 draw_col;
   wire 	 draw_out;
   
   reg [15 : 0]  sp = 0;
   reg [7 : 0] 	 dt = 0;

   reg [3 : 0] 	 ctr_op = 0;
   
   reg [7 : 0] 	 dec_to_bcd_raddr;
   wire [11 : 0] dec_to_bcd_q;

   reg [ADDR_WIDTH - 1 : 0] dump_raddr = 0;

   wire [7 : 0] 	    sprite_location_q;
   
   
   assign red = draw_out ? 4'b1111 : 0 ;
   assign blue = draw_out ? 4'b1111 : 0 ;
   assign green = draw_out ? 4'b1111 : 0;
   
   always @ (state, state_op, draw_raddr, pc, dump_raddr)
     begin
	if (state == ST_DRAW)
	  begin
	     mem_raddr <= draw_raddr;
	  end
	
	else if (state_op == ST_OP_LD_VX_I)
	  begin
	     mem_raddr <= dump_raddr;
	  end
	
	else
	  begin
	     mem_raddr <= pc;
	  end   
     end
   
   always @(mem_q, state, opcode, v_q, I, dec_to_bcd_q)
     begin
	mem_q_pipe[0] <= mem_q;
	state_pipe[0] <= state;
	opcode_pipe[0] <= opcode;
	v_q_pipe[0] <= v_q;
	I_pipe[0] <= I;
	dec_to_bcd_q_pipe[0] <= dec_to_bcd_q;
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
		dec_to_bcd_q_pipe[i] <= dec_to_bcd_q_pipe[i - 1];
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
		    state <= ST_OP;
		 end
	    end

	  ST_OP:
	    begin
	       if (ctr_op == 0)
		 begin
		    state <= ST_RD_L;
		 end
	    end // case: ST_OP
	  
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
	if (state_pipe[0] == ST_RD_U)
	  begin
	     if (opcode_pipe[1] == OP_CALL_ADDR)
	       begin
		  ctr_op <= 1;
	       end
	     else if (opcode_pipe[1] == OP_LD_VX)
	       begin
		  ctr_op <= 1;
	       end
	  end // if (state_pipe[0] == ST_RD_U)
	else if (state_pipe[1] == ST_RD_U)
	  begin
	     if (opcode_pipe[1] == OP_LD_VX)
	       begin
		  if (mem_q_pipe[0] == 8'h33)
		    begin
		       ctr_op <= 4;
		    end
		  else if (mem_q_pipe[0] == 8'h65)
		    begin
		       ctr_op <= mem_q_pipe[2][3 : 0] + 2;
		    end
	       end 
	  end
	else if (ctr_op > 0)
	  begin
	     ctr_op <= ctr_op - 1;
	  end
     end
   
   always @ (posedge clk)
     begin

	if ( ( state_pipe[0] == ST_RD_L | (state_pipe[0] == ST_RD_U)) )
	  begin
	     pc <= pc + 1;
	  end
	
	else if (state_pipe[1] == ST_RD_U)
	  
	  begin
	     case (opcode_pipe[1])

	       OP_JP_ADDR:
		 begin
		    if (state_pipe[0] == ST_OP)
		      begin
			 pc[11 : 8] <= mem_q_pipe[1][3 : 0];
			 pc[7 : 0] <= mem_q_pipe[0];
		      end		    
		 end
	       
	       OP_CALL_ADDR: // incr sp
		 begin
		    if (state_pipe[0] == ST_OP)
		      begin
			 pc[11 : 8] <= mem_q_pipe[1][3 : 0];
			 pc[7 : 0] <= mem_q_pipe[0];
		      end		    
		 end // case: OP_CALL_ADDR
	       
	       OP_SE_VX_BYTE:
		 begin
		    if (state_pipe[0] == ST_OP)
		      begin
			 if (v_q == mem_q_pipe[0][7 : 0])
			   begin
			      pc <= pc + 2;
			   end
		      end		    		    
		 end
	       
	       OP_SNE_VX_BYTE:
		 begin
		    if (state_pipe[0] == ST_OP)
		      begin
			 if (v_q != mem_q_pipe[0][7 : 0])
			   begin
			      pc <= pc + 2;
			   end
		      end
		 end
	       
	       OP_SE_VX_VY: // check
		 begin
		    if (state_pipe[0] == ST_OP)
		      begin
			 if(v_q_pipe[0] == v_q_pipe[1])
			   begin
			      pc <= pc + 2;
			   end
		      end
		 end
	       
	     endcase // case (opcode_pipe[2])
	  end // else: !if( ( state_pipe[0] == ST_RD_L ) )
	
     end // if (state_pipe[1] == ST_RD_U)   
   
   assign _v_we = v_we;

   always @ (mem_q_pipe[0])
     begin
	case(mem_q_pipe[0][7 : 4])
	  
	  4'h0:
	    opcode <= OP_SYS;
	  
	  4'h1:
	    opcode <= OP_JP_ADDR;
	  
	  4'h2:
	    opcode <= OP_CALL_ADDR;
	  
	  4'h3:
	    opcode <= OP_SE_VX_BYTE;
	  
	  4'h4:
	    opcode <= OP_SNE_VX_BYTE;
	  
	  4'h5:
	    opcode <= OP_SE_VX_VY;
	  
	  4'h6:
	    opcode <= OP_LD_VX_BYTE;
	  
	  4'h7:
	    opcode <= OP_ADD_VX_BYTE;
	  
	  4'h8:
	    opcode <= OP_VX_VY;
	  
	  4'h9:
	    opcode <= OP_SNE_VX_VY;
	  
	  4'hA:
	    opcode <= OP_LD_I_ADDR;
	  
	  4'hB:
	    opcode <= OP_JP_V0_ADDR;
	  
	  4'hC:
	    opcode <= OP_RND_VX_BYTE;
	  
	  4'hD:
	    opcode <= OP_DRW_VX_VY_NIB;
	  
	  4'hE:
	    opcode <= OP_SKP_VX;
	  
	  4'hF:
	    opcode <= OP_LD_VX;
	  
	endcase // case (mem_q_pipe[0][7 : 4])
     end
   
   always @ (posedge clk)
     begin

	if (state_pipe[1] == ST_DRAW)
	  begin
	     v_waddr <= 4'hF;
	     v_d <= draw_col;
	  end
	
	else if (state_pipe[1] == ST_RD_L)
	  begin
	     
	     case(opcode_pipe[0])
	       OP_CALL_ADDR:
		 sp <= sp + 1;
	       
	       OP_SE_VX_BYTE:
		 v_raddr <= mem_q_pipe[0][3 : 0];
	       
	       OP_SNE_VX_BYTE:
		 v_raddr <= mem_q_pipe[0][3 : 0];
	       
	       OP_SE_VX_VY:
		 v_raddr <= mem_q_pipe[0][3 : 0];
	       
	       OP_DRW_VX_VY_NIB:
		 v_raddr <= mem_q_pipe[0][3 : 0];

	       OP_ADD_VX_BYTE:
		 v_raddr <= mem_q_pipe[0][3 : 0];
	       
	       OP_LD_VX:
		 v_raddr <= mem_q_pipe[0][3 : 0];
	       
	     endcase // case (opcode_pipe[0])
	  end // if (state_pipe[1] == ST_RD_L)
	
	else if (state_pipe[1] == ST_RD_U)
	  begin
	     case(opcode_pipe[1])
	       
	       OP_SE_VX_VY:
		 v_raddr <= mem_q_pipe[0][3 : 0];
	       
	       OP_LD_VX_BYTE:
		 begin
		    v_waddr <= mem_q_pipe[1][3 : 0];
		    v_d <= mem_q_pipe[0];
		 end

	       OP_ADD_VX_BYTE:
		    v_waddr <= mem_q_pipe[0][3 : 0];
	       
	       OP_DRW_VX_VY_NIB:
		 v_raddr <= mem_q_pipe[0][7  : 4];
	       
	       OP_LD_I_ADDR:
		 I[11 : 0] <= { {mem_q_pipe[1][3 : 0]}, mem_q_pipe[0][7 : 0] };

	       OP_LD_VX:
		 begin
		    if (mem_q_pipe[0] == 8'h07)
		      begin
			 v_d <= dt;
			 v_waddr <= mem_q_pipe[1][3 : 0];
		      end
		    else if (mem_q_pipe[0] == 8'h1E)
		      begin
			 I <= (I + v_q_pipe[0]);
		      end
		    else if (mem_q_pipe[0] == 8'h29)
		      begin
		      end
		    else if (mem_q_pipe[0] == 8'h33)
		      begin
			 waddr <= I[11 : 0];
		      end
		    else if (mem_q_pipe[0] == 8'h65)
		      begin
			 v_waddr <= 0;
			 dump_raddr <= I[ADDR_WIDTH - 1 : 0];
		      end
		 end
	     endcase // case (opcode_pipe[0])
	     
	  end // if (state_pipe[1] == ST_RD_U)

	else if ( (state_pipe[2] == ST_RD_U) & (opcode_pipe[2] == OP_ADD_VX_BYTE) )
	  begin
	     v_d <= v_q_pipe[0] + mem_q_pipe[1];
	  end
	
	else
	  begin
	     
	     case(state_op)

	       ST_OP_LD_B_VX:
		 begin
		    if (ctr_op == 2)
		      begin
			 mem_d[3 : 0] <= dec_to_bcd_q[3 : 0];
		      end
		    else if (ctr_op == 1)
		      begin
			 mem_d[3 : 0] <= dec_to_bcd_q[7 : 4];
		      end
		    else if (ctr_op == 0)
		      begin
			 mem_d[3 : 0] <= dec_to_bcd_q[11 : 8];
		      end
		    
		    if (ctr_op < 3)
		      begin
			 waddr <= waddr + 1;
		      end
		 end // case: ST_OP_LD_B_VX

	       ST_OP_LD_VX_I:
		 begin
		    v_waddr <= v_waddr + v_we;
		    v_d <= mem_q_pipe[0];
		    dump_raddr <= dump_raddr + 1;
		 end

	       ST_OP_LD_F_VX:
		 begin
		    I[7 : 0] <= sprite_location_q;
		    I[15 : 8] <= 0;
		 end
	       
	     endcase // case (state_op)
	  end // else: !if(state_pipe[1] == ST_RD_U)
	
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	if (state_op == ST_OP_LD_B_VX)
	  begin
	     if (ctr_op < 4)
	       begin
		  we <= 1;
	       end
	  end
	else
	  begin
	     we <= 0;
	  end
     end

   always @ (posedge clk)
     begin
	case(state_op)
	  
	  ST_OP_IDLE:
	    begin
	       if ( (state_pipe[1] == ST_RD_U) & (opcode_pipe[1] == OP_LD_VX))
		 begin
		    if (mem_q_pipe[0] == 8'h33)
		      begin
			 state_op <= ST_OP_LD_B_VX;
		      end
		    else if (mem_q_pipe[0] == 8'h29)
		      begin
			 state_op <= ST_OP_LD_F_VX;
		      end
		    else if (mem_q_pipe[0] == 8'h65)
		      begin
			 state_op <= ST_OP_LD_VX_I;
		      end
		 end
	    end

	  ST_OP_LD_B_VX:
	    begin
	       if (ctr_op == 1)
		 begin
		    state_op <= ST_OP_IDLE;
		 end
	    end

	  ST_OP_LD_F_VX:
	    state_op <= ST_OP_IDLE;

	  ST_OP_LD_VX_I:
	    begin
	       if (ctr_op == 1)
		 begin
		    state_op <= ST_OP_IDLE;
		 end
	    end
	  
	endcase // case (state_op)
     end
   
   always @ (posedge clk)
     begin
	if (state_pipe[1] == ST_RD_U)
	  begin
	     case(opcode_pipe[1])
	       
	       OP_LD_VX_BYTE:
		  v_we <= 1;
	       
	       OP_LD_VX:
		  v_we <= mem_q_pipe[0] == 8'h07;

	       default:
		 v_we <= 0;
	       
	     endcase // case (opcode_pipe[1])
	  end // if (state_pipe[1] == ST_RD_U)
	
	else if (state_pipe[1] == ST_DRAW)
	  begin
	     v_we <= 1;
	  end

	else if ( (state_pipe[2] == ST_RD_U) & (opcode_pipe[2] == OP_ADD_VX_BYTE ) )
	  begin
	     v_we <= 1;
	  end
	
	else
	  case(state_op)

	    ST_OP_LD_VX_I:
	      begin
		 if (state_pipe[2] != ST_RD_U)
		   begin
		      v_we <= 1;
		   end
	      end

	    default:
	      v_we <= 0;
	    
	  endcase
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if ( (mem_q_pipe[0] == 8'h15) & (opcode_pipe[1] == OP_LD_VX) & (state_pipe[1] == ST_RD_U ) )
	  begin
	     dt <= v_q_pipe[0];
	  end
	else if  (dt > 0)
	  begin
	     dt <= dt - 1; // make 60Hz
	  end
     end

   always @ (posedge clk)
     begin
	if ( (state_pipe[2] == ST_RD_U) & (opcode_pipe[2] == OP_DRW_VX_VY_NIB))
	  begin
	     draw_en <= 1;
	  end
	else
	  begin
	     draw_en <= 0;
	  end
     end // always @ (posedge clk)
   
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
	       .d(mem_d),
	       .re(1'b1),
	       .raddr(mem_raddr),
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
   
   always @ (posedge clk)
     begin
	dec_to_bcd_raddr <= v_q_pipe[0];
     end

   rom#(
	.ADDR_WIDTH(8),
	.DATA_WIDTH(12),
	.INIT(1),
	.FILE_NAME("projects/chip8/cfg/dec_to_bcd.hex")
	) dec_to_bcd (
		      .clk(clk),
		      .raddr(dec_to_bcd_raddr),
		      .q(dec_to_bcd_q)
		      );
   
   rom#(
	.ADDR_WIDTH(4),
	.DATA_WIDTH(8),
	.INIT(1),
	.FILE_NAME("projects/chip8/cfg/sprite_location.hex")
	) sprite_location (
			   .clk(clk),
			   .raddr(v_q_pipe[1][3 : 0]),
			   .q(sprite_location_q)
			   );
   
   draw draw(
	     .clk(clk),
	     .en(draw_en),
	     .I(I),
	     .start_pix(vram_start_pix),
	     .start_nibbles(vram_nibbles),
	     .mem_raddr(draw_raddr),
	     .mem_d(mem_q),
	     .busy(draw_busy),
	     .col(draw_col),
	     .draw_out(draw_out),
	     .hs_o(hs),
	     .vs_o(vs)
	     );
   
endmodule // interpreter
