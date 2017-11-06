module draw_screen(
		  input 			clk,
		  output [X_ADDR_WIDTH - 1 : 0] x,
		  output [Y_ADDR_WIDTH - 1 : 0] y,
		  output 			vs,
		  output 			vs_valid,
		  output 			hs,
		  output 			hs_valid
		  );

   localparam X_MAX = 64;
   localparam Y_MAX = 32;
   localparam X_ADDR_WIDTH = $clog2(X_MAX);
   localparam Y_ADDR_WIDTH = $clog2(Y_MAX);
   
   localparam X_PIX = 640;
   localparam Y_PIX = 480;
   
   localparam X_DIV = X_PIX / X_MAX;
   localparam Y_DIV = Y_PIX / Y_MAX;
   localparam X_DIV_WIDTH = $clog2(X_DIV);
   localparam Y_DIV_WIDTH = $clog2(Y_DIV);

   
   reg [X_DIV_WIDTH - 1 : 0] 					x_div_ctr = 0;
   reg [Y_DIV_WIDTH - 1 : 0] 					y_div_ctr = 0;
   reg [X_ADDR_WIDTH - 1 : 0] _x = 0;
   reg [Y_ADDR_WIDTH - 1 : 0] _y = 0;
   
   wire 		      _hs_valid, _vs_valid;
   
   assign vs_valid = _vs_valid;
   assign hs_valid = _hs_valid;
   assign x = _x;
   assign y = _y;
   
   always @ (posedge clk)
     begin
	if (_hs_valid)
	  begin
	     if (x_div_ctr == X_DIV - 1)
	       begin
		  x_div_ctr <= 0;
	       end
	     else
	       begin
		  x_div_ctr <= x_div_ctr + 1;
	       end
	  end
	else
	  begin
	     x_div_ctr <= 0;
	  end
     end // always @ (posedge clk)

   always @ (posedge clk)
     begin
	if (_vs_valid)
	  begin
	     if ( (y_div_ctr == Y_DIV - 1) & (_x == X_MAX - 1) & (x_div_ctr == X_DIV - 1) )
	       begin
		  y_div_ctr <= 0;
	       end
	     else if( (_x == X_MAX - 1) & (x_div_ctr == X_DIV - 1) )
	       begin
		  y_div_ctr <= y_div_ctr + 1;
	       end
	  end
	else
	  begin
	     y_div_ctr <= 0;
	  end
     end

   always @ (posedge clk)
     begin
	if ( (_x == X_MAX - 1) & (x_div_ctr == X_DIV - 1) )
	  begin
	     _x <= 0;
	  end
	else if (x_div_ctr == X_DIV - 1)
	  begin
	     _x <= x + 1;
	  end
     end

   always @ (posedge clk)
     begin
	if ( (_y == Y_MAX - 1) & (y_div_ctr == Y_DIV - 1))
	  begin
	     _y <= 0;
	  end
	else if ( (x_div_ctr == X_DIV - 1) & (y_div_ctr == Y_DIV - 1) & (_x == X_MAX - 1))
	  begin
	     _y <= _y + 1;
	  end
     end
   
   vga vga(
	   .clk(clk),
	   .vs_o(vs),
	   .vs_valid(_vs_valid),
	   .hs_o(hs),
	   .hs_valid(_hs_valid)
	   );

endmodule
