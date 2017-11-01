// Timing info
// http://martin.hinner.info/vga/timing.html

module vga(
	   input  clk,
	   output vs_o,
	   output vs_valid,
	   output hs_o,
	   output hs_valid
	   );

   parameter H_PIX = 640;
   parameter H_SYNC_PULSE = 40;//96;
   parameter H_FP = 24;//16;
   parameter H_BP = 128;//48;
   parameter H_SYNC = H_PIX + H_SYNC_PULSE + H_FP + H_BP;
   
   parameter V_PIX = 480;
   parameter V_SYNC_PULSE = 3; //2;
   parameter V_FP = 9; //11;
   parameter V_BP = 28; //31;
   parameter V_SYNC = V_PIX + V_SYNC_PULSE + V_FP + V_BP;

/*   
   parameter H_PIX = 640;
   parameter H_SYNC_PULSE = 96; //40;//96;
   parameter H_FP = 16; //24;//16;
   parameter H_BP = 48; //128;//48;
   parameter H_SYNC = H_PIX + H_SYNC_PULSE + H_FP + H_BP;
   
   parameter V_PIX = 480;
   parameter V_SYNC_PULSE = 2;//3; //2;
   parameter V_FP = 11; //9; //11;
   parameter V_BP = 31; //28; //31;
   parameter V_SYNC = V_PIX + V_SYNC_PULSE + V_FP + V_BP;
*/
   localparam H_SYNC_WIDTH = $clog2(H_SYNC);
   localparam V_SYNC_WIDTH = $clog2(V_SYNC);

   reg [H_SYNC_WIDTH - 1 : 0] ctr_h = 0;
   reg [V_SYNC_WIDTH - 1 : 0] ctr_v = 0;
   
   always @ (posedge clk)
     begin
	if (ctr_h == H_SYNC - 1)
	  begin
	     ctr_h <= 0;
	  end
	else
	  begin
	     ctr_h <= ctr_h + 1;
	  end
     end // always @ (posedge clk)
   
   always @ (posedge clk)
     begin
	if (ctr_h == H_SYNC - 1)
	  begin
	     if (ctr_v == V_SYNC - 1)
	       begin
		  ctr_v <= 0;
	       end
	     else
	       begin
		  ctr_v <= ctr_v + 1;
	       end
	  end
     end // always @ (posedge clk)

   assign hs_o = (ctr_h > H_SYNC_PULSE - 1);
   assign vs_o = (ctr_v > V_SYNC_PULSE - 1);
   assign hs_valid = (ctr_h > H_SYNC_PULSE + H_BP - 1);// & (ctr_h < H_SYNC_PULSE + H_BP + H_PIX - 1);
   assign vs_valid = (ctr_v > V_SYNC_PULSE + V_BP - 1);// & (ctr_v < V_SYNC_PULSE + V_BP + V_PIX - 1);
   
endmodule
