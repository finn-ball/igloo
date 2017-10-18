module top_tb;
   
   reg clk_i = 0;
   reg rst_i = 1;
   
   wire [7:0] led_o;
   wire       rs232_tx_o;
   wire       rs232_rx_i;
   
   initial
     begin
	
	$dumpfile("./build/iverilog/chip8.vcd");
	$dumpvars(0,top_tb);
	
	# 1250 rst_i <= 0;
	
	# 200000 $finish;
	
     end
   
   top tb (
	   .ice_clk_i (clk_i),
	   .rstn_i(rst_i),
	   .rs232_rx_i(rs232_rx_i),
	   .led_o (led_o),
	   .rs232_tx_o(rs232_tx_o)
	   );
   
   always #1 clk_i = ~clk_i;
   
endmodule // top

   
   
   
    
