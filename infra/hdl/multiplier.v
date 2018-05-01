// Booth encoding
// Radix-4?

module multiplier(
		  input			     clk,
		  input [WIDTH - 1 : 0]      a,
		  input [WIDTH - 1 : 0]      b,
		  output [WIDTH * 2 - 1 : 0] c
		  );

   parameter WIDTH = 2;

   reg [WIDTH * 2 - 1 : 0]		     P [WIDTH : 0];
   reg signed [WIDTH - 1 : 0]		     M [WIDTH : 0];
   reg [WIDTH - 1 : 0]			     Q;

   assign c = P[WIDTH];

   always @(*)
     begin
	P[0] <= { {(WIDTH){1'b0}}, {a} };
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
      for (i = 1; i < WIDTH; i = i + 1)
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

   function [2 * WIDTH - 1 : 0] shift_right(input [2 * WIDTH - 1 : 0] x);
      shift_right = { {x[2 * WIDTH - 1]}, x[2 * WIDTH - 1 : 1] };
   endfunction // shift_right

   function [2 * WIDTH - 1 : 0] add_shift_right(input [2 * WIDTH - 1 : 0] x, input signed [WIDTH - 1 : 0] y);
      add_shift_right = shift_right({ {x[2 * WIDTH - 1 : WIDTH] + y}, {x[WIDTH - 1 : 0]} });
   endfunction // add_shift_right

   function [2 * WIDTH - 1 : 0] sub_shift_right(input [2 * WIDTH - 1 : 0] x, input signed [WIDTH - 1 : 0] y);
      sub_shift_right = shift_right({ {x[2 * WIDTH - 1 : WIDTH] - y}, {x[WIDTH - 1 : 0]} });;
   endfunction // sub_shift_right

endmodule // multiplier
