module draw(
	    input 			clk,
	    input 			en,
	    input 			cls_en,
	    input [15 : 0] 		I,
	    input [10 : 0] 		start_pix,
	    input [3 : 0] 		start_nibbles, 
	    output [ADDR_WIDTH - 1 : 0] mem_raddr,
	    input [DATA_WIDTH - 1 : 0] 	mem_d,
	    output 			busy,
	    output 			draw_out,
	    output 			col,
	    output 			hs_o,
	    output 			vs_o
	    );

   localparam ST_IDLE        = 0;
   localparam ST_DRAW_SCREEN = 1;
   localparam ST_DRAW_VRAM   = 2;
   
   localparam DATA_WIDTH = 8;
   localparam ADDR_WIDTH = 12;
   
   localparam VRAM_DATA_WIDTH = 2;
   localparam VRAM_ADDR_WIDTH = 11;

   localparam PIPE_LENGTH = 4;
   
   reg [1 : 0] 				state_pipe [PIPE_LENGTH - 1 : 0];
   reg [VRAM_ADDR_WIDTH - 1 : 0] 	waddr_pipe [PIPE_LENGTH - 1 : 0];
   reg [DATA_WIDTH - 1 : 0] 		mem_d_pipe [PIPE_LENGTH - 1 : 0];
   reg [VRAM_DATA_WIDTH - 1 : 0] 	q_pipe [PIPE_LENGTH - 1 : 0];
   reg [VRAM_DATA_WIDTH - 1 : 0] 	d_pipe [PIPE_LENGTH - 1 : 0];
   reg [PIPE_LENGTH - 1 : 0] 		we_pipe;
   reg [2 : 0] 				ctr_pix_pipe [PIPE_LENGTH - 1 : 0];
   
   reg [1 : 0] 				state = ST_IDLE;
   
   reg [ADDR_WIDTH - 1 : 0] 		_mem_raddr = 0;
   
   reg 					we = 0;
   reg [VRAM_ADDR_WIDTH - 1 : 0] 	waddr = 0;
   wire [VRAM_DATA_WIDTH - 1 : 0] 	q;
   reg [VRAM_DATA_WIDTH - 1 : 0] 	d = 0;
   
   wire [VRAM_ADDR_WIDTH - 1 : 0] 	raddr, draw_vram_raddr, draw_screen_raddr;
   
   reg [3 : 0] 				ctr_nib = 0;
   reg [3 : 0] 				nibbles = 0;
   reg [2 : 0] 				ctr_pix = 0;

   reg [4 : 0] 				y = 0;
   reg [5 : 0] 				x = 0, x0 = 0;
   wire [4 : 0] 			y_screen;
   wire [5 : 0] 			x_screen;

   wire 				vs, hs;
   wire 				hs_valid, vs_valid;
   
   reg 					_col;
   
   reg 					draw_vram = 0, draw_cls = 0;
   reg 					_draw_out;
   
   reg [PIPE_LENGTH - 1 : 0] 		pipe_vs_valid = 0;
   reg [PIPE_LENGTH - 1 : 0] 		pipe_hs_valid = 0;
   reg [PIPE_LENGTH - 1 : 0] 		pipe_vs = 0;
   reg [PIPE_LENGTH - 1 : 0] 		pipe_hs = 0;

   reg [VRAM_ADDR_WIDTH - 1 : 0] 	ctr_vram = 0;
   
   assign draw_out = _draw_out;
   assign vs_o = pipe_vs[3];
   assign hs_o = pipe_hs[3];

   assign col = _col;
   
   assign raddr = state == ST_DRAW_VRAM ? draw_vram_raddr : draw_screen_raddr;
   assign draw_vram_raddr = { {y} , {x} };
   assign draw_screen_raddr = { {y_screen} , {x_screen} };
   assign mem_raddr = _mem_raddr;
   assign busy = vs | ~(state_pipe[0] == ST_IDLE)
		    | ~(state_pipe[1] == ST_IDLE);
   
   always @ (posedge clk)
     begin
	if (pipe_vs_valid[2] & pipe_hs_valid[2])
	  begin
	     _draw_out <= q[0];
	  end
	else
	  begin
	     _draw_out <= 0;
	  end
     end // always @ (posedge clk)
   
   always @ (vs_valid, hs_valid, hs, vs)
     begin
	pipe_vs_valid[0] <= vs_valid;
	pipe_hs_valid[0] <= hs_valid;
	pipe_vs[0] <= vs;
	pipe_hs[0] <= hs;
     end

   always @ (posedge clk)
     begin
	pipe_vs_valid[PIPE_LENGTH - 1 : 1] <= pipe_vs_valid[PIPE_LENGTH - 2 : 0];
	pipe_hs_valid[PIPE_LENGTH - 1 : 1] <= pipe_hs_valid[PIPE_LENGTH - 2 : 0];
	pipe_vs[PIPE_LENGTH - 1 : 1] <= pipe_vs[PIPE_LENGTH - 2 : 0];
	pipe_hs[PIPE_LENGTH - 1 : 1] <= pipe_hs[PIPE_LENGTH - 2 : 0];

	we_pipe[PIPE_LENGTH - 1 : 1] <= we_pipe[PIPE_LENGTH - 2 : 0];
     end

   always @ (mem_d, state, we, waddr, q, d, ctr_pix)
     begin
	mem_d_pipe[0] <= mem_d;
	state_pipe[0] <= state;
	we_pipe[0] <= we;
	waddr_pipe[0] <= waddr;
	q_pipe[0] <= q;
	d_pipe[0] <= d;
	ctr_pix_pipe[0] <= ctr_pix;
     end

   genvar i;
   
   generate
      for (i = 1; i < PIPE_LENGTH; i = i + 1)
	begin
	   always @ (posedge clk)
	     begin
		mem_d_pipe[i] <= mem_d_pipe[i - 1];
		state_pipe[i] <= state_pipe[i - 1];
		waddr_pipe[i] <= waddr_pipe[i - 1];
		q_pipe[i] <= q_pipe[i - 1];
		d_pipe[i] <= d_pipe[i - 1];
		ctr_pix_pipe[i] <= ctr_pix_pipe[i - 1];
	     end
	end
endgenerate
	   
   always @ (posedge clk)
     begin
	case (state)
	  ST_IDLE:
	    begin
	       if (vs)
		 begin
		    state <= ST_DRAW_SCREEN;
		 end
	       else if (en)
		 begin
		    state <= ST_DRAW_VRAM;
		 end
	    end
	  
	  ST_DRAW_VRAM:
	    begin
	       if (ctr_nib == (nibbles - 1) & (ctr_pix == 0) )
		 begin
		    state <= ST_IDLE;
		 end
	       else if (vs)
		 begin
		    state <= ST_DRAW_SCREEN;
		 end
	    end

	  ST_DRAW_SCREEN:
	    begin
	       if (~vs)
		 begin
		    state <= draw_vram ? ST_DRAW_VRAM : ST_IDLE;
		 end
	    end
	endcase
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if (en)
	  begin
	     y <= start_pix[10 : 6];
	     x0 <= start_pix[5 : 0];
	     x <= start_pix[5 : 0];
	     nibbles <= start_nibbles;
	  end
	else if (state == ST_DRAW_VRAM)
	  begin
	     if (ctr_pix == 0)
	       begin
		  y <= y + 1;
		  x <= x0;
	       end
	     else
	       begin
		  x <= x + 1;
	       end
	  end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	if (state == ST_IDLE)
	  begin
	     ctr_pix <= 7;
	  end
	else if (state == ST_DRAW_VRAM)
	  begin
	     ctr_pix <= ctr_pix - 1;
	  end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if (draw_vram)
	  begin
	     waddr <= draw_vram_raddr;
	  end
	else
	  begin
	     waddr <= ctr_vram;
	  end
     end
   
   always @ (posedge clk)
     begin
	if (state_pipe[1] == ST_DRAW_VRAM)
	  begin
	     d[0] <= mem_d_pipe[1][ctr_pix_pipe[1]] ^ q[0];
	  end
	else if (state_pipe[2] == ST_DRAW_VRAM)
	  begin
	     if (q_pipe[1][0] == 1 & d[0] == 0)
	       begin
		  _col <= 1; // screen pix set to unset = collision
	       end
	  end
	else if ( (state_pipe[2] == ST_IDLE) | draw_cls )
	  begin
	     _col <= 0;
	     d <= 0;
	  end
     end

   always @ (posedge clk)
     begin
	if (state == en)
	  begin
	     _mem_raddr <= I;
	  end
	else if (state == ST_DRAW_VRAM & ctr_pix == 1)
	  begin
	     _mem_raddr <= _mem_raddr + 1;
	  end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	if (en)
	  begin
	     draw_vram <= 1;
	  end
	else if (ctr_nib == (nibbles - 1) & (ctr_pix == 0) )
	  begin
	     draw_vram <= 0;
	  end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	ctr_vram <= ctr_vram + draw_cls;
     end
   
   always @ (posedge clk)
     begin
	if (cls_en)
	  begin
	     draw_cls <= 1;
	  end
	else if (ctr_vram == ((1 << VRAM_ADDR_WIDTH) - 2))
	  begin
	     draw_cls <= 0;
	  end
     end

   always @ (posedge clk)
     begin
	if (en)
	  begin
	     ctr_nib <= 0;
	  end
	else if (state == ST_DRAW_VRAM & ctr_pix == 0)
	  begin
	     ctr_nib <= ctr_nib + 1;
	  end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	we <= (state == ST_DRAW_VRAM) | (draw_cls);
     end
   
   dram_2048x2 vram (
		     .w_clk(clk),
		     .r_clk(clk),
		     .w_clk_en(1'b1),
		     .r_clk_en(1'b1),
		     .we(we_pipe[1]),
		     .waddr(waddr_pipe[1]), 
		     .d(d),
		     .re(1'b1),
		     .raddr(raddr),
		     .q(q)
		     );
   
   draw_screen draw_screen(
			   .clk(clk),
			   .x(x_screen),
			   .y(y_screen),
			   .vs(vs),
			   .vs_valid(vs_valid),
			   .hs(hs),
			   .hs_valid(hs_valid)
			   );
   
endmodule
