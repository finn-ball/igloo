module mandlebrot(
		  input 		 clk,
		  input [WIDTH - 1 : 0]  re_i,
		  input [WIDTH - 1 : 0]  im_i,
		  input [WIDTH - 1 : 0]  re_c,
		  input [WIDTH - 1 : 0]  im_c,
		  output [WIDTH - 1 : 0] re_o,
		  output [WIDTH - 1 : 0] im_o,
		  output 		 escaped,
		  input 		 valid_i,
		  output 		 valid_o
		  );

   parameter WIDTH = 8;
   parameter DIVERGENCE = 1 << 2 * WIDTH;
   localparam MAX_SQUARE = 1 << WIDTH;

   localparam VALID_DELAY = 2 * WIDTH + 4;

   reg [VALID_DELAY - 1 : 0] 		 valid_pipe = 0;
   reg signed [WIDTH - 1 : 0] 		 re_c_pipe [WIDTH + 1 : 0];
   reg signed [WIDTH - 1 : 0] 		 im_c_pipe [WIDTH + 1: 0];

   always @(*)
     begin
	valid_pipe[0] <= valid_i;
     end
   always @(posedge clk)
     begin
	valid_pipe[VALID_DELAY - 1 : 1] <= valid_pipe[VALID_DELAY - 2 : 0];
     end
   assign valid_o = valid_pipe[VALID_DELAY - 1];

   // Can reduce the number of multiplications
   // zn+1 = z^2
   //      = (x + iy)^2
   //      = x^2 - y^2 + 2*xyi
   //      = (x + y)*(x - y) + (x + x)*yi

   wire signed [WIDTH : 0]		x_signed;
   wire signed [WIDTH : 0]		y_signed;

   // Extend width by one to fit multipliers after addition
   assign x_signed = {re_i[WIDTH - 1], re_i};
   assign y_signed = {im_i[WIDTH - 1], im_i};

   reg signed [WIDTH : 0]		  x_p_y;
   reg signed [WIDTH : 0]		  x_m_y;
   reg signed [WIDTH : 0]		  double_x;
   reg signed [WIDTH : 0]		  y_d;

   wire signed [(WIDTH + 1) * 2 - 1 : 0]  re;
   wire signed [(WIDTH + 1) * 2 - 1 : 0]  im;

   always @(posedge clk)
     begin
	x_p_y <= x_signed + y_signed;
	x_m_y <= x_signed - y_signed;
	double_x <= re_i << 1; // BUG: Double a negative
	y_d <= y_signed;
     end

   multiplier#(
	       .WIDTH(WIDTH + 1) // (x + y) * (x - y)
	       ) mult_1(
			.clk(clk),
			.a(x_p_y),
			.b(x_m_y),
			.c(re)
			);

   multiplier#(
	       .WIDTH(WIDTH + 1) // (x + x) * y
	       ) mult_2(
			.clk(clk),
			.a(double_x),
			.b(y_d),
			.c(im)
			);

   // Now find the magnitude
   reg [WIDTH - 1 : 0] im_pipe [WIDTH : 0];
   reg [WIDTH - 1 : 0] re_pipe [WIDTH : 0];
   reg [WIDTH : 0]     escaped_i;
   wire [WIDTH * 2 - 1 : 0] im_squared;
   wire [WIDTH * 2 - 1 : 0] re_squared;

   wire [WIDTH - 1 : 0]     im_d;
   wire [WIDTH - 1 : 0]     re_d;

   always @(posedge clk)
     begin
	re_c_pipe[0] <= re_c;
	im_c_pipe[0] <= im_c;

	// Check width after addition
	re_pipe[0] <= re[WIDTH - 1 : 0] + re_c_pipe[WIDTH + 1];
	im_pipe[0] <= im[WIDTH - 1 : 0] + im_c_pipe[WIDTH + 1];
	escaped_i[0] <= ((im + im_c_pipe[WIDTH + 1]) > MAX_SQUARE)
	             || ((im + im_c_pipe[WIDTH + 1]) < -MAX_SQUARE)
	             || ((re + re_c_pipe[WIDTH + 1]) > MAX_SQUARE)
                     || ((re + re_c_pipe[WIDTH + 1]) < -MAX_SQUARE);
	escaped_i[WIDTH : 1] <= escaped_i[WIDTH - 1 : 0];
     end

   genvar i;
   generate
      for (i = 1; i < WIDTH + 1; i = i + 1)
	begin
	   always @(posedge clk)
	     begin
		re_pipe[i] <= re_pipe[i - 1];
		im_pipe[i] <= im_pipe[i - 1];

		re_c_pipe[i] <= re_c_pipe[i - 1];
		im_c_pipe[i] <= im_c_pipe[i - 1];
	     end
	end
   endgenerate

   always @(posedge clk)
     begin
	re_c_pipe[WIDTH + 1] <= re_c_pipe[WIDTH];
	im_c_pipe[WIDTH + 1] <= im_c_pipe[WIDTH];
     end

   assign re_d = re_pipe[0];
   assign im_d = im_pipe[0];
   assign re_o = re_pipe[WIDTH];
   assign im_o = im_pipe[WIDTH];

   multiplier#(
	       .WIDTH(WIDTH)
	       ) square_im(
			  .clk(clk),
			  .a(im_d),
			  .b(im_d),
			  .c(im_squared)
			  );

   multiplier#(
	       .WIDTH(WIDTH)
	       ) square_re(
			  .clk(clk),
			  .a(re_d),
			  .b(re_d),
			  .c(re_squared)
			  );

   assign escaped = ( (re_squared + im_squared) >  DIVERGENCE ) || escaped_i[WIDTH];
   // assign escaped = valid_pipe[VALID_DELAY - 1] &&im_squared[2];

   integer 		     k;
   initial
     begin
	$dumpfile("./build/iverilog/mandlebrot.vcd");
	for (k = 0; k < WIDTH + 1; k = k + 1)
	  begin
	     $dumpvars(0, re_pipe[k]);
	     $dumpvars(0, im_pipe[k]);
	     $dumpvars(0, im_c_pipe[k]);
	     $dumpvars(0, re_c_pipe[k]);
	  end
	$dumpvars(0, im_c_pipe[10]);
	$dumpvars(0, re_c_pipe[10]);

     end


endmodule
