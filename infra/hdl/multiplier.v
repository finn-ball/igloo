// Booth encoding
// TODO: radix-4


module multiplier(
		  input 		     clk,
		  input [WIDTH - 1 : 0]      a,
		  input [WIDTH - 1 : 0]      b,
		  output [WIDTH * 2 - 1 : 0] c
		  );

   parameter WIDTH = 2;

   wire [WIDTH : 0] 					 _a;
   wire [WIDTH : 0] 					 _b;
   wire [2 * WIDTH - 1 : 0] 				 _c;

   assign _a = { {a[WIDTH - 1]}, {a[WIDTH - 1 : 0]} };
   assign _b = { {b[WIDTH - 1]}, {b[WIDTH - 1 : 0]} };
   assign c = _c;

   _multiplier#(
	       .WIDTH(WIDTH + 1)
	       ) mult(
		      .clk(clk),
		      .a(_a),
		      .b(_b),
		      .c(_c)
		      );


endmodule // multiplier


// Will fail on most negative number
// i.e { {1'b1} , {(WIDTH - 2)'b0} }
// So for e.g WIDTH=4 signed numbers, WIDTH=5 for M


module _multiplier(
		  input			     clk,
		  input [WIDTH - 1 : 0]      a,
		  input [WIDTH - 1 : 0]      b,
		  output [WIDTH * 2 - 1 : 0] c
		  );

   parameter WIDTH = 2;

   localparam M_WIDTH = WIDTH;
   localparam P_WIDTH = 2 * M_WIDTH;

   reg [P_WIDTH - 1 : 0] 		     P [M_WIDTH : 0];
   reg signed [M_WIDTH - 1 : 0] 	     M [M_WIDTH : 0];
   reg [M_WIDTH - 1 : 0] 			     Q;

   assign c = P[M_WIDTH];

   always @(a, b)
     begin
	P[0] <= { {(P_WIDTH){1'b0}}, {a} };
	M[0] <= b;
     end

   always @(posedge clk)
     begin
	if (P[0][0])
	  begin
	     P[1] <= sub_shift_right(P[0], M[0]);
	  end
	else
	  begin
	     P[1] <= shift_right(P[0]);
	  end
	Q[0] <= P[0][0];
	M[1] <= M[0];
     end // always @ (posedge clk)

   genvar	    i;
   generate
      for (i = 1; i < M_WIDTH; i = i + 1)
	begin
	   always @(posedge clk)
	     begin
		Q[i] <= P[i][0];
		M[i + 1] <= M[i];
		case( { P[i][0], Q[i - 1] } )

		  2'b01:
		    P[i + 1] <= add_shift_right(P[i], M[i]);

		  2'b10:
		    P[i + 1] <= sub_shift_right(P[i], M[i]);

		  default:
		    P[i + 1] <= shift_right(P[i]);

		endcase
	     end
	end // for (i = 0; i < WIDTH; i = i + 1)
   endgenerate

   function [P_WIDTH - 1 : 0] shift_right(input [P_WIDTH - 1 : 0] x);
      shift_right = { {x[P_WIDTH - 1]}, x[P_WIDTH - 1 : 1] };
   endfunction // shift_right

   function [P_WIDTH - 1 : 0] add_shift_right(input [P_WIDTH - 1 : 0] x, input signed [M_WIDTH - 1 : 0] y);
      add_shift_right = shift_right({ {x[P_WIDTH - 1 : M_WIDTH] + y}, {x[M_WIDTH - 1 : 0]} });
   endfunction // add_shift_right

   function [2 * WIDTH - 1 : 0] sub_shift_right(input [P_WIDTH - 1 : 0] x, input signed [M_WIDTH - 1 : 0] y);
      sub_shift_right = shift_right({ {x[P_WIDTH - 1 : M_WIDTH] - y}, {x[M_WIDTH - 1 : 0]} });;
   endfunction // sub_shift_right

endmodule // _multiplier
