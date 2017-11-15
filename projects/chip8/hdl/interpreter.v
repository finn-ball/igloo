`include "chip8.vh"

module interpreter(
		   input 	  clk,
		   input [7 : 0]  rx_i,
		   input 	  rx_i_v,
		   output 	  vs,
		   output 	  hs,
		   output         draw_o
		   );
   
   localparam ST_IDLE        = 0;
   localparam ST_RD_L        = 1;
   localparam ST_RD_U        = 2;
   localparam ST_OP          = 3;
   localparam ST_DRAW        = 4;
   
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

   localparam ST_OP_IDLE       = 0;
      
   localparam ST_OP_LD_VX_VY   = 1;
   localparam ST_OP_OR_VX_VY   = 2;
   localparam ST_OP_AND_VX_VY  = 3;
   localparam ST_OP_XOR_VX_VY  = 4;
   localparam ST_OP_ADD_VX_VY  = 5;
   localparam ST_OP_SUB_VX_VY  = 6;
   localparam ST_OP_SHR_VX_VY  = 7;
   localparam ST_OP_SUBN_VX_VY = 8;
   localparam ST_OP_SHL_VX_VY  = 9;
   
   localparam ST_OP_LD_VX_DT   = 10;
   localparam ST_OP_LD_VX_K    = 11;
   localparam ST_OP_LD_DT_VX   = 12;
   localparam ST_OP_LD_ST_VX   = 13;
   localparam ST_OP_ADD_I_VX   = 14;
   localparam ST_OP_LD_F_VX    = 15;
   localparam ST_OP_LD_B_VX    = 16;
   localparam ST_OP_LD_I_VX    = 17;
   localparam ST_OP_LD_VX_I    = 18;
   
   localparam DATA_WIDTH = 8;
   localparam ADDR_WIDTH = 12;
   
   reg [3 : 0] 			  state = ST_IDLE;
   reg [3 : 0] 			  opcode = OP_SYS;
   reg [4 : 0] 			  state_op = ST_OP_IDLE;

   reg [PIPE_LENGTH - 1 : 0] 	  op_en_pipe;
   
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
   reg [3 : 0] 			  state_pipe [PIPE_LENGTH - 1 : 0];
   reg [3 : 0] 			  opcode_pipe [PIPE_LENGTH - 1 : 0];
   reg [V_DATA_WIDTH - 1 : 0] 	  v_q_pipe [PIPE_LENGTH - 1 : 0];
   reg [15 : 0] 		  I_pipe [PIPE_LENGTH - 1 : 0];
   reg [15 : 0] 		  dec_to_bcd_q_pipe [PIPE_LENGTH - 1 : 0];
   reg [ADDR_WIDTH - 1 : 0] 	  pc_pipe [PIPE_LENGTH - 1 : 0];
   
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
   reg 		 draw_en = 0, cls_en = 0;
   wire 	 draw_col;

   localparam SP_ADDR_WIDTH = 4;
   localparam SP_DATA_WIDTH = ADDR_WIDTH;
   reg 		 sp_we = 0;
   reg [SP_DATA_WIDTH - 1 : 0] sp_d = 0;
   wire [SP_DATA_WIDTH - 1 : 0] sp_q;
   reg [SP_ADDR_WIDTH - 1 : 0] 	sp_waddr = 0, sp_raddr;
   
   reg [7 : 0] 	 dt = 0;

   reg [3 : 0] 	 ctr_op = 0;
   
   reg [7 : 0] 	 dec_to_bcd_raddr;
   wire [11 : 0] dec_to_bcd_q;

   reg [ADDR_WIDTH - 1 : 0] dump_raddr = 0;

   wire [7 : 0] 	    sprite_location_q;   

   reg [8 : 0] 		    carry = 0; 		    
      
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
   
   always @(mem_q, state, opcode, v_q, I, dec_to_bcd_q, pc)
     begin
	mem_q_pipe[0] <= mem_q;
	state_pipe[0] <= state;
	opcode_pipe[0] <= opcode;
	v_q_pipe[0] <= v_q;
	I_pipe[0] <= I;
	dec_to_bcd_q_pipe[0] <= dec_to_bcd_q;
	pc_pipe[0] <= pc;
	op_en_pipe[0] <= (state == ST_RD_L);
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
		pc_pipe[i] <= pc_pipe[i - 1];
		op_en_pipe[i] <= op_en_pipe[i - 1];
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
	       if ( ~draw_busy & (ctr_op == 0) )
		 begin
		    state <= ST_OP;
		 end
	    end
	endcase // case (state)
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if (state_pipe[0] == ST_RD_U)
	  begin
	     case(opcode_pipe[1])
	       
	       OP_LD_VX_BYTE:
		 ctr_op <= 0;

	       OP_ADD_VX_BYTE:
		 ctr_op <= 0;

	       OP_RND_VX_BYTE:
		 ctr_op <= 0;

	       OP_SKP_VX:
		 ctr_op <= 0;

	       OP_JP_V0_ADDR:
		 ctr_op <= 0;
	       
	       default:
		 ctr_op <= 1;
	       
	     endcase // case (opcode_pipe[1])
	  end // if (state_pipe[0] == ST_RD_U)
	
	else if (state_pipe[1] == ST_RD_U)
	  begin
	     if (opcode_pipe[1] == OP_LD_VX)
	       begin
		  
		  case(mem_q_pipe[0])
		    
		    8'h07:
		      ctr_op <= 0;
		    
		    8'h15:
		      ctr_op <= 0;

		    8'h1E:
		      ctr_op <= 0;
		    
		    8'h33:
		      ctr_op <= 5;

		    8'h55:
		      ctr_op <= mem_q_pipe[2][3 : 0] + 1;
		    
		    8'h65:
		      ctr_op <= mem_q_pipe[2][3 : 0] + 2;
		    
		    default:
		      ctr_op <= 1;
		    
		  endcase
		  
	       end // if (opcode_pipe[1] == OP_LD_VX)
	     else if (opcode_pipe[1] == OP_VX_VY)
	       begin
		  case(mem_q_pipe[0][3: 0])
		    
		    4'h0:
		      ctr_op <= 1;
		    
		    4'h1:
		      ctr_op <= 1;
		    
		    4'h2:
		      ctr_op <= 1;
		    
		    4'h3:
		      ctr_op <= 1;
		    
		    4'h4:
		      ctr_op <= 2;
		    
		    4'h5:
		      ctr_op <= 2;
		    
		    4'h6:
		      ctr_op <= 2;
		    
		    4'h7:
		      ctr_op <= 2;
		    
		    4'hE:
		      ctr_op <= 2;
		    
		  endcase // case (mem_q_pipe[0][3: 0])
	       end // if (opcode_pipe[1] == OP_VX_VY)
	     else if (opcode_pipe[1] == OP_DRW_VX_VY_NIB)
	       begin
		  ctr_op <= 2;
	       end
	  end
	else if (state_op == ST_OP_LD_VX_K)
	  begin
	     ctr_op <= rx_i_v ? 0 : 1;
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
	       
	       OP_SYS:
		 begin
		    if (mem_q_pipe[0] == 8'hEE)
		      begin
			 pc <= sp_q;
		      end
		 end
	       
	       OP_JP_ADDR:
		 begin
		    pc[11 : 8] <= mem_q_pipe[1][3 : 0];
		    pc[7 : 0] <= mem_q_pipe[0];
		 end
	       
	       OP_CALL_ADDR:
		 begin
		    pc[11 : 8] <= mem_q_pipe[1][3 : 0];
		    pc[7 : 0] <= mem_q_pipe[0];
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
	       
	     endcase // case (opcode_pipe[1])
	  end // if (state_pipe[1] == ST_RD_U)
	
     end // always @ (posedge clk)
   
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
	     v_raddr <= mem_q_pipe[0][3 : 0];
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
	       
	       OP_SE_VX_VY:
		 begin
		    v_raddr <= mem_q_pipe[0][7 : 4];
		    v_waddr <= mem_q_pipe[1][3 : 0];
		 end

	       OP_VX_VY:
		 v_raddr <= mem_q_pipe[0][7 : 4];
	       
	       OP_RND_VX_BYTE:
		 begin
		    v_waddr <= mem_q_pipe[1][3 : 0];
		    v_d <= ctr_rnd & mem_q_pipe[0];
		 end
	       
	       OP_DRW_VX_VY_NIB:
		 v_raddr <= mem_q_pipe[0][7  : 4];
	       
	       OP_LD_I_ADDR:
		 I[11 : 0] <= { {mem_q_pipe[1][3 : 0]}, mem_q_pipe[0][7 : 0] };

	       OP_LD_VX:
		 begin
		    case(mem_q_pipe[0])
		      
		      8'h07:
			begin
			   v_d <= dt;
			   v_waddr <= mem_q_pipe[1][3 : 0];
			end
		      
		      8'h1E:
			I <= (I + v_q_pipe[0]);
		      
		      8'h33:
			waddr <= I[11 : 0];

		      8'h55:
			v_raddr <= 0;

		      8'h65:
			begin
			   v_waddr <= 0;
			   dump_raddr <= I[ADDR_WIDTH - 1 : 0];
			end
		      
		    endcase // case (mem_q_pipe[0])
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

	       ST_OP_LD_VX_VY:
		 begin
		    v_d <= v_q_pipe[0];
		    v_waddr <= mem_q_pipe[3][3 : 0];
		 end

	       ST_OP_OR_VX_VY:
		 begin
		    v_d <= v_q_pipe[0] | v_q_pipe[1];
		    v_waddr <= mem_q_pipe[3][3 : 0];
		 end

	       ST_OP_AND_VX_VY:
		 begin
		    v_d <= v_q_pipe[0] & v_q_pipe[1];
		    v_waddr <= mem_q_pipe[3][3 : 0];
		 end

	       ST_OP_XOR_VX_VY:
		 begin
		    v_d <= v_q_pipe[0] ^ v_q_pipe[1];
		    v_waddr <= mem_q_pipe[3][3 : 0];
		 end

	       ST_OP_ADD_VX_VY:
		 begin
		    case(ctr_op)
		      1:
			begin
			   v_d <= v_q_pipe[0] + v_q_pipe[1];
			   carry <= v_q_pipe[0] + v_q_pipe[1];
			   v_waddr <= mem_q_pipe[3][3 : 0];
			end

		      0:
			begin
			   v_waddr <= 4'hF;
			   v_d <= carry[8];	
			end
		      endcase
		 end // case: ST_OP_ADD_VX_VY
	       
	       ST_OP_SUB_VX_VY:
		 begin
		    case(ctr_op)
		      1:
			begin
			   v_d <= v_q_pipe[1] - v_q_pipe[0];
			   carry <= v_q_pipe[1] >  v_q_pipe[0];
			   v_waddr <= mem_q_pipe[3][3 : 0];
			end
		      
		      0:
			begin
			   v_waddr <= 4'hF;
			   v_d <= carry[8];	
			end
		    endcase
		 end
	       
	       ST_OP_SHR_VX_VY:
		 begin
		    case(ctr_op)
		      1:
			begin
			   v_d <= v_q_pipe[1] >> 1;
			   v_waddr <= mem_q_pipe[3][3 : 0];
			end
		      
		      0:
			begin
			   v_waddr <= 4'hF;
			   v_d <= v_q_pipe[2][0];	
			end
		    endcase
		 end
	       
	       ST_OP_SUBN_VX_VY:
		 begin
		    case(ctr_op)
		      1:
			begin
			   v_d <= v_q_pipe[0] - v_q_pipe[1];
			   carry <= v_q_pipe[0] >  v_q_pipe[1];
			   v_waddr <= mem_q_pipe[3][3 : 0];
			end
		      
		      0:
			begin
			   v_waddr <= 4'hF;
			   v_d <= carry[8];
			end
		    endcase
		 end
	       
	       ST_OP_SHL_VX_VY:
		 begin
		    case(ctr_op)
		      1:
			begin
			   v_d <= v_q_pipe[1] << 1;
			   v_waddr <= mem_q_pipe[3][3 : 0];
			end
		      
		      0:
			begin
			   v_waddr <= 4'hF;
			   v_d <= v_q_pipe[2][7];	
			end
		    endcase		    
		 end
	       
	       ST_OP_LD_B_VX:
		 begin
		    
		    if (ctr_op < 3)
		      begin
			 waddr <= waddr + 1;
		      end
		    
		    case(ctr_op)
		      
		      3:
			mem_d <= dec_to_bcd_q[3 : 0];
		      
		      2:			
			mem_d <= dec_to_bcd_q[7 : 4];
		      
		      1:
			mem_d <= dec_to_bcd_q[11 : 8];
		      
		    endcase // case (ctr_op)
		 end
	       
	       ST_OP_LD_F_VX:
		 begin
		    I <= sprite_location_q;
		 end

	       ST_OP_LD_VX_K:
		 begin
		    v_d <= rx_i;
		    if (state_pipe[2] == ST_RD_U)
		      begin
			 v_waddr <= mem_q_pipe[2][3 : 0];
		      end
		 end

	       ST_OP_LD_I_VX:
		 begin
		    v_raddr <= v_raddr + 1;
		    mem_d <= v_q_pipe[0];
		    
		    if ( (state_pipe[2] == ST_RD_U) | (state_pipe[3] == ST_RD_U) )
		      begin
			 waddr <= I;
		      end
		    else
		      begin
			 waddr <= waddr + 1;
		      end
		 end

	       ST_OP_LD_VX_I:
		 begin
		    if ( (state_pipe[2] == ST_RD_U) | (state_pipe[3] == ST_RD_U) )
		      begin
			 v_waddr <= 0;
		      end
		    else
		      begin
			 v_waddr <= v_waddr + 1;
		      end
		    v_d <= mem_q_pipe[0];
		    dump_raddr <= dump_raddr + 1;
		 end

	     endcase // case (state_op)
	  end // else: !if(state_pipe[1] == ST_RD_U)
	
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	case(state_op)
	  
	  ST_OP_LD_I_VX:
	    begin
	       if ( ~(state_pipe[2] == ST_RD_U) | (state_pipe[3] == ST_RD_U) )
		 begin
		    we <= 1;
		 end
	    end
	  
	  ST_OP_LD_B_VX:
	    begin
	       if (ctr_op < 4)
		 begin
		    we <= 1;
		 end
	    end
	  
	  default:
	     we <= 0;

	endcase // case (state_op)
     end
   
   always @ (posedge clk)
     begin
	case(state_op)
	  
	  ST_OP_IDLE:
	    begin
	       
	       if ( (state_pipe[1] == ST_RD_U) & (opcode_pipe[1] == OP_VX_VY))
		 begin
		    
		    case(mem_q_pipe[0][3 : 0])
		      4'h0:
			state_op <= ST_OP_LD_VX_VY;

		      4'h1:
			state_op <= ST_OP_OR_VX_VY;

		      4'h2:
			state_op <= ST_OP_AND_VX_VY;
		      
		      4'h3:
			state_op <= ST_OP_XOR_VX_VY;

		      4'h4:
			state_op <= ST_OP_ADD_VX_VY;

		      4'h5:
			state_op <= ST_OP_SUB_VX_VY;

		      4'h6:
			state_op <= ST_OP_SHR_VX_VY;
		      
		      4'h7:
			state_op <= ST_OP_SUBN_VX_VY;
		      
		      4'hE:
			state_op <= ST_OP_SHL_VX_VY;
		      
		    endcase // case (mem_q_pipe[0][3 : 0])
		 end
	       
	       if ( (state_pipe[1] == ST_RD_U) & (opcode_pipe[1] == OP_LD_VX))
		 begin
		    case(mem_q_pipe[0])
		      
		      8'h07:
			state_op <= ST_OP_LD_VX_DT;
		      
		      8'h0A:
			state_op <= ST_OP_LD_VX_K;

		      8'h15:
			state_op <= ST_OP_LD_DT_VX;
		      
		      8'h18:
			state_op <= ST_OP_LD_ST_VX;
		      
		      8'h1E:
			state_op <= ST_OP_ADD_I_VX;
		      
		      8'h29:
			state_op <= ST_OP_LD_F_VX;
		      
		      8'h33:
			state_op <=  ST_OP_LD_B_VX;
		      
		      8'h55:
			state_op <= ST_OP_LD_I_VX;
		      
		      8'h65:
			state_op <= ST_OP_LD_VX_I;
		      
		    endcase
		 end // if ( (state_pipe[1] == ST_RD_U) & (opcode_pipe[1] == OP_LD_VX))
	    end // case: ST_OP_IDLE
	  
	  ST_OP_LD_B_VX: 
	    begin
	       if (ctr_op == 1) // change to == 0
		 begin
		    state_op <= ST_OP_IDLE;
		 end
	    end

	  ST_OP_LD_VX_I:
	    begin
	       if (ctr_op == 1) // change == 0
		 begin
		    state_op <= ST_OP_IDLE;
		 end
	    end

	  default:
	    if (ctr_op == 0)
	      begin
		 state_op <= ST_OP_IDLE;
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

	       OP_RND_VX_BYTE:
		 v_we <= 1;
	       
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

	    ST_OP_IDLE:
	      v_we <= 0;
	    
	    ST_OP_ADD_VX_VY:
	      v_we <= (ctr_op < 2);
	    
	    ST_OP_SUB_VX_VY:
	      v_we <= (ctr_op < 2);

	    ST_OP_SHR_VX_VY:
	      v_we <= (ctr_op < 2);

	    ST_OP_SUBN_VX_VY:
	      v_we <= (ctr_op < 2);

	    ST_OP_SHL_VX_VY:
	      v_we <= (ctr_op < 2);
	    
	    ST_OP_LD_DT_VX:
	      v_we <= 0;

	    ST_OP_LD_ST_VX:
	      v_we <= 0;

	    ST_OP_ADD_I_VX:
	      v_we <= 0;

	    ST_OP_LD_F_VX:
	      v_we <= 0;

	    ST_OP_LD_B_VX:
	      v_we <= 0;
	    
	    ST_OP_LD_I_VX:
	      v_we <= 0;

	    ST_OP_LD_ST_VX:
	      v_we <= 0;

	    ST_OP_LD_VX_K:
	      v_we <= rx_i_v;

	    ST_OP_LD_VX_I:
	      v_we <= 1;
	    
	    default:
	      v_we <= ctr_op == 0;
	    
	  endcase
     end // always @ (posedge clk)
   
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

	if ( (state_pipe[1] == ST_RD_U) & (opcode_pipe[1] == OP_SYS) )
	  begin
	     cls_en <= 1;
	  end
	else
	  begin
	     cls_en <= 0;
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
	.PROGRAM_FILE_NAME("projects/chip8/cfg/test.hex"),
	.PROGRAM_FILE_WIDTH(16)
	//.PROGRAM_FILE_NAME("projects/chip8/cfg/pong.hex"),
	//.PROGRAM_FILE_WIDTH(256)
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

   always @ (posedge clk)
     begin
	sp_d <= pc;
	if (state_pipe[1] == ST_RD_U)
	  begin
	     if (opcode_pipe[1] == OP_CALL_ADDR)
	       begin
		  sp_we <= 1;		  
	       end
	  end
	else
	  begin
	     sp_we <= 0;
	  end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	if (state_pipe[1] == ST_RD_U)
	  begin
	     if (opcode_pipe[1] == OP_SYS)
	       begin
		  if (mem_q_pipe[0] == 8'hEE)
		    begin
		       sp_waddr <= sp_waddr - 1;		  
		    end
	       end
	  end
	else if (state_pipe[2] == ST_RD_U)
	  begin
	     if (opcode_pipe[2] == OP_CALL_ADDR)
	       begin
		  sp_waddr <= sp_waddr + 1;		  
	       end
	  end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	sp_raddr <= sp_waddr - 1;
     end
   
   ram#(
	.ADDR_WIDTH(SP_ADDR_WIDTH),
	.DATA_WIDTH(SP_DATA_WIDTH)
	) stack_addr (
		      .clk(clk),
		      .we(sp_we),
		      .waddr(sp_waddr),
		      .d(sp_d),
		      .re(1'b1),
		      .raddr(sp_raddr),
		      .q(sp_q)
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
			   .raddr(v_q_pipe[0][3 : 0]),
			   .q(sprite_location_q)
			   );

   draw draw(
	     .clk(clk),
	     .en(draw_en),
	     .cls_en(cls_en),
	     .I(I),
	     .start_pix(vram_start_pix),
	     .start_nibbles(vram_nibbles),
	     .mem_raddr(draw_raddr),
	     .mem_d(mem_q_pipe[0]),
	     .busy(draw_busy),
	     .col(draw_col),
	     .draw_out(draw_o),
	     .hs_o(hs),
	     .vs_o(vs)
	     );

   wire clk_dt;
   reg 	dt_pulse = 0, dt_pulse_d = 0;

   always @ (posedge clk_dt)
     begin
	dt_pulse <= ~dt_pulse;
     end
   
   clks#(
	 //.T(418750 / 2) // 60Hz
	 .T(10 / 2) // quicker for quick sim testing
	 )
     dt_clks(
	     .clk_i(clk),
	     .clk_o(clk_dt)
	     );

   always @ (posedge clk)
     begin
	
	dt_pulse_d <= dt_pulse;
	
	if (state_op ==  ST_OP_LD_DT_VX)//(mem_q_pipe[1] == 8'h15) & (opcode_pipe[2] == OP_LD_VX) & (state_pipe[2] == ST_RD_U ) )
	  begin
	     dt <= v_q_pipe[0];
	  end
	else if  ( dt > 0 )
	  begin
	     dt <= dt - (dt_pulse ^ dt_pulse_d);
	  end
     end
   
   reg [7 : 0] ctr_rnd = 0;
   
   always @ (posedge clk)
     begin
	ctr_rnd <= ctr_rnd + 1;
     end
   
endmodule // interpreter
