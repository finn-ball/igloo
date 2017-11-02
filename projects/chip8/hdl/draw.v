module draw(
	    input 			clk,
	    input 			en,
	    input [15 : 0] 		I,
	    input [10 : 0] 		start_pix,
	    input [3 : 0] 		start_nibbles, 
	    output [ADDR_WIDTH - 1 : 0] mem_raddr,
	    input [DATA_WIDTH - 1 : 0] 	mem_d,
	    output 			busy,
	    output 			draw_out,
	    output 			col,
	    output 			hs,
	    output 			vs
	    );

   localparam ST_IDLE        = 0;
   localparam ST_DRAW_SCREEN = 1;
   localparam ST_DRAW_VRAM   = 2;
   
   localparam DATA_WIDTH = 8;
   localparam ADDR_WIDTH = 12;
   
   localparam VRAM_DATA_WIDTH = 2;
   localparam VRAM_ADDR_WIDTH = 11;
   
   reg [ADDR_WIDTH - 1 : 0] 		_mem_raddr = 0;
   
   reg [3 : 0] 				state = ST_IDLE;
   
   reg 					we;
   reg [VRAM_ADDR_WIDTH - 1 : 0] 	waddr = 0;//, raddr = 0;
   
   wire [VRAM_DATA_WIDTH - 1 : 0] 	q;
   reg [VRAM_DATA_WIDTH - 1 : 0] 	d = 0;
   wire [VRAM_ADDR_WIDTH - 1 : 0] 	raddr, draw_vram_raddr, draw_screen_raddr;
   
   reg [3 : 0] 				ctr_nib = 0;
   reg [3 : 0] 				nibbles = 0;
   reg [2 : 0] 				ctr_pix = 0;

   reg [4 : 0] 				y = 0;
   reg [5 : 0] 				x, x0 = 0;
   wire [4 : 0] 			y_screen;
   wire [5 : 0] 			x_screen;

   wire 				hs_valid, vs_valid;
   
   reg 					_col;
   
   reg 					q_d = 0;
   reg 					draw_vram;
   
   assign draw_out = (vs_valid & hs_valid) ? q[0] : 0;
   
   assign col = _col;
   
   assign raddr = state == ST_DRAW_VRAM ? draw_vram_raddr : draw_screen_raddr;
   assign draw_vram_raddr = { {y} , {x} };
   assign draw_screen_raddr = { {y_screen} , {x_screen} };
   assign mem_raddr = _mem_raddr;

   assign busy = en | ~(state == ST_IDLE);
   
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
	       if (ctr_nib == (nibbles - 1) & (ctr_pix == 7) )
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
	     y <= y + (ctr_pix == 7);
	     x <= x0 + ctr_pix;
	  end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	if (state == ST_IDLE)
	  begin
	     ctr_pix <= 0;
	  end
	else if (state == ST_DRAW_VRAM)
	  begin
	     ctr_pix <= ctr_pix + 1;
	  end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	waddr <= raddr; 
     end
   
   always @ (posedge clk)
     begin
	q_d <= q[0];
     end
   
   always @ (posedge clk)
     begin
	if (state == ST_DRAW_VRAM)
	  begin
	     d[0] <= mem_d[ctr_pix] ^ q[0];
	     if (q_d == 1 & d[0] == 0)
	       begin
		  _col <= 1; // screen pix set to unset
	       end
	  end
	else if (state == ST_IDLE)
	  begin
	     _col <= 0;
	  end
     end

   always @ (posedge clk)
     begin
	if (state == en)
	  begin
	     _mem_raddr <= I;
	  end
	else if (state == ST_DRAW_VRAM & ctr_pix == 6)
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
	else if (ctr_nib == (nibbles - 1) & (ctr_pix == 7) )
	  begin
	     draw_vram <= 0;
	  end
     end

   always @ (posedge clk)
     begin
	if (en)
	  begin
	     ctr_nib <= 0;
	  end
	else if (state == ST_DRAW_VRAM & ctr_pix == 7)
	  begin
	     ctr_nib <= ctr_nib + 1;
	  end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	we <= state == ST_DRAW_VRAM;
     end

   dram_2048x2 vram (
		     .w_clk(clk),
		     .r_clk(clk),
		     .w_clk_en(1'b1),
		     .r_clk_en(1'b1),
		     .we(we),
		     .waddr(waddr),
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
