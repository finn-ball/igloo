`include "top.vh"

module top(
	   input 	  ice_clk_i,
	   output [7:0]   led_o,
	   output 	  vs_o,
	   output 	  hs_o,
	   output [3 : 0] red_o,
	   output [3 : 0] blue_o,
	   output [3 : 0] green_o
	   );
   
   reg [31:0] 		ctr;
   
   reg 			vs = 0, hs = 0;
   reg [9 : 0] 		ctr_x = 0;
   reg [8 : 0] 		ctr_y = 0;

   wire 		clk_vga;
   wire 		locked;
  
   clks#(
	 .PLL_EN(1),
	 .GBUFF_EN(1),
	 .DIVR(4'b0000),
	 .DIVF(7'b1000010),
	 .DIVQ(3'b100)

	 ) clks(
		.clk_i(ice_clk_i),
		.clk_o(clk_vga)
		);
   

   always @(posedge clk_vga)
     begin
	ctr <= ctr +1;
     end

   genvar i;
   generate
      for (i = 0; i<8; i = i + 1) begin
	 assign led_o[i] = ctr[i + 18];
      end
   endgenerate

   // 640 x 480

   wire pix_clk;
   // pixel clock: 25Mhz = 40ns (clk/2)
   reg 		pcount = 0;		 // used to generate pixel clock
   wire 	en = (pcount == 0);
   always @ (posedge clk_vga) pcount <= ~pcount;
   assign 	pix_clk = en;
   
   reg 		hsync = 0,vsync = 0,hblank = 0,vblank = 0;
   reg [9:0] 	hcount = 0;      // pixel number on current line
   reg [9:0] 	vcount = 0;	 // line number
   
   // horizontal: 794 pixels = 31.76us
   // display 640 pixels per line
   wire 	hsyncon,hsyncoff,hreset,hblankon;
   assign 	hblankon = en & (hcount == 639);    
   assign 	hsyncon = en & (hcount == 652-4);
   assign 	hsyncoff = en & (hcount == 746-4);
   assign 	hreset = en & (hcount == 793-4);
   
   wire 	blank =  (vblank | (hblank & ~hreset));    // blanking => black
   
   // vertical: 528 lines = 16.77us
   // display 480 lines
   wire 	vsyncon,vsyncoff,vreset,vblankon;
   assign 	vblankon = hreset & (vcount == 479);    
   assign 	vsyncon = hreset & (vcount == 492-4);
   assign 	vsyncoff = hreset & (vcount == 494-4);
   assign 	vreset = hreset & (vcount == 527-4);
   
   // sync and blanking
   always @(posedge clk_vga) begin
      hcount <= en ? (hreset ? 0 : hcount + 1) : hcount;
      hblank <= hreset ? 0 : hblankon ? 1 : hblank;
      hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;   // hsync is active low
      
      vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
      vblank <= vreset ? 0 : vblankon ? 1 : vblank;
      vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;   // vsync is active low
   end
   
   
   assign hs_o = hsync;
   assign vs_o = vsync;
   
//   assign red_o =  hsync ? hcount[8 : 5] & vcount[4:1] : 0;  
//   assign blue_o = hsync ? hcount[8 : 5] & vcount[4:1]: 0;  
//   assign green_o = hsync ? 1 : 0;//hsync ? hcount[8: 5] & vcount[4:1] : 0;

   assign red_o =  hsync & vsync ? 4'b1111 : 0;  
   assign blue_o = hsync & vsync ?  4'b1111 : 0;  
   assign green_o = hsync & vsync ? 4'b1111 : 0;//hsync ? hcount[8: 5] & vcount[4:1] : 0;
   
   
endmodule // top
